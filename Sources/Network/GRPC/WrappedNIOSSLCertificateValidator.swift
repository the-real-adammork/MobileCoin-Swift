//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class WrappedNIOSSLCertificateValidator {
    func validate(possibleCertificateData bytes: [Data]) -> Result<PossibleNIOSSLCertificate, InvalidInputError> {
         WrappedNIOSSLCertificate.make(trustRootBytes: bytes)
    }
}
