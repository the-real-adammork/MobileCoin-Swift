//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// A unary http call. The request is sent on initialization.
///
/// Note: while this object is a `struct`, its implementation delegates to `Call`. It therefore
/// has reference semantics.
public struct HTTPUnaryCall<RequestPayload, ResponsePayload> : HTTPUnaryResponseClientCall {

    /// The options used in the URLSession
    public var options: HTTP.CallOptions?

    /// Cancel this session if it hasn't already completed.
    public func cancel() { }

    /// The initial metadata returned from the server.
    public var initialMetadata: HTTPURLResponse? = nil

    /// The request returned by the server.
    public var request: RequestPayload?

    /// The response returned by the server.
    public var responseType: ResponsePayload.Type
    public var response: ResponsePayload? = nil

    /// The final status of the the RPC.
    public var status: HTTPStatus? = nil
}
