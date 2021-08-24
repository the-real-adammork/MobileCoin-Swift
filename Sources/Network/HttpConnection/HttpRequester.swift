//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import SwiftProtobuf

public protocol HttpRequester {
    func request(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (HTTPResult) -> Void)
}

public enum HTTPMethod {
    case get
    case post
    case put
    case head
    case patch
    case delete
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

    public init(configuration: URLSessionConfiguration = HTTPRequester.defaultConfiguration) {
        self.configuration = configuration
    }
}

public protocol Requester {
    func makeRequest<T: HTTPClientCall>(call: T, completion: @escaping (Result<T.ResponsePayload, Error>) -> Void)
}

extension HTTPRequester : Requester {
    public func makeRequest<T: HTTPClientCall>(call: T, completion: @escaping (Result<T.ResponsePayload, Error>) -> Void) {
//        let session = URLSession(configuration: call.options)
        
//        var request = URLRequest(url: ProtoModel.requestURL)
//        request.httpMethod = ProtoModel.httpMethod
//        request.addProtoHeaders()
//
//        do {
//            var scRequest = SCRequest()
//            scRequest[keyPath: ProtoModel.requestKeyPath] = message
//            request.httpBody = try scRequest.serializedData()
//
//            logger.debug("Stable Coin Request: \(scRequest.prettyPrintJSON())")
//        } catch let error {
//            logger.debug(error.localizedDescription)
//        }
//
//        return firstly {
//            session.dataTask(.promise, with: request)
//        }.map { (data: Data, response: URLResponse) in
//            //{ (data, response, error) in
//            guard let httpResponse = response as? HTTPURLResponse else {
//                throw NetworkingError.noResponse
//            }
//
//            guard (200...299).contains(httpResponse.statusCode) else {
//                throw HTTPResponseStatusCodeError(httpResponse.statusCode)
//            }
//
//            let responseProto = try SCResponse.init(serializedData: data)
//
//            logger.debug("Resposne Proto as JSON: \((try? responseProto.jsonString()) ?? "Unable to print JSON")")
//
//            // Fail immediately if response status not explicitly set ??
//            // guard scresponse.hasResponseStatus else { completion(.failure(WrappedError.noResponseStatus)); return }
//
//            let status : SCResponseStatus = responseProto.responseStatus
//            switch status.statusType {
//            case .success:
//                let element : ProtoModel.Response = responseProto[keyPath:ProtoModel.responseKeyPath]
//                return element
//            default:
//                throw ServiceError(status)
//            }
//        }
    }
    
}

fileprivate extension URLRequest {
    mutating func addProtoHeaders() {
        let contentType = HTTPHeaders.CONTENT_TYPE_PROTOBUF
        self.setValue(contentType.value, forHTTPHeaderField: contentType.fieldName)
        
        let accept = HTTPHeaders.ACCEPT_PROTOBUF
        self.addValue(accept.value, forHTTPHeaderField: accept.fieldName)
    }
}

struct HTTPHeaders {
    static var ACCEPT_PROTOBUF = (fieldName:"Accept", value:"application/x-protobuf")
    static var CONTENT_TYPE_PROTOBUF = (fieldName:"Content-Type", value:"application/x-protobuf")
}
