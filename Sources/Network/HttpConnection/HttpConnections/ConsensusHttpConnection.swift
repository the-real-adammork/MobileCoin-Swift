//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class ConsensusHttpConnection: AttestedHttpConnection, ConsensusService {
    private let client: AuthHttpCallableCloientWrapper<FogView_FogViewAPIRestClient>
    private let requester: HTTPRequester

    init(
        config: AttestedConnectionConfig<ConsensusUrl>,
        requester: HTTPRequester? = nil,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        self.requester = HTTPRequester(baseUrl: config.url.httpBasedUrl, trustRoots: config.trustRoots)
        self.client = AuthHttpCallableCloientWrapper(client: ConsensusClient_ConsensusClientAPIRestClient(), requester: self.requester)
        super.init(
            client: AuthHttpCallableCloientWrapper(client: Attest_AttestedApiRestClient(), requester: self.requester),
            requester: self.requester,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func proposeTx(
        _ tx: External_Tx,
        completion: @escaping (Result<ConsensusCommon_ProposeTxResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            ProposeTxCall(client: client, requester: requester),
            request: tx,
            completion: completion)
    }
}

extension ConsensusHttpConnection {
    private struct ProposeTxCall: AttestedHttpCallable {
        typealias InnerRequest = External_Tx
        typealias InnerResponse = ConsensusCommon_ProposeTxResponse

        let client: AuthHttpCallableCloientWrapper<FogView_FogViewAPIRestClient>
        let requester: HTTPRequester


        func call(
            request: Attest_Message,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<ConsensusCommon_ProposeTxResponse>) -> Void
        ) {
            let clientCall = client.clientTxPropose(request, callOptions: callOptions)
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

extension Attest_AttestedApiRestClient: AuthHttpCalleeAndClient {}
extension ConsensusClient_ConsensusClientAPIRestClient: AuthHttpCalleeAndClient {}
