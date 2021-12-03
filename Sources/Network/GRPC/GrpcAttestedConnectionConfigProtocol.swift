//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIOSSL

struct GrpcAttestedConnectionConfig<Url: MobileCoinUrlProtocol>: AttestedConnectionConfigProtocol {
    let urlTyped: Url
    let transportProtocolOption: TransportProtocol.Option
    let attestation: Attestation
    let trustRoots: [NIOSSLCertificate]?
    let authorization: BasicCredentials?

    init(
        url: Url,
        transportProtocolOption: TransportProtocol.Option,
        attestation: Attestation,
        possibleTrustRoots: PossibleNIOSSLCertificate?,
        authorization: BasicCredentials?
    ) {
        self.urlTyped = url
        self.transportProtocolOption = transportProtocolOption
        self.attestation = attestation
        self.trustRoots = (possibleTrustRoots as? WrappedNIOSSLCertificate)?.trustRoots
        self.authorization = authorization
    }

    var url: MobileCoinUrlProtocol { urlTyped }
}
