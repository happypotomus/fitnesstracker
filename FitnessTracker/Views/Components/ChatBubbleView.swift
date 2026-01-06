//
//  ChatBubbleView.swift
//  FitnessTracker
//
//  Chat bubble for user and AI messages
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            }

            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}

#Preview {
    VStack {
        ChatBubbleView(message: ChatMessage(
            content: "What exercises did I do most last month?",
            isUser: true
        ))

        ChatBubbleView(message: ChatMessage(
            content: "Based on your workout history, you did bench press the most last month, with a total of 15 sessions. You also did squats 12 times and deadlifts 10 times.",
            isUser: false
        ))
    }
}
