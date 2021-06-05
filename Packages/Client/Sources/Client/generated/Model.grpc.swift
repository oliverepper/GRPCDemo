//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: Model.proto
//

//
// Copyright 2018, gRPC Authors All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import GRPC
import NIO
import SwiftProtobuf


/// Usage: instantiate `SimpleClient`, then call methods of this protocol to make API calls.
internal protocol SimpleClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: SimpleClientInterceptorFactoryProtocol? { get }

  func send(
    _ request: SimpleMessage,
    callOptions: CallOptions?
  ) -> UnaryCall<SimpleMessage, SwiftProtobuf.Google_Protobuf_Empty>
}

extension SimpleClientProtocol {
  internal var serviceName: String {
    return "Simple"
  }

  /// Unary call to Send
  ///
  /// - Parameters:
  ///   - request: Request to send to Send.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func send(
    _ request: SimpleMessage,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<SimpleMessage, SwiftProtobuf.Google_Protobuf_Empty> {
    return self.makeUnaryCall(
      path: "/Simple/Send",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeSendInterceptors() ?? []
    )
  }
}

internal protocol SimpleClientInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when invoking 'send'.
  func makeSendInterceptors() -> [ClientInterceptor<SimpleMessage, SwiftProtobuf.Google_Protobuf_Empty>]
}

internal final class SimpleClient: SimpleClientProtocol {
  internal let channel: GRPCChannel
  internal var defaultCallOptions: CallOptions
  internal var interceptors: SimpleClientInterceptorFactoryProtocol?

  /// Creates a client for the Simple service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  internal init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: SimpleClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

/// To build a server, implement a class that conforms to this protocol.
internal protocol SimpleProvider: CallHandlerProvider {
  var interceptors: SimpleServerInterceptorFactoryProtocol? { get }

  func send(request: SimpleMessage, context: StatusOnlyCallContext) -> EventLoopFuture<SwiftProtobuf.Google_Protobuf_Empty>
}

extension SimpleProvider {
  internal var serviceName: Substring { return "Simple" }

  /// Determines, calls and returns the appropriate request handler, depending on the request's method.
  /// Returns nil for methods not handled by this service.
  internal func handle(
    method name: Substring,
    context: CallHandlerContext
  ) -> GRPCServerHandlerProtocol? {
    switch name {
    case "Send":
      return UnaryServerHandler(
        context: context,
        requestDeserializer: ProtobufDeserializer<SimpleMessage>(),
        responseSerializer: ProtobufSerializer<SwiftProtobuf.Google_Protobuf_Empty>(),
        interceptors: self.interceptors?.makeSendInterceptors() ?? [],
        userFunction: self.send(request:context:)
      )

    default:
      return nil
    }
  }
}

internal protocol SimpleServerInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when handling 'send'.
  ///   Defaults to calling `self.makeInterceptors()`.
  func makeSendInterceptors() -> [ServerInterceptor<SimpleMessage, SwiftProtobuf.Google_Protobuf_Empty>]
}