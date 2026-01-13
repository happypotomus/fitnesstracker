//
//  BulkMealConfirmationViewModel.swift
//  FitnessTracker
//
//  ViewModel for confirming and editing multiple meals before saving
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BulkMealConfirmationViewModel: ObservableObject {
    @Published var meals: [MealSession]
    @Published var isSaving: Bool = false
    @Published var saveError: String = ""

    private let repository = NutritionRepository()

    init(meals: [MealSession]) {
        self.meals = meals
    }

    // MARK: - Update Meal

    func updateMeal(at index: Int, with updatedMeal: MealSession) {
        guard index < meals.count else { return }
        meals[index] = updatedMeal
    }

    // MARK: - Delete Meal

    func deleteMeal(at index: Int) {
        guard index < meals.count else { return }
        meals.remove(at: index)
    }

    // MARK: - Update Food Item in Specific Meal

    func updateFoodItem(mealIndex: Int, foodIndex: Int, with updatedFoodItem: MealFood) {
        guard mealIndex < meals.count, foodIndex < meals[mealIndex].foodItems.count else { return }
        meals[mealIndex].foodItems[foodIndex] = updatedFoodItem
    }

    // MARK: - Add Food Item to Specific Meal

    func addFoodItem(to mealIndex: Int) {
        guard mealIndex < meals.count else { return }
        let newFoodItem = MealFood(
            name: "New Food Item",
            portionSize: "1 serving",
            calories: nil,
            protein: nil,
            carbs: nil,
            fat: nil,
            notes: nil,
            order: meals[mealIndex].foodItems.count
        )
        meals[mealIndex].foodItems.append(newFoodItem)
    }

    // MARK: - Delete Food Item from Specific Meal

    func deleteFoodItem(mealIndex: Int, foodIndex: Int) {
        guard mealIndex < meals.count, foodIndex < meals[mealIndex].foodItems.count else { return }
        meals[mealIndex].foodItems.remove(at: foodIndex)

        // Reorder remaining food items
        for i in 0..<meals[mealIndex].foodItems.count {
            meals[mealIndex].foodItems[i].order = i
        }
    }

    // MARK: - Validation

    func validateMeals() -> Bool {
        // Check that we have at least one meal
        guard !meals.isEmpty else {
            saveError = "No meals to save"
            return false
        }

        // Validate each meal
        for (mealIndex, meal) in meals.enumerated() {
            // Check that we have at least one food item
            guard !meal.foodItems.isEmpty else {
                saveError = "Meal \(mealIndex + 1) needs at least one food item"
                return false
            }

            // Validate each food item
            for (foodIndex, foodItem) in meal.foodItems.enumerated() {
                if foodItem.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    saveError = "Meal \(mealIndex + 1), Food item \(foodIndex + 1) needs a name"
                    return false
                }
            }
        }

        saveError = ""
        return true
    }

    // MARK: - Save All Meals

    func saveAllMeals() -> Bool {
        guard validateMeals() else {
            print("❌ Meals validation failed: \(saveError)")
            return false
        }

        isSaving = true

        var allSuccess = true
        for (index, meal) in meals.enumerated() {
            let success = repository.saveMeal(meal)
            if success {
                print("✅ Meal \(index + 1) saved successfully")
            } else {
                saveError = "Failed to save meal \(index + 1)"
                print("❌ Failed to save meal \(index + 1)")
                allSuccess = false
                break
            }
        }

        isSaving = false
        return allSuccess
    }
}
