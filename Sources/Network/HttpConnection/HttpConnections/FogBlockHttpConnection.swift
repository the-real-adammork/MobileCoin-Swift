//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
//  swiftlint:disable all

import Foundation
import LibMobileCoin


final class FogBlockHttpConnection: HttpConnection, FogBlockService {
    private let client: FogLedger_FogBlockAPI
    private let requester: HTTPRequester

    init(
        config: ConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?
    ) {
        self.client = FogLedger_FogBlockAPI()
        self.requester = HTTPRequester(baseUrl: config.url.httpBasedUrl, trustRoots: config.trustRoots)
        super.init(config: config, targetQueue: targetQueue)
    }

    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, ConnectionError>) -> Void
    ) {
        performCall(GetBlocksCall(client: client, requester: requester), request: request, completion: completion)
    }
}

extension FogBlockHttpConnection {
    private struct GetBlocksCall: HttpCallable {
        let client: FogLedger_FogBlockAPI
        let requester: HTTPRequester

        func call(
            request: FogLedger_BlockRequest,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<FogLedger_BlockResponse>) -> Void
        ) {
            let clientCall = client.getBlocks(request, callOptions: callOptions)
            requester.makeRequest(call: clientCall) { result in
                switch result {
                case .success(let callResult):
                    completion(callResult)
                case .failure(let error):
                    logger.error(error.localizedDescription)
                }
            }
        }
    }
}
