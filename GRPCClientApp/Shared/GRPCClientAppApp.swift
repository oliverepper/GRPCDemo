//
//  GRPCClientAppApp.swift
//  Shared
//
//  Created by Oliver Epper on 04.06.21.
//

import SwiftUI
import ComposableArchitecture
import Client

@main
struct GRPCClientAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: ClientState(),
                                     reducer: clientReducer,
                                     environment: .live))
        }
    }
}
