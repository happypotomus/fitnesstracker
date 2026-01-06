//
//  RootView.swift
//  FitnessTracker
//
//  Root view that routes to API key setup or main app
//

import SwiftUI

struct RootView: View {
    @State private var hasAPIKey: Bool = KeychainManager.shared.hasAPIKey()

    var body: some View {
        Group {
            if hasAPIKey {
                // User has set up API key - show main app
                HomeView()
            } else {
                // First launch - show API key setup
                APIKeyInputView {
                    // Callback when key is saved
                    hasAPIKey = true
                }
            }
        }
    }
}

#Preview {
    RootView()
}
