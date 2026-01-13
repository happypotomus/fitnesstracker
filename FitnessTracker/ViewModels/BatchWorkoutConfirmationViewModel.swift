//
//  BatchWorkoutConfirmationViewModel.swift
//  FitnessTracker
//
//  ViewModel for confirming and editing multiple workouts before batch saving
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BatchWorkoutConfirmationViewModel: ObservableObject {
    @Published var workouts: [WorkoutSession]
    @Published var sharedDate: Date
    @Published var isSaving: Bool = false
    @Published var saveError: String = ""
    @Published var saveSuccessCount: Int = 0
    @Published var saveFailureCount: Int = 0

    private let repository = WorkoutRepository()

    init(workouts: [WorkoutSession]) {
        self.workouts = workouts
        // Use the first workout's date as the shared date
        self.sharedDate = workouts.first?.date ?? Date()
    }

    // MARK: - Update Workout

    func updateWorkout(at index: Int, with updatedWorkout: WorkoutSession) {
        guard index < workouts.count else { return }
        workouts[index] = updatedWorkout
    }

    // MARK: - Apply Shared Date

    func applySharedDateToAll() {
        for i in 0..<workouts.count {
            workouts[i].date = sharedDate
        }
    }

    // MARK: - Validation

    func validateWorkouts() -> Bool {
        guard !workouts.isEmpty else {
            saveError = "No workouts to save"
            return false
        }

        for (index, workout) in workouts.enumerated() {
            if workout.exercises.isEmpty {
                saveError = "Workout \(index + 1) has no exercises"
                return false
            }

            for (exIndex, exercise) in workout.exercises.enumerated() {
                if exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    saveError = "Workout \(index + 1), Exercise \(exIndex + 1) needs a name"
                    return false
                }

                if exercise.sets <= 0 {
                    saveError = "Workout \(index + 1), Exercise \(exIndex + 1) must have at least 1 set"
                    return false
                }

                if exercise.reps <= 0 {
                    saveError = "Workout \(index + 1), Exercise \(exIndex + 1) must have at least 1 rep"
                    return false
                }

                if exercise.weight < 0 {
                    saveError = "Workout \(index + 1), Exercise \(exIndex + 1) cannot have negative weight"
                    return false
                }

                if exercise.rpe < 0 || exercise.rpe > 10 {
                    saveError = "Workout \(index + 1), Exercise \(exIndex + 1) RPE must be between 0-10"
                    return false
                }
            }
        }

        saveError = ""
        return true
    }

    // MARK: - Save All Workouts

    func saveAllWorkouts() -> Bool {
        guard validateWorkouts() else {
            print("❌ Batch workout validation failed: \(saveError)")
            return false
        }

        // Apply shared date to all workouts before saving
        applySharedDateToAll()

        isSaving = true
        saveSuccessCount = 0
        saveFailureCount = 0

        // Save each workout
        for workout in workouts {
            print("🔍 DIAGNOSTIC: Saving workout - ID: \(workout.id), Name: \(workout.name ?? "Unnamed"), isTemplate: \(workout.isTemplate)")

            let success = repository.saveWorkout(workout)

            if success {
                saveSuccessCount += 1
                print("✅ Workout '\(workout.name ?? "Unnamed")' saved successfully")
            } else {
                saveFailureCount += 1
                print("❌ Failed to save workout '\(workout.name ?? "Unnamed")'")
            }
        }

        isSaving = false

        // Return true if at least one workout was saved successfully
        let overallSuccess = saveSuccessCount > 0

        if overallSuccess {
            if saveFailureCount > 0 {
                saveError = "Saved \(saveSuccessCount) workout(s), but \(saveFailureCount) failed"
            }
            print("✅ Batch save completed: \(saveSuccessCount) succeeded, \(saveFailureCount) failed")
        } else {
            saveError = "Failed to save all workouts"
            print("❌ Batch save failed: all workouts failed to save")
        }

        return overallSuccess
    }
}
