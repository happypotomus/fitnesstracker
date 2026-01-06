//
//  TemplateEditViewModel.swift
//  FitnessTracker
//
//  ViewModel for editing existing templates
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TemplateEditViewModel: ObservableObject {
    @Published var exercises: [WorkoutExercise]
    @Published var templateName: String
    @Published var isSaving: Bool = false
    @Published var saveError: String = ""

    private let originalTemplateId: UUID
    private let repository = WorkoutRepository()

    init(template: WorkoutSession) {
        self.originalTemplateId = template.id
        self.exercises = template.exercises
        self.templateName = template.name ?? ""
    }

    // MARK: - Exercise Management

    func updateExercise(at index: Int, with updatedExercise: WorkoutExercise) {
        guard index < exercises.count else { return }
        exercises[index] = updatedExercise
    }

    func addExercise() {
        let newExercise = WorkoutExercise(
            name: "New Exercise",
            sets: 3,
            reps: 10,
            weight: 0,
            rpe: 0,
            notes: nil,
            order: exercises.count
        )
        exercises.append(newExercise)
    }

    func deleteExercise(at index: Int) {
        guard index < exercises.count else { return }
        exercises.remove(at: index)

        // Reorder remaining exercises
        for i in 0..<exercises.count {
            exercises[i].order = i
        }
    }

    // MARK: - Validation

    func validateTemplate() -> Bool {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            saveError = "Template name cannot be empty"
            return false
        }

        guard !exercises.isEmpty else {
            saveError = "Please add at least one exercise"
            return false
        }

        // Validate each exercise
        for (index, exercise) in exercises.enumerated() {
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

    // MARK: - Save Template

    func saveTemplate() -> Bool {
        guard validateTemplate() else {
            print("❌ Template validation failed: \(saveError)")
            return false
        }

        isSaving = true

        let success = repository.updateTemplate(
            id: originalTemplateId,
            name: templateName.trimmingCharacters(in: .whitespacesAndNewlines),
            exercises: exercises
        )

        if success {
            print("✅ Template updated successfully: \(templateName)")
        } else {
            saveError = "Failed to save template"
            print("❌ Failed to save template")
        }

        isSaving = false
        return success
    }
}
