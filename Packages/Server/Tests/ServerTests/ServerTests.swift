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
}
