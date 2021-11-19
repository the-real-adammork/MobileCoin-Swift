//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol PossibleNIOSSLCertificate {
    var trustRootsBytes : [Data] { get }
    
    init?(trustRootBytes: [Data])
    
    func trustRoots() -> Result<Any, InvalidInputError>
}

extension PossibleNIOSSLCertificate {
    func trustRoots() -> Result<Any, InvalidInputError> {
        return .failure(InvalidInputError("Not implemented"))
    }
}
