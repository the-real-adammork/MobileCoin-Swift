//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation


public struct HTTPCallOptions {
    let customHeaders: [String : String]
    let timeoutIntervalForRequest : TimeInterval?
    let timeoutIntervalForResource : TimeInterval?
}
