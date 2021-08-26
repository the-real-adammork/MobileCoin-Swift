//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogMerkleProofHttpConnection: AttestedHttpConnection, FogMerkleProofService {
    private let client: AuthHttpCallableClientWrapper<FogLedger_FogMerkleProofAPIRestClient>
    private let requester : HTTPRequester

    init(
        config: AttestedConnectionConfig<FogUrl>,
        requester: HTTPRequester? = nil,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        self.requester = HTTPRequester(baseUrl: config.url.httpBasedUrl, trustRoots: config.trustRoots)
        self.client = AuthHttpCallableClientWrapper(client:FogLedger_FogMerkleProofAPIRestClient(), requester: self.requester)
        super.init(
            client: self.client,
            requester: self.requester,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func getOutputs(
        request: FogLedger_GetOutputsRequest,
        completion: @escaping (Result<FogLedger_GetOutputsResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            GetOutputsCall(client: client, requester: self.requester),
            request: request,
            completion: completion)
    }
}

extension FogMerkleProofHttpConnection {
    private struct GetOutputsCall: AttestedHttpCallable {
        typealias InnerRequest = FogLedger_GetOutputsRequest
        typealias InnerResponse = FogLedger_GetOutputsResponse

        let client: AuthHttpCallableClientWrapper<FogLedger_FogMerkleProofAPIRestClient>
        let requester: HTTPRequester

        func call(
            request: Attest_Message,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<Attest_Message>) -> Void
        ) {
            let unaryCall = client.getOutputs(request, callOptions: callOptions)
            requester.makeRequest(call: unaryCall, completion: completion)
        }
    }
}

extension FogLedger_FogMerkleProofAPIRestClient: AuthHttpCallee, OutputsHttpCallee {}

