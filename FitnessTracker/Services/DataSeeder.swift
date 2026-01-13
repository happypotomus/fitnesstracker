//
//  DataSeeder.swift
//  FitnessTracker
//
//  One-time script to backfill workout data
//

import Foundation

class DataSeeder {
    private let repository = WorkoutRepository()

    /// Call this once to insert all backfill workouts
    func seedJanuaryWorkouts() {
        print("🌱 Starting workout data seeding...")

        // January 1, 8:00 AM
        let jan1 = createDate(month: 1, day: 1, hour: 8, minute: 0)
        let workout1 = WorkoutSession(
            date: jan1,
            exercises: [
                WorkoutExercise(
                    name: "Bench Press",
                    sets: 3,
                    reps: 8,
                    weight: 105.0,
                    rpe: 0,
                    order: 0
                ),
                WorkoutExercise(
                    name: "Shoulder Press (Dumbbell)",
                    sets: 3,
                    reps: 10,
                    weight: 35.0,
                    rpe: 0,
                    order: 1
                ),
                WorkoutExercise(
                    name: "Chest Fly (Machine)",
                    sets: 3,
                    reps: 10,
                    weight: 75.0,
                    rpe: 0,
                    order: 2
                ),
                WorkoutExercise(
                    name: "Cable Pushdowns",
                    sets: 3,
                    reps: 10,
                    weight: 65.0,
                    rpe: 0,
                    order: 3
                )
            ],
            name: "Chest & Triceps",
            isTemplate: false
        )

        // January 2, 8:00 AM
        let jan2 = createDate(month: 1, day: 2, hour: 8, minute: 0)
        let workout2 = WorkoutSession(
            date: jan2,
            exercises: [
                WorkoutExercise(
                    name: "Lat Pulldown",
                    sets: 3,
                    reps: 10,
                    weight: 100.0,
                    rpe: 0,
                    order: 0
                ),
                WorkoutExercise(
                    name: "Machine Dumbbell Row",
                    sets: 3,
                    reps: 10, // Default since not specified
                    weight: 70.0,
                    rpe: 0,
                    order: 1
                ),
                WorkoutExercise(
                    name: "Machine Row",
                    sets: 3,
                    reps: 10,
                    weight: 100.0,
                    rpe: 0,
                    order: 2
                )
            ],
            name: "Back Day",
            isTemplate: false
        )

        // January 3, 8:00 AM
        let jan3 = createDate(month: 1, day: 3, hour: 8, minute: 0)
        let workout3 = WorkoutSession(
            date: jan3,
            exercises: [
                WorkoutExercise(
                    name: "Stretching",
                    sets: 1,
                    reps: 1,
                    weight: 0.0,
                    rpe: 0,
                    notes: "Light stretching session",
                    order: 0
                ),
                WorkoutExercise(
                    name: "Sauna",
                    sets: 1,
                    reps: 1,
                    weight: 0.0,
                    rpe: 0,
                    notes: "Recovery session",
                    order: 1
                )
            ],
            name: "Recovery Session",
            isTemplate: false
        )

        // January 4, 8:00 AM
        let jan4 = createDate(month: 1, day: 4, hour: 8, minute: 0)
        let workout4 = WorkoutSession(
            date: jan4,
            exercises: [
                WorkoutExercise(
                    name: "Run",
                    sets: 1,
                    reps: 15, // 15 minutes
                    weight: 0.0,
                    rpe: 0,
                    notes: "15 minute run",
                    order: 0
                )
            ],
            name: "Cardio",
            isTemplate: false
        )

        // Save all workouts
        let workouts = [workout1, workout2, workout3, workout4]
        var successCount = 0

        for (index, workout) in workouts.enumerated() {
            if repository.saveWorkout(workout) {
                successCount += 1
                print("✅ Saved workout \(index + 1) for \(formatDate(workout.date))")
            } else {
                print("❌ Failed to save workout \(index + 1) for \(formatDate(workout.date))")
            }
        }

        print("🎉 Seeding complete! \(successCount)/\(workouts.count) workouts saved.")
    }

    /// One-time method to add names to existing workouts that don't have them
    func addNamesToExistingWorkouts() {
        print("🏷️ Starting to name existing workouts...")

        let workouts = repository.fetchAllWorkouts()
        var updateCount = 0

        for workout in workouts {
            // Skip if already has a name
            if workout.name != nil && !workout.name!.isEmpty {
                continue
            }

            // Generate a name based on exercises
            let generatedName = generateWorkoutName(from: workout.exercises)

            // Delete old workout and save with new name
            if repository.deleteWorkout(id: workout.id) {
                let updatedWorkout = WorkoutSession(
                    id: workout.id,
                    date: workout.date,
                    exercises: workout.exercises,
                    name: generatedName,
                    isTemplate: false
                )

                if repository.saveWorkout(updatedWorkout) {
                    updateCount += 1
                    print("✅ Named workout from \(formatDate(workout.date)): \"\(generatedName)\"")
                } else {
                    print("❌ Failed to save updated workout")
                }
            }
        }

        print("🎉 Naming complete! \(updateCount) workouts updated.")
    }

    /// Generates a descriptive workout name based on exercises
    private func generateWorkoutName(from exercises: [WorkoutExercise]) -> String {
        let exerciseNames = exercises.map { $0.name.lowercased() }

        // Check for common patterns
        let hasChest = exerciseNames.contains { $0.contains("bench") || $0.contains("chest") || $0.contains("fly") }
        let hasTriceps = exerciseNames.contains { $0.contains("tricep") || $0.contains("pushdown") || $0.contains("dip") }
        let hasBack = exerciseNames.contains { $0.contains("row") || $0.contains("pulldown") || $0.contains("pull") }
        let hasBiceps = exerciseNames.contains { $0.contains("curl") || $0.contains("bicep") }
        let hasShoulders = exerciseNames.contains { $0.contains("shoulder") || $0.contains("press") && !$0.contains("bench") }
        let hasLegs = exerciseNames.contains { $0.contains("squat") || $0.contains("leg") || $0.contains("lunge") }
        let hasCardio = exerciseNames.contains { $0.contains("run") || $0.contains("bike") || $0.contains("treadmill") }
        let hasRecovery = exerciseNames.contains { $0.contains("stretch") || $0.contains("sauna") || $0.contains("foam") }

        // Generate name based on muscle groups
        if hasRecovery {
            return "Recovery Session"
        } else if hasCardio && exercises.count <= 2 {
            return "Cardio"
        } else if hasChest && hasTriceps {
            return "Chest & Triceps"
        } else if hasBack && hasBiceps {
            return "Back & Biceps"
        } else if hasChest {
            return "Chest Day"
        } else if hasBack {
            return "Back Day"
        } else if hasLegs {
            return "Leg Day"
        } else if hasShoulders {
            return "Shoulder Day"
        } else if exercises.count >= 5 {
            return "Full Body"
        } else {
            return "Upper Body"
        }
    }

    // MARK: - Helper Methods

    private func createDate(month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone.current

        return Calendar.current.date(from: components) ?? Date()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
