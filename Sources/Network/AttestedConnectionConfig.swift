//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol AttestedConnectionConfigProtocol: ConnectionConfigProtocol {
    associatedtype Url:MobileCoinUrlProtocol
    var attestation: Attestation { get }
    var urlTyped: Url { get }
    var transportProtocolOption: TransportProtocol.Option { get }
    var authorization: BasicCredentials? { get }
}
