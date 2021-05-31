import ComposableArchitecture
import SwiftUI
import Combine

public struct ServerState: Equatable {
    var isRunning = false
    var address: String? = nil
    var error: ServerError?

    public init(isRuning: Bool = false, address: String? = nil) {
        self.isRunning = isRuning
        self.address = address
    }
}

public enum ServerAction: Equatable {
    case startServerBtnTapped
    case serverStarted(Result<String, ServerError>)

    case stopServerBtnTapped
    case serverStopped(Result<AnyHashable?, ServerError>)
}

public enum ServerError: Error, Equatable {
    case couldNotStart
    case couldNotStop
}

public struct ServerEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
    var startServer: (AnyHashable) -> Effect<String, ServerError> = { _ in fatalError() }
    var stopServer: (AnyHashable) -> Effect<AnyHashable?, ServerError> = { _ in fatalError() }

    func startServer(id: AnyHashable) -> Effect<String, ServerError> {
        startServer(id)
    }

    func stopServer(id: AnyHashable) -> Effect<AnyHashable?, ServerError> {
        stopServer(id)
    }
}

extension ServerEnvironment {
    public static let mock = ServerEnvironment(
        mainQueue: .main
    ) { id in
        print("Starting server \(id.hashValue)")
        return Just("mocked_address")
            .delay(for: 0.5, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global(qos: .background))
            .setFailureType(to: ServerError.self)
            .eraseToEffect()
    } stopServer: { id in
        print("Stopping server: \(id.hashValue)")
        return Just(id)
            .delay(for: 0.5, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global(qos: .background))
            .setFailureType(to: ServerError.self)
            .eraseToEffect()
    }
}

extension ServerEnvironment {
    public static let live = ServerEnvironment(
        mainQueue: .main
    ) { id in
        return GRPCServer.startServer(id: id)
            .mapError { _ in ServerError.couldNotStart }
            .eraseToEffect()
    } stopServer: { id in
        return GRPCServer.stopServer(id: id)
            .mapError { _ in ServerError.couldNotStop }
            .eraseToEffect()
    }
}

public let serverReducer = Reducer<ServerState, ServerAction, ServerEnvironment> { state, action, environment in
    struct GRPCServerId: Hashable {}

    switch action {

    case .startServerBtnTapped:
        return environment.startServer(id: GRPCServerId())
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(ServerAction.serverStarted)

    case .serverStarted(.success(let address)):
        state.isRunning = true
        state.address = address
        return .none

    case .serverStarted(.failure(let error)):
        state.error = error
        return .fireAndForget {
            print(error)
        }

    case .stopServerBtnTapped:
        return environment.stopServer(id: GRPCServerId())
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(ServerAction.serverStopped)

    case .serverStopped(.success(let id)):
        state.isRunning = false
        state.address = nil
        return .none

    case .serverStopped(.failure(let error)):
        state.error = error
        return .fireAndForget {
            print(error)
        }
    }
}

public struct ContentView: View {
    let store: Store<ServerState, ServerAction>

    public init(store: Store<ServerState, ServerAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                if viewStore.state.isRunning {
                    if let address = viewStore.state.address {
                        Text("Server running: \(address)")
                    }
                } else {
                    Text("Server stopped")
                }
                HStack {
                    Button("Start Server") {
                        viewStore.send(.startServerBtnTapped)
                    }.disabled(viewStore.state.isRunning)
                    Button("Stop Server") {
                        viewStore.send(.stopServerBtnTapped)
                    }.disabled(!viewStore.state.isRunning)
                }
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: ServerState(),
                                 reducer: serverReducer,
                                 environment: .mock))
    }
}
