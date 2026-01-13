//
//  WorkoutConfirmationViewModel.swift
//  FitnessTracker
//
//  ViewModel for confirming and editing workout before saving
//

import Foundation
import SwiftUI
import Combine

@MainActor
class WorkoutConfirmationViewModel: ObservableObject {
    @Published var workout: WorkoutSession
    @Published var isSaving: Bool = false
    @Published var saveError: String = ""

    private let repository = WorkoutRepository()

    init(workout: WorkoutSession) {
        self.workout = workout
    }

    // MARK: - Update Exercise

    func updateExercise(at index: Int, with updatedExercise: WorkoutExercise) {
        guard index < workout.exercises.count else { return }
        workout.exercises[index] = updatedExercise
    }

    // MARK: - Add Exercise

    func addExercise() {
        let newExercise = WorkoutExercise(
            name: "New Exercise",
            sets: 3,
            reps: 10,
            weight: 0,
            rpe: 0,
            notes: nil,
            order: workout.exercises.count
        )
        workout.exercises.append(newExercise)
    }

    // MARK: - Delete Exercise

    func deleteExercise(at index: Int) {
        guard index < workout.exercises.count else { return }
        workout.exercises.remove(at: index)

        // Reorder remaining exercises
        for i in 0..<workout.exercises.count {
            workout.exercises[i].order = i
        }
    }

    // MARK: - Validation

    func validateWorkout() -> Bool {
        // Check that we have at least one exercise
        guard !workout.exercises.isEmpty else {
            saveError = "Please add at least one exercise"
            return false
        }

        // Validate each exercise
        for (index, exercise) in workout.exercises.enumerated() {
            if exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                saveError = "Exercise \(index + 1) needs a name"
                return false
            }

            if exercise.sets <= 0 {
                saveError = "Exercise \(index + 1) must have at least 1 set"
                return false
            }

            if exercise.reps <= 0 {
                saveError = "Exercise \(index + 1) must have at least 1 rep"
                return false
            }

            if exercise.weight < 0 {
                saveError = "Exercise \(index + 1) cannot have negative weight"
                return false
            }

            if exercise.rpe < 0 || exercise.rpe > 10 {
                saveError = "Exercise \(index + 1) RPE must be between 0-10"
                return false
            }
        }

        saveError = ""
        return true
    }

    // MARK: - Save Workout

    func saveWorkout() -> Bool {
        guard validateWorkout() else {
            print("❌ Workout validation failed: \(saveError)")
            return false
        }

        print("🔍 DIAGNOSTIC: Saving workout - ID: \(workout.id), isTemplate: \(workout.isTemplate)")

        isSaving = true

        let success = repository.saveWorkout(workout)

        if success {
            print("✅ Workout saved successfully")
        } else {
            saveError = "Failed to save workout"
            print("❌ Failed to save workout")
        }

        isSaving = false
        return success
    }

    // MARK: - Save as Template

    func saveAsTemplate(name: String) -> Bool {
        print("🔍 DIAGNOSTIC: saveAsTemplate called with name: '\(name)'")

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            saveError = "Template name cannot be empty"
            print("❌ Template name is empty")
            return false
        }

        print("🔍 DIAGNOSTIC: Saving template '\(trimmedName)' with \(workout.exercises.count) exercises")
        let success = repository.saveTemplate(name: trimmedName, exercises: workout.exercises)

        if success {
            print("✅ Template '\(trimmedName)' saved successfully")
        } else {
            saveError = "Failed to save template"
            print("❌ Failed to save template")
        }

        return success
    }
}
