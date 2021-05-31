//
//  File.swift
//  
//
//  Created by Oliver Epper on 30.05.21.
//

import Combine
import Foundation
import GRPC
import NIO
import os.log

class GRPCServer {
    static var dependencies: [AnyHashable: Any] = [:]

    static func startServer(id: AnyHashable) -> AnyPublisher<String, Error> {
        let subject = PassthroughSubject<String, Error>()

        func getGroup() -> MultiThreadedEventLoopGroup {
            if let group = dependencies[id] as? MultiThreadedEventLoopGroup {
                return group
            } else {
                let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
                dependencies[id] = group
                return group
            }
        }

        let server = Server.insecure(group: getGroup())
            .bind(host: "localhost", port: 0)

        server.map {
            $0.channel.localAddress
        }.whenSuccess { address in
            if let address = address {
                os_log("Server started %@", type: .debug, String(describing: address))
                subject.send(address.description)
            }
            subject.send(completion: .finished)
        }

        server.whenFailure { error in
            subject.send(completion: .failure(error))
        }

        return subject.eraseToAnyPublisher()
    }

    static func stopServer(id: AnyHashable) -> AnyPublisher<AnyHashable?, Error> {
        return Future { promise in
            guard let group = dependencies[id] as? MultiThreadedEventLoopGroup else {
                promise(.success(nil))
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
        }.eraseToAnyPublisher()
    }

    static func stopServerOld(id: AnyHashable) -> AnyPublisher<AnyHashable, Error> {
        let subject = CurrentValueSubject<AnyHashable, Error>(AnyHashable.init(1))

        guard let group = dependencies[id] as? MultiThreadedEventLoopGroup else {
            subject.send(completion: .finished)
            return subject.eraseToAnyPublisher()
        }

        group.shutdownGracefully { error in
            if let error = error {
                subject.send(completion: .failure(error))
            } else {
                dependencies[id] = nil
                DispatchQueue.main.async { // Dirty Fix. Should not be necessary
                    subject.send(id)
                    subject.send(completion: .finished)
                }
            }
        }

        return subject.eraseToAnyPublisher()
    }
}
