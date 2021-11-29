//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIOSSL

struct WrappedNIOSSLCertificate {
    var trustRootsBytes : [Data]? = nil
    var trustRoots: [NIOSSLCertificate] = []
    
    init?(trustRootBytes bytes: [Data]) {
        switch Self.trustRoots(from: bytes) {
        case .success(let certificates as [NIOSSLCertificate]):
            self.trustRoots = certificates
            self.trustRootsBytes = bytes
        default:
            return nil
        }
    }

    static func trustRoots(from bytes: [Data]) -> Result<Any, InvalidInputError> {
        var trustRoots: [NIOSSLCertificate] = []
        for trustRootBytes in bytes {
            do {
                trustRoots.append(
                    try NIOSSLCertificate(bytes: Array(trustRootBytes), format: .der))
            } catch {
                let errorMessage = "Error parsing trust root certificate: " +
                    "\(trustRootBytes.base64EncodedString())  Error: \(error)"
                logger.error(errorMessage, logFunction: false)
                return .failure(InvalidInputError(errorMessage))
            }
        }
        return .success(trustRoots)
    }
}
