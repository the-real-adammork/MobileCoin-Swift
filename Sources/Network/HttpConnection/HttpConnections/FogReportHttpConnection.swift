//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogReportHttpConnection: ArbitraryHttpConnection, FogReportService {
    private let client: Report_ReportAPIRestClient
    let requester: HTTPRequester

    init(url: FogUrl, requester: HTTPRequester? = nil, targetQueue: DispatchQueue?) {
        self.client = Report_ReportAPIRestClient()
        self.requester = HTTPRequester(baseUrl: url.httpBasedUrl, trustRoots: [])
        super.init(url: url, targetQueue: targetQueue)
    }

    func getReports(
        request: Report_ReportRequest,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        performCall(GetReportsCall(client: client, requester: requester), request: request, completion: completion)
    }
}

extension FogReportHttpConnection {
    private struct GetReportsCall: HttpCallable {
        let client: Report_ReportAPIRestClient
        let requester: HTTPRequester

        func call(
            request: Report_ReportRequest,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<Report_ReportResponse>) -> Void
        ) {
            let unaryCall = client.getReports(request, callOptions: callOptions)
            requester.makeRequest(call: unaryCall, completion: completion)
        }
    }
}
