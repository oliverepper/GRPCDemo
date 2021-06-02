import ComposableArchitecture
import SwiftUI
import Combine

public struct ServerState: Equatable {
    public init(isRunning: Bool = false, address: String? = nil, error: ServerError? = nil, message: String = "", receivedMessage: String? = nil, alert: AlertState<ServerAction>? = nil) {
        self.isRunning = isRunning
        self.address = address
        self.error = error
        self.message = message
        self.receivedMessage = receivedMessage
        self.alert = alert
    }

    var isRunning = false
    var address: String? = nil
    var error: ServerError? = nil
    var message: String = ""
    var receivedMessage: String? = nil
    var alert: AlertState<ServerAction>? = nil
}

public enum ServerAction: Equatable {
    case startServerBtnTapped
    case serverStarted(Result<String, ServerError>)

    case stopServerBtnTapped
    case serverStopped(Result<AnyHashable?, ServerError>)

    case messageChanged(String)
    case sendMessageBtnTapped

    case messageReceived(String)
    case alertDismissBtnTapped
    case alertDismissed(String)

    case createSubscriptionBtnTapped
    case subscriptionCreated
}

public enum ServerError: Error, Equatable {
    case couldNotStart
    case couldNotStop
}

public struct ServerEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
    var startServer: (AnyHashable) -> Effect<String, ServerError> = { _ in fatalError() }
    var createSubscription: (AnyHashable) -> Effect<ServerAction, Never> = { _ in fatalError() }
    var sendMessage: (AnyHashable, String) -> Void = { _,_ in }
    var stopServer: (AnyHashable) -> Effect<AnyHashable?, ServerError> = { _ in fatalError() }

    func startServer(id: AnyHashable) -> Effect<String, ServerError> {
        startServer(id)
    }

    func createSubscription(id: AnyHashable) -> Effect<ServerAction, Never> {
        createSubscription(id)
    }

    func sendMessage(id: AnyHashable, text: String) -> Void {
        sendMessage(id, text)
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
            .setFailureType(to: ServerError.self)
            .eraseToEffect()
    } createSubscription: { id in
        print("Creating subscription for \(id.hashValue)")
        return Just(ServerAction.subscriptionCreated)
            .eraseToEffect()
    } sendMessage: { id, text in
        print("Sending message: \(text)")
    } stopServer: { id in
        print("Stopping server: \(id.hashValue)")
        return Just(id)
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
    } createSubscription: { id in
        return GRPCServer.subscribeSimpleService(id: id)
    } sendMessage: { id, text in
        GRPCServer.sendSimpleMessage(id: id, text: text)
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
        return environment.createSubscription(id: GRPCServerId())

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

    case .sendMessageBtnTapped:
        let message = state.message
        state.message = ""
        return .fireAndForget {
            environment.sendMessage(id: GRPCServerId(), text: message)
        }

    case .messageChanged(let message):
        state.message = message
        return .none

    case .messageReceived(let message):
        state.alert = .init(title: .init("Message Received"),
                            message: TextState(message),
                            dismissButton: .default(TextState("Ok"), send: .alertDismissed(message)))
        return .none

    case .subscriptionCreated:
        return .fireAndForget {
            print("Subscription created.")
        }

    case .createSubscriptionBtnTapped:
        return environment.createSubscription(id: GRPCServerId())

    case .alertDismissBtnTapped:
        state.alert = nil
        return .none

    case .alertDismissed(let message):
        state.receivedMessage = message
        return .none
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
                if viewStore.isRunning {
                    if let address = viewStore.address {
                        Text("Server running: \(address)")
                    }
                } else {
                    Text("Server stopped")
                }
                if let message = viewStore.receivedMessage {
                    Text(message)
                }
                HStack {
                    Button("Start Server") {
                        viewStore.send(.startServerBtnTapped)
                    }
                    .disabled(viewStore.isRunning)
                    .keyboardShortcut("r")
                    Button("Stop Server") {
                        viewStore.send(.stopServerBtnTapped)
                    }
                    .disabled(!viewStore.isRunning)
                    .keyboardShortcut("p")
                }
                TextField("Enter message", text: viewStore.binding(
                    get: { $0.message },
                    send: { .messageChanged($0) }
                ))
                Button("Send simple message") {
                    viewStore.send(.sendMessageBtnTapped)
                }
                .disabled(!viewStore.isRunning)
                .keyboardShortcut("s")
            }
            .padding()
            .alert(
                self.store.scope(state: \.alert),
                dismiss: .alertDismissBtnTapped
            )
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
