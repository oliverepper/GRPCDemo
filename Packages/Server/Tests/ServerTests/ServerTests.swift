import XCTest
@testable import Server
import ComposableArchitecture
import Combine

final class ServerTests: XCTestCase {
    func testServerStart() {
        let scheduler = DispatchQueue.test

        let testEnvironment = ServerEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                                startServer: { id in
                                                    Just("mocked_address")
                                                        .setFailureType(to: ServerError.self)
                                                        .eraseToEffect()
                                                }, createSubscription: { _ in
                                                    Just(ServerAction.subscriptionCreated)
                                                        .eraseToEffect()
                                                })

        let store = TestStore(initialState: ServerState(),
                              reducer: serverReducer,
                              environment: testEnvironment)

        store.send(.startServerBtnTapped)

        scheduler.advance()

        store.receive(.serverStarted(.success("mocked_address"))) {
            $0.isRunning = true
            $0.address = "mocked_address"
        }

        scheduler.advance()

        store.receive(.subscriptionCreated)
    }

    func testServerStopped() {
        let scheduler = DispatchQueue.test

        let testEnvironment = ServerEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                                stopServer: { id in
                                                    Just(AnyHashable(4711))
                                                        .setFailureType(to: ServerError.self)
                                                        .eraseToEffect()
                                                })

        let store = TestStore(initialState: ServerState(),
                              reducer: serverReducer,
                              environment: testEnvironment)

        store.send(.stopServerBtnTapped)

        scheduler.advance()

        store.receive(.serverStopped(.success(4711))) {
            $0.address = nil
            $0.isRunning = false
        }
    }

    func testServerStartFail() {
        let scheduler = DispatchQueue.test

        let startFail = ServerEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                          startServer: { _ in
                                            return .init(error: .couldNotStart)
                                          }, createSubscription: { _ in
                                            Just(ServerAction.subscriptionCreated)
                                                .eraseToEffect()
                                          })

        let store = TestStore(initialState: ServerState(),
                              reducer: serverReducer,
                              environment: startFail)

        store.send(.startServerBtnTapped)

        scheduler.advance()

        store.receive(.serverStarted(.failure(.couldNotStart))) {
            $0.error = .couldNotStart
        }
    }

    func testServerStopFail() {
        let scheduler = DispatchQueue.test

        let stopFail = ServerEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                         stopServer: { _ in
                                            return .init(error: .couldNotStop)
                                         })

        let store = TestStore(initialState: ServerState(),
                              reducer: serverReducer,
                              environment: stopFail)

        store.send(.stopServerBtnTapped)

        scheduler.advance()

        store.receive(.serverStopped(.failure(.couldNotStop))) {
            $0.error = .couldNotStop
        }
    }

    func testCreateSubscription() {
        let scheduler = DispatchQueue.test

        let environment = ServerEnvironment(
            mainQueue: scheduler.eraseToAnyScheduler(),
            createSubscription: { _ in
                Effect(value: ServerAction.subscriptionCreated)
            })

        let store = TestStore(initialState: ServerState(),
                              reducer: serverReducer,
                              environment: environment)

        store.send(.createSubscriptionBtnTapped)

        scheduler.advance()

        store.receive(.subscriptionCreated)
    }

    func testReceiveMessageFlow() {
        let store = TestStore(initialState: ServerState(),
                              reducer: serverReducer,
                              environment: ServerEnvironment())

        let message = UUID().uuidString

        store.send(.messageReceived(message)) {
            $0.alert = .init(
                title: .init("Message Received"),
                message: TextState(message),
                dismissButton: .default(TextState("Ok"), send: .alertDismissed(message)))
        }

        store.send(.alertDismissed(message)) {
            $0.receivedMessage = message
        }
    }
}
