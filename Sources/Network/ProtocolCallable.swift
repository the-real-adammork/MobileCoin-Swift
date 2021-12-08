//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation


protocol ProtocolCallable {
    associatedtype Request
    associatedtype Response
    associatedtype ProtocolCallOptions
    associatedtype ProtocolUnaryCallResult

    func call(
        request: Request,
        callOptions: ProtocolCallOptions?,
        completion: @escaping (ProtocolUnaryCallResult<Response>) -> Void)
}

extension ProtocolCallable {
    func call(request: Request, completion: @escaping (ProtocolUnaryCallResult<Response>) -> Void) {
        call(request: request, callOptions: nil, completion: completion)
    }
}
