//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable all

import Foundation
import SwiftProtobuf
import NIOSSL

public protocol HttpRequester {
    func request(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (HTTPResult) -> Void)
}

public enum HTTPMethod : String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case HEAD = "HEAD"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

public struct HTTPResponse {
    public let httpUrlResponse: HTTPURLResponse
    public let responseData: Data?

    public var statusCode: Int {
        httpUrlResponse.statusCode
    }

    public var allHeaderFields: [AnyHashable: Any] {
        httpUrlResponse.allHeaderFields
    }
}

public enum HTTPResult {
    case success(response: HTTPResponse)
    case failure(error: Error)
}

// - Add relative path component toe NetworkedMessage and then combine at runtime.

public class HTTPRequester {
    public static let defaultConfiguration : URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return config
    }()

    let configuration : URLSessionConfiguration
    let baseUrl: URL
    let trustRoots: [NIOSSLCertificate]?

    public init(baseUrl: URL, trustRoots: [NIOSSLCertificate]?, configuration: URLSessionConfiguration = HTTPRequester.defaultConfiguration) {
        self.configuration = configuration
//        self.baseUrl = URL(string:"/gw/", relativeTo: baseUrl)!
        self.baseUrl = baseUrl
        self.trustRoots = trustRoots
    }
}

public protocol Requester {
//    func makeRequest<T: HTTPClientCall>(call: T, completion: @escaping (Result<T.ResponsePayload, Error>) -> Void)
    func makeRequest<T: HTTPClientCall>(call: T, completion: @escaping (HttpCallResult<T.ResponsePayload>) -> Void)
}

extension HTTPRequester : Requester {
    private func completeURLFromPath(_ path: String) -> URL? {
        URL(string: "/gw\(path)", relativeTo: baseUrl)
    }
    
//    public func makeRequest<T: HTTPClientCall>(call: T, completion: @escaping (Result<HttpCallResult<T.ResponsePayload>, Error>) -> Void) {
    public func makeRequest<T: HTTPClientCall>(call: T, completion: @escaping (HttpCallResult<T.ResponsePayload>) -> Void) {
        let session = URLSession(configuration: configuration)
        
        guard let url = completeURLFromPath(call.path) else {
            // TODO move out of Requester ?
            completion(HttpCallResult(status: HTTPStatus(code: 1, message: "could not construct URL")))
            return
        }
        logger.debug("completeURLFromPath: \(url.debugDescription)")
        logger.debug("absoluteURL: \(url.absoluteURL.debugDescription)")
        
        
        /*
         - Convert all service files that rely on HTTPConnection, fix using integration tests
         - Port AttestedHTTPConnection, fix using integration tests
         - Cleanup code, tighten up solution.
         - Add requester requirement to HTTPCallable, AuthHTTPCallable
         - Add requester requirement to HTTPConnection, AttestableHTTPConnection
         */
        var request = URLRequest(url: url.absoluteURL)
        request.httpMethod = call.method.rawValue
        request.addProtoHeaders()
        request.addHeaders(call.options?.headers ?? [:])

        do {
            request.httpBody = try call.requestPayload?.serializedData() ?? Google_Protobuf_Empty().serializedData()
            logger.debug("MC HTTP Request: \(call.requestPayload?.prettyPrintJSON() ?? "")")
        } catch let error {
            logger.debug(error.localizedDescription)
            completion(HttpCallResult(status: HTTPStatus(code: 1, message: error.localizedDescription)))
        }

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(HttpCallResult(status: HTTPStatus(code: 1, message: error.localizedDescription)))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(HttpCallResult(status: HTTPStatus(code: 1, message: "No response object")))
                return
            }
            
            logger.debug("HTTPURLResponse debug:")
            logger.debug(response.debugDescription)

            let responsePayload : T.ResponsePayload? = {
                guard let data = data,
                      let responsePayload = try? T.ResponsePayload.init(serializedData: data)
                else {
                    logger.debug("Response proto is empty or no data")
                    return nil
                }
                logger.debug("Resposne Proto as JSON: \((try? responsePayload.jsonString()) ?? "Unable to print JSON")")
                return responsePayload
            }()

