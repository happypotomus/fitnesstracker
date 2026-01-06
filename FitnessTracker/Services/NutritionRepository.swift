//
//  NutritionRepository.swift
//  FitnessTracker
//
//  Data access layer for Meal operations
//

import Foundation
import CoreData

class NutritionRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Save Meal

    /// Saves a meal session to CoreData
    func saveMeal(_ meal: MealSession) -> Bool {
        let context = persistenceController.container.viewContext

        let mealEntity = Meal(context: context)
        mealEntity.id = meal.id
        mealEntity.date = meal.date
        mealEntity.name = meal.name
        mealEntity.mealType = meal.mealType

        // Create food item entities
        for foodItem in meal.foodItems {
            let foodItemEntity = FoodItem(context: context)
            foodItemEntity.id = foodItem.id
            foodItemEntity.name = foodItem.name
            foodItemEntity.portionSize = foodItem.portionSize
            foodItemEntity.calories = foodItem.calories ?? 0
            foodItemEntity.protein = foodItem.protein ?? 0
            foodItemEntity.carbs = foodItem.carbs ?? 0
            foodItemEntity.fat = foodItem.fat ?? 0
            foodItemEntity.notes = foodItem.notes
            foodItemEntity.order = Int16(foodItem.order)
            foodItemEntity.meal = mealEntity
        }

        do {
            try context.save()
            print("✅ Meal saved successfully: \(meal.foodItems.count) food items")
            return true
        } catch {
            print("❌ Failed to save meal: \(error)")
            return false
        }
    }

    // MARK: - Fetch Meals

    /// Fetches all meals (excluding templates)
    func fetchAllMeals() -> [MealSession] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()

        // Only fetch non-templates (name is nil)
        request.predicate = NSPredicate(format: "name == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: false)]

        do {
            let meals = try context.fetch(request)
            return meals.map { convertToMealSession($0) }
        } catch {
            print("❌ Failed to fetch meals: \(error)")
            return []
        }
    }

    /// Fetches meals within a date range
    func fetchMeals(from startDate: Date, to endDate: Date) -> [MealSession] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()

        // Only fetch non-templates within date range
        request.predicate = NSPredicate(
            format: "name == nil AND date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: false)]

        do {
            let meals = try context.fetch(request)
            return meals.map { convertToMealSession($0) }
        } catch {
            print("❌ Failed to fetch meals in date range: \(error)")
            return []
        }
    }

    // MARK: - Delete Meal

    /// Deletes a meal by ID
    func deleteMeal(id: UUID) -> Bool {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let meals = try context.fetch(request)
            guard let meal = meals.first else {
                print("⚠️ Meal not found for deletion: \(id)")
                return false
            }

            context.delete(meal)
            try context.save()
            print("✅ Meal deleted successfully")
            return true
        } catch {
            print("❌ Failed to delete meal: \(error)")
            return false
        }
    }

    // MARK: - Templates

    /// Saves a meal as a named template
    func saveTemplate(name: String, foodItems: [MealFood], mealType: String?) -> Bool {
        let template = MealSession(
            date: Date(),
            foodItems: foodItems,
            mealType: mealType,
            name: name
        )
        return saveMeal(template)
    }

    /// Fetches all saved templates
    func fetchTemplates() -> [MealSession] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()

        // Only fetch templates (name is not nil)
        request.predicate = NSPredicate(format: "name != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.name, ascending: true)]

        do {
            let meals = try context.fetch(request)
            return meals.map { convertToMealSession($0) }
        } catch {
            print("❌ Failed to fetch templates: \(error)")
            return []
        }
    }

    /// Updates an existing template
    func updateTemplate(id: UUID, name: String, foodItems: [MealFood], mealType: String?) -> Bool {
        // Delete old template
        guard deleteMeal(id: id) else { return false }

        // Save new version with same ID
        let template = MealSession(
            id: id,
            date: Date(),
            foodItems: foodItems,
            mealType: mealType,
            name: name
        )
        return saveMeal(template)
    }

    // MARK: - Helper Methods

    /// Converts a CoreData Meal entity to a MealSession struct
    private func convertToMealSession(_ meal: Meal) -> MealSession {
        let foodItems = meal.foodItemsArray.map { foodItem in
            MealFood(
                id: foodItem.id ?? UUID(),
                name: foodItem.name ?? "Unknown",
                portionSize: foodItem.portionSize,
                calories: foodItem.calories == 0 ? nil : foodItem.calories,
                protein: foodItem.protein == 0 ? nil : foodItem.protein,
                carbs: foodItem.carbs == 0 ? nil : foodItem.carbs,
                fat: foodItem.fat == 0 ? nil : foodItem.fat,
                notes: foodItem.notes,
                order: Int(foodItem.order)
            )
        }

        return MealSession(
            id: meal.id ?? UUID(),
            date: meal.date ?? Date(),
            foodItems: foodItems,
            mealType: meal.mealType,
            name: meal.name
        )
    }
}
