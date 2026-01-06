//
//  ContentView.swift
//  alert
//
//  Main entry point - switches between splash, responsável, and criança modes
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.showingSplash {
                SplashView()
            } else {
                switch appState.userMode {
                case .responsavel:
                    HomeView()
                case .crianca:
                    ChildModeView()
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            appState.finishSplash()
        }
    }
}

#Preview {
    ContentView()
}