            let result = HttpCallResult(status: HTTPStatus(code: response.statusCode, message: ""), initialMetadata: response, response: responsePayload)
            completion(result)
        }.resume()
    }
    
}

fileprivate extension URLRequest {
    mutating func addProtoHeaders() {
        let contentType = HTTPHeadersConstants.CONTENT_TYPE_PROTOBUF
        self.setValue(contentType.value, forHTTPHeaderField: contentType.fieldName)
        
        let accept = HTTPHeadersConstants.ACCEPT_PROTOBUF
        self.addValue(accept.value, forHTTPHeaderField: accept.fieldName)
    }
    
    mutating func addHeaders(_ headers: [String:String]) {
        headers.forEach { headerFieldName, value in
            self.setValue(value, forHTTPHeaderField: headerFieldName)
        }
    }
}

struct HTTPHeadersConstants {
    static var ACCEPT_PROTOBUF = (fieldName:"Accept", value:"application/x-protobuf")
    static var CONTENT_TYPE_PROTOBUF = (fieldName:"Content-Type", value:"application/x-protobuf")
}

extension Message {
    func prettyPrintJSON() -> String {
        guard let jsonData = try? self.jsonUTF8Data(),
              let data = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let object = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: object, encoding: String.Encoding.utf8) else {
              return "Unable to pretty print json"
        }
        return prettyPrintedString
    }
}

public enum HTTPResponseStatusCodeError : Error {
    case unauthorized
    case badRequest
    case forbidden
    case notFound
    case unprocessableEntity
    case internalServerError
    case invalidResponseFromExternal
    case unknown(Int)
    
    // TODO add other HTTP errors here
    init(_ code: Int) {
        switch code {
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 404: self = .notFound
        case 422: self = .unprocessableEntity
        case 500: self = .internalServerError
        case 502: self = .invalidResponseFromExternal
        default: self = .unknown(code)
        }
    }
    
    var value : Int? {
        switch self {
        case .badRequest: return 400
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .unprocessableEntity: return 422
        case .internalServerError: return 500
        case .invalidResponseFromExternal: return 502
        default: return nil
        }
    }
}

extension HTTPResponseStatusCodeError : CustomStringConvertible {
    public var localizedDescription: String {
        return description
    }
    
    public var description: String {
        switch self {
        case .badRequest: return "The request is malformed (ex. missing or incorrect parameters)"
        case .unauthorized: return "Failed to provide proper authentication with the request."
        case .forbidden: return "The action in the request is not allowed."
        case .notFound: return "Not Found"
        case .unprocessableEntity: return "The server understands the content type of the request entity, and the syntax of the request entity is correct, but it was unable to process the contained instructions."
        case .internalServerError: return "Unhandled exception from one of the other services: the Database, FTX, or the Full Service Wallet."
        case .invalidResponseFromExternal: return "The server was acting as a gateway or proxy and received an invalid response from the upstream server (ie. one of the other services: the Database, FTX, or the Full Service Wallet.)"
        case .unknown(let code): return "HTTP Response code \(code)"
        }
    }
}

extension HTTPResponseStatusCodeError : Equatable {
    public static func == (lhs: HTTPResponseStatusCodeError, rhs: HTTPResponseStatusCodeError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown(let lhsValue), .unknown(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return lhs.value ?? -1 == rhs.value ?? -1
        }
    }
}

public enum NetworkingError: Error {
    case unknownDecodingError
    case noResponseStatus
    case noResponse
    case unknown
    case noData
}

extension NetworkingError: CustomStringConvertible {
    public var description : String {
        switch self {
        case .noResponseStatus: return "Response status not explicitly set in proto response"
        case .noResponse: return "URLResponse object is nil"
        case .unknownDecodingError: return "Unknown decoding error"
        case .unknown: return "Unknown netowrking error"
        case .noData: return "No data in resposne"
        }
    }
}
