//
//  LogMealViewModel.swift
//  FitnessTracker
//
//  ViewModel for logging meals via voice
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LogMealViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String = ""
    @Published var parsedMeal: MealSession?

    private let openAIService = OpenAIService()
    private let repository = NutritionRepository()
    private var availableTemplates: [MealSession] = []

    // MARK: - Process Transcription

    func processTranscription(_ transcription: String) async {
        guard !transcription.isEmpty else {
            errorMessage = "No speech detected. Please try again."
            return
        }

        isProcessing = true
        errorMessage = ""

        do {
            print("🔄 Processing meal transcription: \(transcription)")

            // Fetch available templates (for template matching)
            availableTemplates = repository.fetchTemplates()
            print("📋 Available meal templates: \(availableTemplates.map { $0.name ?? "Unnamed" })")

            // Get previous meal for "same as last time" reference
            let previousMeals = repository.fetchAllMeals()
            let previousMeal = previousMeals.first

            // Parse meal using OpenAI (now with template context)
            let meal = try await openAIService.parseMealText(
                transcription,
                previousMeal: previousMeal,
                availableTemplates: availableTemplates
            )

            print("✅ Meal parsed successfully: \(meal.foodItems.count) food items")
            parsedMeal = meal
            isProcessing = false

        } catch let error as OpenAIError {
            print("❌ OpenAI error: \(error.errorDescription ?? "")")
            errorMessage = error.errorDescription ?? "Failed to parse meal"
            isProcessing = false
        } catch {
            print("❌ Unexpected error: \(error)")
            errorMessage = "An unexpected error occurred. Please try again."
            isProcessing = false
        }
    }

    // MARK: - Retry

    func retry() {
        errorMessage = ""
        parsedMeal = nil
    }
}
