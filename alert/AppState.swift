//
//  AppState.swift
//  alert
//
//  Global app state management for Phase 1
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var userMode: UserMode = .responsavel
    @Published var showingSplash = true
    @Published var selectedChild: Child?
    @Published var currentChildName = "João" // For child mode

    // Navigation
    @Published var navigationPath = NavigationPath()

    // Mock data
    let mockData = MockData.shared

    func finishSplash() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showingSplash = false
            }
        }
    }

    func toggleMode() {
        userMode = userMode == .responsavel ? .crianca : .responsavel
    }
}
