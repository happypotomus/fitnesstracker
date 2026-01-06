//
//  MealModel.swift
//  FitnessTracker
//
//  Swift model structs for Meal data
//

import Foundation

/// Represents a single food item within a meal
struct MealFood: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var portionSize: String?
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var notes: String?
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        portionSize: String? = nil,
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.portionSize = portionSize
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.notes = notes
        self.order = order
    }
}

/// Represents a complete meal session or template
struct MealSession: Identifiable, Equatable {
    var id: UUID
    var date: Date
    var foodItems: [MealFood]
    var mealType: String?  // breakfast, lunch, dinner, snack
    var name: String?  // If name is set, this is a template

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        foodItems: [MealFood] = [],
        mealType: String? = nil,
        name: String? = nil
    ) {
        self.id = id
        self.date = date
        self.foodItems = foodItems
        self.mealType = mealType
        self.name = name
    }

    /// Returns true if this is a template (has a name)
    var isTemplate: Bool {
        return name != nil
    }

    /// Total calories across all food items
    var totalCalories: Double {
        return foodItems.reduce(0.0) { $0 + ($1.calories ?? 0.0) }
    }

    /// Total protein across all food items
    var totalProtein: Double {
        return foodItems.reduce(0.0) { $0 + ($1.protein ?? 0.0) }
    }

    /// Total carbs across all food items
    var totalCarbs: Double {
        return foodItems.reduce(0.0) { $0 + ($1.carbs ?? 0.0) }
    }

    /// Total fat across all food items
    var totalFat: Double {
        return foodItems.reduce(0.0) { $0 + ($1.fat ?? 0.0) }
    }
}

// MARK: - Sample Data for Previews and Testing

extension MealSession {
    static let sampleEggs = MealFood(
        name: "Scrambled Eggs",
        portionSize: "2 eggs",
        calories: 140,
        protein: 12,
        carbs: 2,
        fat: 10,
        notes: "Cooked with butter"
    )

    static let sampleToast = MealFood(
        name: "Whole Wheat Toast",
        portionSize: "2 slices",
        calories: 160,
        protein: 8,
        carbs: 28,
        fat: 2,
        notes: "With butter",
        order: 1
    )

    static let sampleCoffee = MealFood(
        name: "Coffee",
        portionSize: "1 cup",
        calories: 5,
        protein: 0,
        carbs: 1,
        fat: 0,
        order: 2
    )

    static let sampleMeal = MealSession(
        date: Date(),
        foodItems: [sampleEggs, sampleToast, sampleCoffee],
        mealType: "breakfast",
        name: nil
    )

    static let sampleTemplate = MealSession(
        date: Date(),
        foodItems: [sampleEggs, sampleToast, sampleCoffee],
        mealType: "breakfast",
        name: "My Usual Breakfast"
    )
}
