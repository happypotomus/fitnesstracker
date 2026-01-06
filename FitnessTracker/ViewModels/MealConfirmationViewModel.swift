//
//  MealConfirmationViewModel.swift
//  FitnessTracker
//
//  ViewModel for confirming and editing meal before saving
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MealConfirmationViewModel: ObservableObject {
    @Published var meal: MealSession
    @Published var isSaving: Bool = false
    @Published var saveError: String = ""

    private let repository = NutritionRepository()

    init(meal: MealSession) {
        self.meal = meal
    }

    // MARK: - Update Food Item

    func updateFoodItem(at index: Int, with updatedFoodItem: MealFood) {
        guard index < meal.foodItems.count else { return }
        meal.foodItems[index] = updatedFoodItem
    }

    // MARK: - Add Food Item

    func addFoodItem() {
        let newFoodItem = MealFood(
            name: "New Food Item",
            portionSize: "1 serving",
            calories: nil,
            protein: nil,
            carbs: nil,
            fat: nil,
            notes: nil,
            order: meal.foodItems.count
        )
        meal.foodItems.append(newFoodItem)
    }

    // MARK: - Delete Food Item

    func deleteFoodItem(at index: Int) {
        guard index < meal.foodItems.count else { return }
        meal.foodItems.remove(at: index)

        // Reorder remaining food items
        for i in 0..<meal.foodItems.count {
            meal.foodItems[i].order = i
        }
    }

    // MARK: - Validation

    func validateMeal() -> Bool {
        // Check that we have at least one food item
        guard !meal.foodItems.isEmpty else {
            saveError = "Please add at least one food item"
            return false
        }

        // Validate each food item
        for (index, foodItem) in meal.foodItems.enumerated() {
            if foodItem.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                saveError = "Food item \(index + 1) needs a name"
                return false
            }
        }

        saveError = ""
        return true
    }

    // MARK: - Save Meal

    func saveMeal() -> Bool {
        guard validateMeal() else {
            print("❌ Meal validation failed: \(saveError)")
            return false
        }

        isSaving = true

        let success = repository.saveMeal(meal)

        if success {
            print("✅ Meal saved successfully")
        } else {
            saveError = "Failed to save meal"
            print("❌ Failed to save meal")
        }

        isSaving = false
        return success
    }

    // MARK: - Save as Template

    func saveAsTemplate(name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            saveError = "Template name cannot be empty"
            return false
        }

        let success = repository.saveTemplate(
            name: name,
            foodItems: meal.foodItems,
            mealType: meal.mealType
        )

        if success {
            print("✅ Meal template '\(name)' saved successfully")
        } else {
            saveError = "Failed to save meal template"
            print("❌ Failed to save meal template")
        }

        return success
    }
}
