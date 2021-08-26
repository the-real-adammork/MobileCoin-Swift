//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogUntrustedTxOutHttpConnection: HttpConnection, FogUntrustedTxOutService {
    private let client: FogLedger_FogUntrustedTxOutApiRestClient
    private let requester : HTTPRequester

    init(
        config: ConnectionConfig<FogUrl>,
        requester: HTTPRequester? = nil,
        targetQueue: DispatchQueue?
    ) {
        self.client = FogLedger_FogUntrustedTxOutApiRestClient()
        self.requester = HTTPRequester(baseUrl: config.url.httpBasedUrl, trustRoots: config.trustRoots)
        super.init(config: config, targetQueue: targetQueue)
    }

    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, ConnectionError>) -> Void
    ) {
        performCall(GetTxOutsCall(client: client, requester: self.requester), request: request, completion: completion)
    }
}

extension FogUntrustedTxOutHttpConnection {
    private struct GetTxOutsCall: HttpCallable {
        let client: FogLedger_FogUntrustedTxOutApiRestClient
        let requester: HTTPRequester

        func call(
            request: FogLedger_TxOutRequest,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<FogLedger_TxOutResponse>) -> Void
        ) {
            let unaryCall = client.getTxOuts(request, callOptions: callOptions)
            requester.makeRequest(call: unaryCall, completion: completion)
        }
    }
}
