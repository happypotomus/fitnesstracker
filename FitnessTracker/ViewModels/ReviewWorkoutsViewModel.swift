//
//  ReviewWorkoutsViewModel.swift
//  FitnessTracker
//
//  Manages chat state for reviewing workout history with AI
//

import Foundation
import Combine

@MainActor
class ReviewWorkoutsViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    private var conversationContext = ConversationContext()
    private let openAIService = OpenAIService()
    private let repository = WorkoutRepository()

    // Example questions that appear as chips
    let exampleQuestions: [String] = [
        "What exercises did I do most last month?",
        "Show me my bench press progress",
        "How many workouts this week?",
        "What was my heaviest squat?"
    ]

    init() {
        // Start with a welcome message
        let welcomeMessage = ChatMessage(
            content: "Hi! Ask me anything about your workout history. You can tap an example question above or type/speak your own question.",
            isUser: false
        )
        messages.append(welcomeMessage)
    }

    // MARK: - Public Methods

    /// Send a question (from user input or example chip)
    func sendQuestion(_ question: String) async {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add user message to chat
        let userMessage = ChatMessage(content: trimmedQuestion, isUser: true)
        messages.append(userMessage)
        conversationContext.addMessage(userMessage)

        // Clear input field
        inputText = ""

        // Set processing state
        isProcessing = true
        errorMessage = ""
        showError = false

        do {
            // Fetch all workouts for context
            let workouts = repository.fetchAllWorkouts()

            // Check if user has any workout data
            guard !workouts.isEmpty else {
                let errorResponse = "I don't see any workout data yet. Start logging workouts to ask questions about your progress!"
                let aiMessage = ChatMessage(content: errorResponse, isUser: false)
                messages.append(aiMessage)
                conversationContext.addMessage(aiMessage)
                isProcessing = false
                return
            }

            // Query OpenAI with conversation context
            let response = try await openAIService.queryWorkoutHistoryWithContext(
                trimmedQuestion,
                workouts: workouts,
                conversationContext: conversationContext
            )

            // Add AI response to chat
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)
            conversationContext.addMessage(aiMessage)

        } catch let error as OpenAIError {
            handleError(error)
        } catch {
            handleError(.networkError(error))
        }

        isProcessing = false
    }

    /// Start a new conversation (clear history)
    func startNewConversation() {
        messages.removeAll()
        conversationContext.clear()

        // Add welcome message
        let welcomeMessage = ChatMessage(
            content: "Hi! Ask me anything about your workout history. You can tap an example question above or type/speak your own question.",
            isUser: false
        )
        messages.append(welcomeMessage)

        inputText = ""
        errorMessage = ""
        showError = false
    }

    /// Handle voice transcription completion
    func handleVoiceInput(_ transcription: String) {
        inputText = transcription
    }

    // MARK: - Private Methods

    private func handleError(_ error: OpenAIError) {
        errorMessage = error.errorDescription ?? "An unknown error occurred"
        showError = true

        // Add error message to chat
        let errorChatMessage = ChatMessage(
            content: "Sorry, I encountered an error: \(errorMessage). Please try again.",
            isUser: false
        )
        messages.append(errorChatMessage)
    }
}
