//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import SwiftProtobuf


///// Usage: instantiate `ConsensusClient_ConsensusClientAPIClient`, then call methods of this protocol to make API calls.
//public protocol ConsensusClient_ConsensusClientAPIClientProtocol: GRPCClient {
//  var serviceName: String { get }
//  var interceptors: ConsensusClient_ConsensusClientAPIClientInterceptorFactoryProtocol? { get }
//
//  func clientTxPropose(
//    _ request: Attest_Message,
//    callOptions: CallOptions?
//  ) -> UnaryCall<Attest_Message, ConsensusCommon_ProposeTxResponse>
//}
//
//extension ConsensusClient_ConsensusClientAPIClientProtocol {
//  public var serviceName: String {
//    return "consensus_client.ConsensusClientAPI"
//  }
//
//  //// This API call is made with an encrypted payload for the enclave,
//  //// indicating a new value to be acted upon.
//  ///
//  /// - Parameters:
//  ///   - request: Request to send to ClientTxPropose.
//  ///   - callOptions: Call options.
//  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
//  public func clientTxPropose(
//    _ request: Attest_Message,
//    callOptions: CallOptions? = nil
//  ) -> UnaryCall<Attest_Message, ConsensusCommon_ProposeTxResponse> {
//    return self.makeUnaryCall(
//      path: "/consensus_client.ConsensusClientAPI/ClientTxPropose",
//      request: request,
//      callOptions: callOptions ?? self.defaultCallOptions,
//      interceptors: self.interceptors?.makeClientTxProposeInterceptors() ?? []
//    )
//  }
//}
//
//public protocol ConsensusClient_ConsensusClientAPIClientInterceptorFactoryProtocol {
//
//  /// - Returns: Interceptors to use when invoking 'clientTxPropose'.
//  func makeClientTxProposeInterceptors() -> [ClientInterceptor<Attest_Message, ConsensusCommon_ProposeTxResponse>]
//}
//
//public final class ConsensusClient_ConsensusClientAPIClient: ConsensusClient_ConsensusClientAPIClientProtocol {
//  public let channel: GRPCChannel
//  public var defaultCallOptions: CallOptions
//  public var interceptors: ConsensusClient_ConsensusClientAPIClientInterceptorFactoryProtocol?
//
//  /// Creates a client for the consensus_client.ConsensusClientAPI service.
//  ///
//  /// - Parameters:
//  ///   - channel: `GRPCChannel` to the service host.
//  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
//  ///   - interceptors: A factory providing interceptors for each RPC.
//  public init(
//    channel: GRPCChannel,
//    defaultCallOptions: CallOptions = CallOptions(),
//    interceptors: ConsensusClient_ConsensusClientAPIClientInterceptorFactoryProtocol? = nil
//  ) {
//    self.channel = channel
//    self.defaultCallOptions = defaultCallOptions
//    self.interceptors = interceptors
//  }
//}
//
