//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogViewHttpConnection: AttestedHttpConnection, FogViewService {
    private let client: FogView_FogViewAPIRestClient
    private let requester : HTTPRequester

    init(
        config: AttestedConnectionConfig<FogUrl>,
        requester: HTTPRequester? = nil,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        self.client = FogView_FogViewAPIRestClient()
        self.requester = HTTPRequester(baseUrl: config.url.httpBasedUrl, trustRoots: config.trustRoots)
        super.init(
            client: self.client,
            requester: self.requester,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func query(
        requestAad: FogView_QueryRequestAAD,
        request: FogView_QueryRequest,
        completion: @escaping (Result<FogView_QueryResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            EnclaveRequestCall(client: client, requester:requester),
            requestAad: requestAad,
            request: request,
            completion: completion)
    }
}

extension FogViewHttpConnection {
    private struct EnclaveRequestCall: AttestedHttpCallable {
        typealias InnerRequestAad = FogView_QueryRequestAAD
        typealias InnerRequest = FogView_QueryRequest
        typealias InnerResponse = FogView_QueryResponse

        let client: FogView_FogViewAPIRestClient
        let requester: HTTPRequester

        func call(
            request: Attest_Message,
            requester: HTTPRequester,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<Attest_Message>) -> Void
        ) {
            let clientCall = client.query(request, callOptions: callOptions)
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

extension FogView_FogViewAPIRestClient: AuthHttpCallableClient {
    var requester: HTTPRequester {
    }
}
