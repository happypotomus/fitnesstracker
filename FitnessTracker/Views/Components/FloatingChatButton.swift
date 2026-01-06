//
//  FloatingChatButton.swift
//  FitnessTracker
//
//  Floating blue chat button that expands to full-screen chat
//

import SwiftUI

struct FloatingChatButton: View {
    let accentColor: Color
    let onTap: () -> Void

    @State private var isAnimated: Bool = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .opacity(isAnimated ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                isAnimated = true
            }
        }
    }
}
