//
//  LogWorkoutViewModel.swift
//  FitnessTracker
//
//  ViewModel for logging workout via voice
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LogWorkoutViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String = ""
    @Published var parsedWorkout: WorkoutSession?

    private let openAIService = OpenAIService()
    private let repository = WorkoutRepository()
    private var availableTemplates: [WorkoutSession] = []

    // MARK: - Process Transcription

    func processTranscription(_ transcription: String) async {
        guard !transcription.isEmpty else {
            errorMessage = "No speech detected. Please try again."
            return
        }

        isProcessing = true
        errorMessage = ""

        do {
            print("🔄 Processing transcription: \(transcription)")

            // Fetch available templates (for template matching)
            availableTemplates = repository.fetchTemplates()
            print("📋 Available templates: \(availableTemplates.map { $0.name ?? "Unnamed" })")

            // Get previous workout for "same as last time" reference
            let previousWorkouts = repository.fetchAllWorkouts()
            let previousWorkout = previousWorkouts.first

            // Parse workout using OpenAI (now with template context)
            let workout = try await openAIService.parseWorkoutText(
                transcription,
                previousWorkout: previousWorkout,
                availableTemplates: availableTemplates
            )

            print("✅ Workout parsed successfully: \(workout.exercises.count) exercises")
            parsedWorkout = workout
            isProcessing = false

        } catch let error as OpenAIError {
            print("❌ OpenAI error: \(error.errorDescription ?? "")")
            errorMessage = error.errorDescription ?? "Failed to parse workout"
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
        parsedWorkout = nil
    }
}
