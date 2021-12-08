//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

//
//protocol AuthProtocolCallable {
//    associatedtype ProtocolCallOptions
//    associatedtype ProtocolUnaryCallResult
//    
//    func auth(
//        _ request: Attest_AuthMessage,
//        callOptions: ProtocolCallOptions?,
//        completion: @escaping (ProtocolUnaryCallResult<Attest_AuthMessage>) -> Void)
//}
//
//struct AuthProtocolCallableWrapper: ProtocolCallable {
//    let authCallable: AuthGrpcCallable
//
//    func call(
//        request: Attest_AuthMessage,
//        callOptions: ProtocolCallOptions?,
//        completion: @escaping (ProtocolUnaryCallResult<Attest_AuthMessage>) -> Void
//    ) {
//        authCallable.auth(request, callOptions: callOptions, completion: completion)
//    }
//}
