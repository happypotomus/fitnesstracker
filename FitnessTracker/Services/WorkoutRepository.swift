//
//  WorkoutRepository.swift
//  FitnessTracker
//
//  Data access layer for Workout operations
//

import Foundation
import CoreData

class WorkoutRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Save Workout

    /// Saves a workout session to CoreData (creates new or updates existing)
    func saveWorkout(_ workout: WorkoutSession) -> Bool {
        let context = persistenceController.container.viewContext

        // Check if workout already exists
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workout.id as CVarArg)

        do {
            let existingWorkouts = try context.fetch(request)

            if let existingWorkout = existingWorkouts.first {
                // Update existing workout
                print("🔄 Updating existing workout: \(workout.id)")
                return updateExistingWorkout(existingWorkout, with: workout, in: context)
            } else {
                // Create new workout
                print("➕ Creating new workout: \(workout.id)")
                return createNewWorkout(workout, in: context)
            }
        } catch {
            print("❌ Failed to check for existing workout: \(error)")
            return false
        }
    }

    // MARK: - Update Workout

    /// Updates an existing workout in CoreData
    func updateWorkout(_ workout: WorkoutSession) -> Bool {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workout.id as CVarArg)

        do {
            let workouts = try context.fetch(request)
            guard let existingWorkout = workouts.first else {
                print("⚠️ Workout not found for update: \(workout.id)")
                return false
            }

            return updateExistingWorkout(existingWorkout, with: workout, in: context)
        } catch {
            print("❌ Failed to update workout: \(error)")
            return false
        }
    }

    // MARK: - Helper: Update Existing Workout

    private func updateExistingWorkout(_ entity: Workout, with workout: WorkoutSession, in context: NSManagedObjectContext) -> Bool {
        // Update workout properties
        entity.date = workout.date
        entity.name = workout.name
        entity.isTemplate = workout.isTemplate

        // Delete all existing exercises
        if let existingExercises = entity.exercises as? Set<Exercise> {
            for exercise in existingExercises {
                context.delete(exercise)
            }
        }

        // Create new exercise entities
        for exercise in workout.exercises {
            let exerciseEntity = Exercise(context: context)
            exerciseEntity.id = exercise.id
            exerciseEntity.name = exercise.name
            exerciseEntity.sets = Int16(exercise.sets)
            exerciseEntity.reps = Int16(exercise.reps)
            exerciseEntity.weight = exercise.weight
            exerciseEntity.rpe = Int16(exercise.rpe)
            exerciseEntity.notes = exercise.notes
            exerciseEntity.order = Int16(exercise.order)
            exerciseEntity.workout = entity
        }

        do {
            try context.save()
            print("✅ Workout updated successfully: \(workout.exercises.count) exercises")
            return true
        } catch {
            print("❌ Failed to save updated workout: \(error)")
            return false
        }
    }

    // MARK: - Helper: Create New Workout

    private func createNewWorkout(_ workout: WorkoutSession, in context: NSManagedObjectContext) -> Bool {
        let workoutEntity = Workout(context: context)
        workoutEntity.id = workout.id
        workoutEntity.date = workout.date
        workoutEntity.name = workout.name
        workoutEntity.isTemplate = workout.isTemplate

        // Create exercise entities
        for exercise in workout.exercises {
            let exerciseEntity = Exercise(context: context)
            exerciseEntity.id = exercise.id
            exerciseEntity.name = exercise.name
            exerciseEntity.sets = Int16(exercise.sets)
            exerciseEntity.reps = Int16(exercise.reps)
            exerciseEntity.weight = exercise.weight
            exerciseEntity.rpe = Int16(exercise.rpe)
            exerciseEntity.notes = exercise.notes
            exerciseEntity.order = Int16(exercise.order)
            exerciseEntity.workout = workoutEntity
        }

        do {
            try context.save()
            print("✅ Workout created successfully: \(workout.exercises.count) exercises")
            return true
        } catch {
            print("❌ Failed to create workout: \(error)")
            return false
        }
    }

    // MARK: - Fetch Workouts

    /// Fetches all workouts (excluding templates)
    func fetchAllWorkouts() -> [WorkoutSession] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()

        // Only fetch non-templates
        request.predicate = NSPredicate(format: "isTemplate == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]

        do {
            let workouts = try context.fetch(request)
            return workouts.map { convertToWorkoutSession($0) }
        } catch {
            print("❌ Failed to fetch workouts: \(error)")
            return []
        }
    }

    /// Fetches workouts within a date range
    func fetchWorkouts(from startDate: Date, to endDate: Date) -> [WorkoutSession] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()

        // Only fetch non-templates within date range
        request.predicate = NSPredicate(
            format: "isTemplate == NO AND date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]

        do {
            let workouts = try context.fetch(request)
            return workouts.map { convertToWorkoutSession($0) }
        } catch {
            print("❌ Failed to fetch workouts in date range: \(error)")
            return []
        }
    }

    // MARK: - Delete Workout

    /// Deletes a workout by ID
    func deleteWorkout(id: UUID) -> Bool {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let workouts = try context.fetch(request)
            guard let workout = workouts.first else {
                print("⚠️ Workout not found for deletion: \(id)")
                return false
            }

            context.delete(workout)
            try context.save()
            print("✅ Workout deleted successfully")
            return true
        } catch {
            print("❌ Failed to delete workout: \(error)")
            return false
        }
    }

    // MARK: - Templates

    /// Saves a workout as a named template
    func saveTemplate(name: String, exercises: [WorkoutExercise]) -> Bool {
        let template = WorkoutSession(
            date: Date(),
            exercises: exercises,
            name: name,
            isTemplate: true
        )
        return saveWorkout(template)
    }

    /// Fetches all saved templates
    func fetchTemplates() -> [WorkoutSession] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()

        // Only fetch templates
        request.predicate = NSPredicate(format: "isTemplate == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.name, ascending: true)]

        do {
            let workouts = try context.fetch(request)
            return workouts.map { convertToWorkoutSession($0) }
        } catch {
            print("❌ Failed to fetch templates: \(error)")
            return []
        }
    }

    /// Updates an existing template
    func updateTemplate(id: UUID, name: String, exercises: [WorkoutExercise]) -> Bool {
        // Delete old template
        guard deleteWorkout(id: id) else { return false }

        // Save new version with same ID
        let template = WorkoutSession(
            id: id,
            date: Date(),
            exercises: exercises,
            name: name,
            isTemplate: true
        )
        return saveWorkout(template)
    }

    // MARK: - Helper Methods

    /// Converts a CoreData Workout entity to a WorkoutSession struct
    private func convertToWorkoutSession(_ workout: Workout) -> WorkoutSession {
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
}
