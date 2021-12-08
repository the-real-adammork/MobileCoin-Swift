//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

//import Foundation
//
//protocol AttestedConnectionConfigProtocol: ConnectionConfigProtocol {
//    associatedtype Url:MobileCoinUrlProtocol
//    var attestation: Attestation { get }
//    var urlTyped: Url { get }
//    var transportProtocolOption: TransportProtocol.Option { get }
//    var authorization: BasicCredentials? { get }
//}
//
//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol AttestedConnectionConfigProtocol: ConnectionConfigProtocol {
    var attestation: Attestation { get }
}

struct AttestedConnectionConfig<Url: MobileCoinUrlProtocol>: AttestedConnectionConfigProtocol {
    let urlTyped: Url
    let transportProtocolOption: TransportProtocol.Option
    let attestation: Attestation
    let trustRoots: PossibleNIOSSLCertificate?
    let authorization: BasicCredentials?

    init(
        url: Url,
        transportProtocolOption: TransportProtocol.Option,
        attestation: Attestation,
        trustRoots: PossibleNIOSSLCertificate?,
        authorization: BasicCredentials?
    ) {
        self.urlTyped = url
        self.transportProtocolOption = transportProtocolOption
        self.attestation = attestation
        self.trustRoots = trustRoots
        self.authorization = authorization
    }

    var url: MobileCoinUrlProtocol { urlTyped }
}

