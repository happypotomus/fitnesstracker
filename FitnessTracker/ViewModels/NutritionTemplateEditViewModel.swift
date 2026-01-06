//
//  NutritionTemplateEditViewModel.swift
//  FitnessTracker
//
//  ViewModel for editing existing meal templates
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NutritionTemplateEditViewModel: ObservableObject {
    @Published var foodItems: [MealFood]
    @Published var templateName: String
    @Published var mealType: String?
    @Published var isSaving: Bool = false
    @Published var saveError: String = ""

    private let originalTemplateId: UUID
    private let repository = NutritionRepository()

    init(template: MealSession) {
        self.originalTemplateId = template.id
        self.foodItems = template.foodItems
        self.templateName = template.name ?? ""
        self.mealType = template.mealType
    }

    // MARK: - Food Item Management

    func updateFoodItem(at index: Int, with updatedFoodItem: MealFood) {
        guard index < foodItems.count else { return }
        foodItems[index] = updatedFoodItem
    }

    func addFoodItem() {
        let newFoodItem = MealFood(
            name: "New Food Item",
            portionSize: "1 serving",
            calories: nil,
            protein: nil,
            carbs: nil,
            fat: nil,
            notes: nil,
            order: foodItems.count
        )
        foodItems.append(newFoodItem)
    }

    func deleteFoodItem(at index: Int) {
        guard index < foodItems.count else { return }
        foodItems.remove(at: index)

        // Reorder remaining food items
        for i in 0..<foodItems.count {
            foodItems[i].order = i
        }
    }

    // MARK: - Validation

    func validateTemplate() -> Bool {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            saveError = "Template name cannot be empty"
            return false
        }

        guard !foodItems.isEmpty else {
            saveError = "Please add at least one food item"
            return false
        }

        // Validate each food item
        for (index, foodItem) in foodItems.enumerated() {
            if foodItem.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                saveError = "Food item \(index + 1) needs a name"
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
            foodItems: foodItems,
            mealType: mealType
        )

        if success {
            print("✅ Meal template updated successfully: \(templateName)")
        } else {
            saveError = "Failed to save template"
            print("❌ Failed to save meal template")
        }

        isSaving = false
        return success
    }

    // MARK: - Delete Template

    func deleteTemplate() -> Bool {
        let success = repository.deleteMeal(id: originalTemplateId)

        if success {
            print("✅ Meal template deleted successfully")
        } else {
            print("❌ Failed to delete meal template")
        }

        return success
    }
}
