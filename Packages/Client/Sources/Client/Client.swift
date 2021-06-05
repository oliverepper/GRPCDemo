import ComposableArchitecture
import SwiftUI

public struct ClientState: Equatable {
    public init(serverPort: Int = 0, message: String = "") {
        self.serverPort = serverPort
        self.message = message
    }

    var serverPort: Int = 0
    var message: String = ""
}

public enum ClientAction {
    case serverPortChanged(String)
    case messageChanged(String)
    case clearMessageBtnTapped
    case sendMessageBtnTapped
    case messageSend
}

public struct ClientEnvironment {
    var sendMessage: (String, Int) -> Effect<ClientAction, Never>

    func sendMessage(text: String, port: Int) -> Effect<ClientAction, Never> {
        sendMessage(text, port)
    }
}

extension ClientEnvironment {
    public static let mock = ClientEnvironment { text, port in
        print("Message send: \(text) to server on port: \(port)")
        return Effect(value: ClientAction.messageSend)
    }
}

extension ClientEnvironment {
    public static let live = ClientEnvironment { text, port in
        send(message: text, port: port)
        return Effect(value: ClientAction.messageSend)
    }
}

public let clientReducer = Reducer<ClientState, ClientAction, ClientEnvironment> { state, action, environment in
    switch action {
    case .clearMessageBtnTapped:
        state.message = ""
        return .none

    case .messageChanged(let message):
        state.message = message
        return .none

    case .sendMessageBtnTapped:
        let message = state.message
        let port = state.serverPort
        return environment.sendMessage(text: message, port: port)

    case .messageSend:
        state.message = ""
        return .none

    case .serverPortChanged(let port):
        state.serverPort = Int(port) ?? 0
        return .none
    }
}

public struct ContentView: View {
    let store: Store<ClientState, ClientAction>

    public init(store: Store<ClientState, ClientAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                TextField("Please enter your message", text: viewStore.binding(
                            get: { $0.message },
                            send: { .messageChanged($0) })
                )
                HStack {
                    Text("Server Port")
                    TextField("Please enter server port", text: viewStore.binding(
                                get: { $0.serverPort.description },
                                send: { .serverPortChanged($0) })
                    )
                }
                Button("Send") {
                    viewStore.send(.sendMessageBtnTapped)
                }
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: ClientState(),
                                 reducer: clientReducer,
                                 environment: .mock))
    }
}

