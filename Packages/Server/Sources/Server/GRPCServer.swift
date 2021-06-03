//
//  File.swift
//  
//
//  Created by Oliver Epper on 30.05.21.
//

import Combine
import ComposableArchitecture
import Foundation
import GRPC
import NIO
import SwiftProtobuf
import os.log

private struct Dependencies {
    let group: MultiThreadedEventLoopGroup
    var simpleMessageSubscriber: Effect<ServerAction, Never>.Subscriber?
    var port: Int?
}

private var dependencies: [AnyHashable: Dependencies] = [:]

class SimpleServiceProvider: SimpleProvider {
    private let id: AnyHashable

    init(id: AnyHashable) {
        self.id = id
    }

    var interceptors: SimpleServerInterceptorFactoryProtocol?

    func send(request: SimpleMessage, context: StatusOnlyCallContext) -> EventLoopFuture<Google_Protobuf_Empty> {
        os_log("Received SimpleMessage: %@", type: .debug, request.text)

        DispatchQueue.main.async {
            dependencies[self.id]?.simpleMessageSubscriber?.send(.messageReceived(request.text))
        }

        return context.eventLoop.makeSucceededFuture(.init())
    }
}


class GRPCServer {
    static func subscribeSimpleService(id: AnyHashable) -> Effect<ServerAction, Never> {
        return Effect.run { subscriber in
            dependencies[id]?.simpleMessageSubscriber = subscriber

            return AnyCancellable {
                dependencies[id]?.simpleMessageSubscriber = nil
            }
        }
    }

    static func startServer(id: AnyHashable) -> Future<String, Error> {
        return Future { promise in
            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            dependencies[id] = Dependencies(
                group: group,
                simpleMessageSubscriber: nil
            )

            let server = Server.insecure(group: group)
                .withServiceProviders([
                    SimpleServiceProvider(id: id)
                ])
                .bind(host: "localhost", port: 0)

            server.map {
                $0.channel.localAddress
            }.whenSuccess { address in
                if let address = address {
                    os_log("Server started %@", type: .debug, String(describing: address))
                    dependencies[id]?.port = address.port
                    promise(.success(address.description))
                }
            }

            server.whenFailure { error in
                promise(.failure(error))
            }
        }
    }

    static func stopServer(id: AnyHashable) -> Future<AnyHashable, Error> {
        return Future { promise in
            guard let group = dependencies[id]?.group else {
                promise(.failure(ServerError.couldNotStop))
                return
            }

            group.shutdownGracefully { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    os_log("Server stopped", type: .debug)
                    dependencies[id] = nil
                    promise(.success(id))
                }
            }
        }
    }

    static func sendSimpleMessage(id: AnyHashable, text: String) {
        guard let port = dependencies[id]?.port else { return }
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let connection = ClientConnection(
            configuration: .init(
                target: .hostAndPort("localhost", port),
                eventLoopGroup: group
            )
        )

        let client = SimpleClient(channel: connection)

        let message = SimpleMessage.with { message in
            message.text = text
        }

        let request = client.send(message)

        request.response.whenComplete { result in
            switch result {
            case .success:
                print("Yeah!")
            case let .failure(error):
                print(error)
            }
        }

        let status = try? request.status.wait()
        os_log("Completed with: %@", type: .debug, status.debugDescription)
    }
}
