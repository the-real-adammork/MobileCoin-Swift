//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol PossibleNIOSSLCertificate {
    var trustRootsBytes : [Data] { get }
    
    init?(trustRootBytes: [Data])
    
    static func trustRoots() -> Result<Any, InvalidInputError>
}

extension PossibleNIOSSLCertificate {
    init?(trustRootBytes: [Data]) {
        return nil
    }
    
    static func trustRoots() -> Result<Any, InvalidInputError> {
        return .failure(InvalidInputError("Not implemented"))
    }
}
