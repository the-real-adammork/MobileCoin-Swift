//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import NIOHPACK
import NIOHTTP1

final class ConnectionSession {
    private static var ephemeralCookieStorage: HTTPCookieStorage {
        guard let cookieStorage = URLSessionConfiguration.ephemeral.httpCookieStorage else {
            // Safety: URLSessionConfiguration.ephemeral.httpCookieStorage will always return
            // non-nil.
            logger.fatalError("URLSessionConfiguration.ephemeral.httpCookieStorage returned nil.")
        }
        return cookieStorage
    }

    private let url: URL
    private let cookieStorage: HTTPCookieStorage
    var authorizationCredentials: BasicCredentials?

    convenience init(config: ConnectionConfigProtocol) {
        self.init(url: config.url, authorization: config.authorization)
    }

    init(url: MobileCoinUrlProtocol, authorization: BasicCredentials? = nil) {
        self.url = url.httpBasedUrl
        self.cookieStorage = Self.ephemeralCookieStorage
        self.authorizationCredentials = authorization
    }

    func addRequestHeaders(to hpackHeaders: inout HPACKHeaders) {
        addAuthorizationHeader(to: &hpackHeaders)
        addCookieHeader(to: &hpackHeaders)
    }

    func addRequestHeaders(to urlRequest: inout URLRequest) {
        addAuthorizationHeader(to: &urlRequest)
        addCookieHeader(to: &urlRequest)
    }

    func processResponse(headers: [AnyHashable : Any]) {
        processCookieHeader(headers: headers)
    }
}

extension ConnectionSession {
    private func addAuthorizationHeader(to hpackHeaders: inout HPACKHeaders) {
        if let credentials = authorizationCredentials {
            hpackHeaders.add(httpHeaders: ["Authorization": credentials.authorizationHeaderValue])
        }
    }
    
    private func addAuthorizationHeader(to urlRequest: inout URLRequest) {
        if let credentials = authorizationCredentials {
            urlRequest.setValue(credentials.authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        }
    }
}

// GRPC
extension ConnectionSession {
    private func addCookieHeader(to urlRequest: inout URLRequest) {
        if let cookies = cookieStorage.cookies(for: url) {
            HTTPCookie.requestHeaderFields(with: cookies).forEach { header in
                urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
    }

    private func processCookieHeader(headers: HPACKHeaders) {
        let http1Headers = Dictionary(
            headers.map { ($0.name.capitalized, $0.value) },
            uniquingKeysWith: { k, _ in k })

        let receivedCookies = HTTPCookie.cookies(
            withResponseHeaderFields: http1Headers,
            for: url)
        receivedCookies.forEach(cookieStorage.setCookie)
    }
}

extension HPACKHeaders {
    fileprivate mutating func add(httpHeaders: [String: String]) {
        add(httpHeaders: HTTPHeaders(Array(httpHeaders)))
    }

    fileprivate mutating func add(httpHeaders: HTTPHeaders) {
        add(contentsOf: HPACKHeaders(httpHeaders: httpHeaders))
    }
}

// HTTP
extension ConnectionSession {
    private func addCookieHeader(to hpackHeaders: inout HPACKHeaders) {
        if let cookies = cookieStorage.cookies(for: url) {
            hpackHeaders.add(httpHeaders: HTTPCookie.requestHeaderFields(with: cookies))
        }
    }

    private func processCookieHeader(headers: [AnyHashable: Any]) {
        let http1Headers = Dictionary(
            headers.compactMap({ (key: AnyHashable, value: Any) -> (name: String, value: String)? in
                guard let name = key as? String else { return nil }
                guard let value = value as? String else { return nil }
                return (name:name, value:value)
            }).map { ($0.name.capitalized, $0.value) },
            uniquingKeysWith: { k, _ in k })

        let receivedCookies = HTTPCookie.cookies(
            withResponseHeaderFields: http1Headers,
            for: url)
        receivedCookies.forEach(cookieStorage.setCookie)
    }
}

