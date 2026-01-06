//
//  ReviewNutritionViewModel.swift
//  FitnessTracker
//
//  Manages chat state for reviewing nutrition history with AI
//

import Foundation
import Combine

@MainActor
class ReviewNutritionViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    private var conversationContext = ConversationContext()
    private let openAIService = OpenAIService()
    private let repository = NutritionRepository()
    private let calendar = Calendar.current

    // Example questions that appear as chips
    let exampleQuestions: [String] = [
        "How much protein did I eat yesterday?",
        "What was my average calorie intake this week?",
        "Show me my breakfast meals",
        "Am I eating enough protein?"
    ]

    init() {
        // Start with a welcome message
        let welcomeMessage = ChatMessage(
            content: "Hi! Ask me anything about your nutrition history. You can tap an example question above or type/speak your own question.",
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
            // Fetch all meals for context
            let meals = repository.fetchAllMeals()

            // Check if user has any meal data
            guard !meals.isEmpty else {
                let errorResponse = "I don't see any meal data yet. Start logging meals to ask questions about your nutrition!"
                let aiMessage = ChatMessage(content: errorResponse, isUser: false)
                messages.append(aiMessage)
                conversationContext.addMessage(aiMessage)
                isProcessing = false
                return
            }

            // Query OpenAI with conversation context
            let response = try await openAIService.queryNutritionHistoryWithContext(
                trimmedQuestion,
                meals: meals,
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

        let welcomeMessage = ChatMessage(
            content: "Starting fresh! Ask me anything about your nutrition history.",
            isUser: false
        )
        messages.append(welcomeMessage)

        conversationContext.clear()
    }

    // MARK: - Private Methods

    private func handleError(_ error: OpenAIError) {
        errorMessage = error.errorDescription ?? "An error occurred"
        showError = true

        // Also add error message to chat
        let errorChatMessage = ChatMessage(
            content: "Sorry, I encountered an error: \(errorMessage)",
            isUser: false
        )
        messages.append(errorChatMessage)
    }

    // MARK: - Date Filtering for Calendar

    /// Fetch meals for a specific date
    func fetchMeals(for date: Date) -> [MealSession] {
        let allMeals = repository.fetchAllMeals()
        return allMeals.filter { meal in
            calendar.isDate(meal.date, inSameDayAs: date)
        }
    }

    /// Get all dates that have meals in a specific month
    func getDatesWithMeals(in month: Date) -> [Date] {
        guard let range = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        let meals = repository.fetchMeals(from: range.start, to: range.end)
        return meals.map { calendar.startOfDay(for: $0.date) }
    }

    /// Delete a meal
    func deleteMeal(_ meal: MealSession) -> Bool {
        return repository.deleteMeal(id: meal.id)
    }
}
