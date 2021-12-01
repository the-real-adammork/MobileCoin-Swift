//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct HttpsAttestedConnectionConfig<Url: MobileCoinUrlProtocol>: AttestedConnectionConfigProtocol {
    let urlTyped: Url
    let transportProtocolOption: TransportProtocol.Option
    let attestation: Attestation
    let authorization: BasicCredentials?

    init(
        url: Url,
        transportProtocolOption: TransportProtocol.Option,
        attestation: Attestation,
        authorization: BasicCredentials?
    ) {
        self.urlTyped = url
        self.transportProtocolOption = transportProtocolOption
        self.attestation = attestation
        self.authorization = authorization
    }

    var url: MobileCoinUrlProtocol { urlTyped }
}
