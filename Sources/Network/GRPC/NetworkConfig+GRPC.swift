//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIOSSL

extension NetworkConfig {
    func consensusTrustRoots() throws -> [NIOSSLCertificate] { try Self.trustRoots() }
    func fogTrustRoots() throws -> [NIOSSLCertificate] { try Self.trustRoots() }

    static func trustRoots() throws -> [NIOSSLCertificate] {
        let trustRootsBytes = try self.trustRootsBytes()
        return try trustRootsBytes.map { try NIOSSLCertificate(bytes: Array($0), format: .der) }
    }
    
    private static func parseTrustRoots(trustRootsBytes: [Data])
        -> Result<[NIOSSLCertificate], InvalidInputError>
    {
        var trustRoots: [NIOSSLCertificate] = []
        for trustRootBytes in trustRootsBytes {
            do {
                trustRoots.append(
                    try NIOSSLCertificate(bytes: Array(trustRootBytes), format: .der))
            } catch {
                let errorMessage = "Error parsing trust root certificate: " +
                    "\(trustRootBytes.base64EncodedString()) - Error: \(error)"
                logger.error(errorMessage, logFunction: false)
                return .failure(InvalidInputError(errorMessage))
            }
        }
        return .success(trustRoots)
    }
}



