//
//  GRPCServerAppApp.swift
//  GRPCServerApp
//
//  Created by Oliver Epper on 30.05.21.
//

import SwiftUI
import ComposableArchitecture
import Server

@main
struct GRPCServerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: ServerState(),
                                     reducer: serverReducer,
                                     environment: .live))
        }
    }
}
