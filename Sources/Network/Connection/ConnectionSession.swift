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

    private var cookieHeaders : [String:String] {
        guard let cookies = cookieStorage.cookies(for: url) else { return [:] }
        return HTTPCookie.requestHeaderFields(with: cookies)
    }

    private var authorizationHeades : [String: String] {
        guard let credentials = authorizationCredentials else { return [:] }
        return ["Authorization" : credentials.authorizationHeaderValue]
    }
    var requestHeaders: [String : String] {
        var headers : [String: String] = [:]
        headers.merge(cookieHeaders) {  (_, new) in new }
        headers.merge(authorizationHeades) {  (_, new) in new }
        return headers
    }
    
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

    func processResponse(headers: HPACKHeaders) {
        processCookieHeader(headers: headers)
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
    
}

// GRPC
extension ConnectionSession {
    private func processCookieHeader(headers: HPACKHeaders) {
        let http1Headers = Dictionary(
            headers.map { ($0.name.capitalized, $0.value) },
            uniquingKeysWith: { k, _ in k })

        let receivedCookies = HTTPCookie.cookies(
            withResponseHeaderFields: http1Headers,
            for: url)
        receivedCookies.forEach(cookieStorage.setCookie)
    }
    
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

extension HPACKHeaders {
    fileprivate mutating func add(httpHeaders: [String: String]) {
        add(httpHeaders: HTTPHeaders(Array(httpHeaders)))
    }

    fileprivate mutating func add(httpHeaders: HTTPHeaders) {
        add(contentsOf: HPACKHeaders(httpHeaders: httpHeaders))
    }
}

class ConnectionSessionTrust : NSObject, URLSessionDelegate {
    let config : ConnectionConfigProtocol

    init(config: ConnectionConfigProtocol) {
        self.config = config
    }
    
    func urlSession(_ session: URLSession,
                  didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // indicates the server requested a client certificate.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            logger.info("No cert needed")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let trust = challenge.protectionSpace.serverTrust else {
            logger.info("no server trust")
            completionHandler(.performDefaultHandling, nil)
            return
        }

//        let isServerTrusted = SecTrustEvaluateWithError(serverTrust, nil)
        
        if let serverCertificate = SecTrustGetCertificateAtIndex(trust, 0),
           let serverCertificateKey = publicKey(for: serverCertificate) {
           if pinnedKeys().contains(serverCertificateKey) {
               completionHandler(.useCredential, URLCredential(trust: trust))
               return
           }
       }
        guard let file = Bundle(for: HTTPAccessURLSessionDelegate.self).url(forResource: p12Filename, withExtension: "p12"),
              let p12Data = try? Data(contentsOf: file) else {
            // Loading of the p12 file's data failed.
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Interpret the data in the P12 data blob with
        // a little helper class called `PKCS12`.
        let password = "MyP12Password" // Obviously this should be stored or entered more securely.
        let p12Contents = PKCS12(pkcs12Data: p12Data, password: password)
        guard let identity = p12Contents.identity else {
            // Creating a PKCS12 never fails, but interpretting th contained data can. So again, no identity? We fall back to default.
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // In my case, and as Apple recommends,
        // we do not pass the certificate chain into
        // the URLCredential used to respond to the challenge.
        let credential = URLCredential(identity: identity,
                                   certificates: nil,
                                    persistence: .none)
        challenge.sender?.use(credential, for: challenge)
        completionHandler(.useCredential, credential)
    }
}
