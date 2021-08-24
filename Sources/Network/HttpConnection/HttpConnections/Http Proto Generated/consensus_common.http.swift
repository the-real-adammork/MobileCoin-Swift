//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIO
import SwiftProtobuf
import LibMobileCoin


//// Blockchain APIRest shared between clients and peers.
///
/// Usage: instantiate `ConsensusCommon_BlockchainAPIRestClient`, then call methods of this protocol to make APIRest calls.
public protocol ConsensusCommon_BlockchainAPIRestClientProtocol: HTTPClient {
  var serviceName: String { get }

  func getLastBlockInfo(
    _ request: SwiftProtobuf.Google_Protobuf_Empty,
    callOptions: HTTP.CallOptions?
  ) -> HTTPUnaryCall<SwiftProtobuf.Google_Protobuf_Empty, ConsensusCommon_LastBlockInfoResponse>

  func getBlocks(
    _ request: ConsensusCommon_BlocksRequest,
    callOptions: HTTP.CallOptions?
  ) ->HTTPUnaryCall<ConsensusCommon_BlocksRequest, ConsensusCommon_BlocksResponse>
}

extension ConsensusCommon_BlockchainAPIRestClientProtocol {
  public var serviceName: String {
    return "consensus_common.BlockchainAPIRest"
  }

  /// Unary call to GetLastBlockInfo
  ///
  /// - Parameters:
  ///   - request: Request to send to GetLastBlockInfo.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func getLastBlockInfo(
    _ request: SwiftProtobuf.Google_Protobuf_Empty,
    callOptions: HTTP.CallOptions? = nil
  ) ->HTTPUnaryCall<SwiftProtobuf.Google_Protobuf_Empty, ConsensusCommon_LastBlockInfoResponse> {
    return self.makeUnaryCall(
      path: "/consensus_common.BlockchainAPIRest/GetLastBlockInfo",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions
    )
  }

  /// Unary call to GetBlocks
  ///
  /// - Parameters:
  ///   - request: Request to send to GetBlocks.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func getBlocks(
    _ request: ConsensusCommon_BlocksRequest,
    callOptions: HTTP.CallOptions? = nil
  ) ->HTTPUnaryCall<ConsensusCommon_BlocksRequest, ConsensusCommon_BlocksResponse> {
    return self.makeUnaryCall(
      path: "/consensus_common.BlockchainAPIRest/GetBlocks",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions
    )
  }
}

public final class ConsensusCommon_BlockchainAPIRestClient: ConsensusCommon_BlockchainAPIRestClientProtocol {
  public var defaultCallOptions: HTTP.CallOptions

  /// Creates a client for the consensus_common.BlockchainAPIRest service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  public init(
    defaultCallOptions: HTTP.CallOptions = HTTP.CallOptions()
  ) {
    self.defaultCallOptions = defaultCallOptions
  }
}

