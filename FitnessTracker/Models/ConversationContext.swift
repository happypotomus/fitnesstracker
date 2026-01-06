//
//  ConversationContext.swift
//  FitnessTracker
//
//  Manages conversation history for context-aware queries
//

import Foundation

struct ConversationContext {
    var messages: [ChatMessage]
    let maxContextMessages: Int = 10 // Limit to prevent token overflow

    init(messages: [ChatMessage] = []) {
        self.messages = messages
    }

    /// Returns recent messages for context (last N pairs)
    func getRecentContext() -> [ChatMessage] {
        // Keep last maxContextMessages to stay within token limits
        return Array(messages.suffix(maxContextMessages))
    }

    /// Formats conversation for OpenAI prompt
    func formatForPrompt() -> String {
        let recentMessages = getRecentContext()
        return recentMessages.map { message in
            let role = message.isUser ? "User" : "Assistant"
            return "\(role): \(message.content)"
        }.joined(separator: "\n")
    }

    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }

    mutating func clear() {
        messages.removeAll()
    }
}
