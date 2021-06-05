//
//  File.swift
//  
//
//  Created by Oliver Epper on 04.06.21.
//
import GRPC
import SwiftProtobuf
import NIO
import os.log

func send(message text: String, port: Int) {
    let connection = ClientConnection(
        configuration: .init(
            target: .hostAndPort("localhost", port),
            eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1)
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
