//
//  BackupService.swift
//  FitnessTracker
//
//  Handles data export and import for backup/restore functionality
//

import Foundation
import CoreData

struct BackupData: Codable {
    let workouts: [WorkoutSession]
    let nutritionData: [MealSession]
    let exportDate: Date
    let version: String

    init(workouts: [WorkoutSession], nutritionData: [MealSession]) {
        self.workouts = workouts
        self.nutritionData = nutritionData
        self.exportDate = Date()
        self.version = "1.0"
    }
}

class BackupService {
    private let workoutRepository = WorkoutRepository()
    private let nutritionRepository = NutritionRepository()

    // MARK: - Export

    /// Exports all data (workouts, templates, meals) to JSON
    func exportAllData() -> URL? {
        // Fetch all workouts (including templates)
        let allWorkouts = fetchAllWorkoutsIncludingTemplates()

        // Fetch all meals (including templates)
        let allMeals = fetchAllMealsIncludingTemplates()

        // Create backup data structure
        let backup = BackupData(workouts: allWorkouts, nutritionData: allMeals)

        // Convert to JSON
        guard let jsonData = try? JSONEncoder().encode(backup) else {
            print("❌ Failed to encode backup data to JSON")
            return nil
        }

        // Create temporary file
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "FitnessTracker_Backup_\(timestamp).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: tempURL)
            print("✅ Backup exported successfully to: \(tempURL.path)")
            print("📊 Exported \(allWorkouts.count) workouts and \(allMeals.count) meals")
            return tempURL
        } catch {
            print("❌ Failed to write backup file: \(error)")
            return nil
        }
    }

    // MARK: - Import

    /// Imports data from a backup JSON file
    func importData(from url: URL) -> (success: Bool, workoutCount: Int, mealCount: Int) {
        do {
            // Read JSON file
            let jsonData = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(BackupData.self, from: jsonData)

            print("📥 Importing backup from \(backup.exportDate)")
            print("   Version: \(backup.version)")
            print("   Workouts: \(backup.workouts.count)")
            print("   Meals: \(backup.nutritionData.count)")

            // Import workouts
            var workoutSuccessCount = 0
            for workout in backup.workouts {
                if workoutRepository.saveWorkout(workout) {
                    workoutSuccessCount += 1
                }
            }

            // Import meals
            var mealSuccessCount = 0
            for meal in backup.nutritionData {
                if nutritionRepository.saveMeal(meal) {
                    mealSuccessCount += 1
                }
            }

            print("✅ Import complete!")
            print("   Workouts imported: \(workoutSuccessCount)/\(backup.workouts.count)")
            print("   Meals imported: \(mealSuccessCount)/\(backup.nutritionData.count)")

            return (true, workoutSuccessCount, mealSuccessCount)

        } catch {
            print("❌ Failed to import backup: \(error)")
            return (false, 0, 0)
        }
    }

    // MARK: - Helper Methods

    /// Fetches all workouts including templates (bypasses repository filter)
    private func fetchAllWorkoutsIncludingTemplates() -> [WorkoutSession] {
        let context = PersistenceController.shared.container.viewContext
        let request = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]

        do {
            let workouts = try context.fetch(request)
            return workouts.map { workout in
                let exercises = workout.exercisesArray.map { exercise in
                    WorkoutExercise(
                        id: exercise.id ?? UUID(),
                        name: exercise.name ?? "Unknown",
                        sets: Int(exercise.sets),
                        reps: Int(exercise.reps),
                        weight: exercise.weight,
                        rpe: Int(exercise.rpe),
                        notes: exercise.notes,
                        order: Int(exercise.order)
                    )
                }

                return WorkoutSession(
                    id: workout.id ?? UUID(),
                    date: workout.date ?? Date(),
                    exercises: exercises,
                    name: workout.name,
                    isTemplate: workout.isTemplate
                )
            }
        } catch {
            print("❌ Failed to fetch workouts for backup: \(error)")
            return []
        }
    }

    /// Fetches all meals including templates (bypasses repository filter)
    private func fetchAllMealsIncludingTemplates() -> [MealSession] {
        let context = PersistenceController.shared.container.viewContext
        let request = Meal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: false)]

        do {
            let meals = try context.fetch(request)
            return meals.map { meal in
                let foodItems = meal.foodItemsArray.map { food in
                    MealFood(
                        id: food.id ?? UUID(),
                        name: food.name ?? "Unknown",
                        portionSize: food.portionSize,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        notes: food.notes,
                        order: Int(food.order)
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
        } catch {
            print("❌ Failed to fetch meals for backup: \(error)")
            return []
        }
    }
}
