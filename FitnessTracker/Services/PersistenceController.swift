//
//  PersistenceController.swift
//  FitnessTracker
//
//  CoreData stack manager
//

import CoreData

struct PersistenceController {
    // Singleton instance for the entire app
    static let shared = PersistenceController()

    // Preview instance for SwiftUI previews with in-memory store
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        let sampleWorkout = Workout(context: viewContext)
        sampleWorkout.id = UUID()
        sampleWorkout.date = Date()
        sampleWorkout.name = nil // Regular workout (not a template)

        let exercise1 = Exercise(context: viewContext)
        exercise1.id = UUID()
        exercise1.name = "Bench Press"
        exercise1.sets = 3
        exercise1.reps = 10
        exercise1.weight = 185.0
        exercise1.rpe = 7
        exercise1.notes = "Felt strong today"
        exercise1.order = 0
        exercise1.workout = sampleWorkout

        let exercise2 = Exercise(context: viewContext)
        exercise2.id = UUID()
        exercise2.name = "Squats"
        exercise2.sets = 5
        exercise2.reps = 5
        exercise2.weight = 225.0
        exercise2.rpe = 8
        exercise2.notes = "Heavy but manageable"
        exercise2.order = 1
        exercise2.workout = sampleWorkout

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitnessTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Failed to load Core Data stack: \(error)")
            }

            print("✅ CoreData store loaded: \(description.url?.absoluteString ?? "unknown")")
        }

        // Enable automatic merging of changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save Context

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("✅ Context saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Test Data Methods

    func insertTestData() {
        let context = container.viewContext

        // Create a test workout with 2 exercises
        let workout = Workout(context: context)
        workout.id = UUID()
        workout.date = Date()
        workout.name = nil // Not a template

        let exercise1 = Exercise(context: context)
        exercise1.id = UUID()
        exercise1.name = "Deadlift"
        exercise1.sets = 3
        exercise1.reps = 8
        exercise1.weight = 315.0
        exercise1.rpe = 9
        exercise1.notes = "PR attempt"
        exercise1.order = 0
        exercise1.workout = workout

        let exercise2 = Exercise(context: context)
        exercise2.id = UUID()
        exercise2.name = "Pull-ups"
        exercise2.sets = 4
        exercise2.reps = 12
        exercise2.weight = 0.0 // Bodyweight
        exercise2.rpe = 6
        exercise2.notes = ""
        exercise2.order = 1
        exercise2.workout = workout

        save()
        print("📝 Test workout inserted with 2 exercises")
    }

    func fetchAllWorkouts() -> [Workout] {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]

        do {
            let workouts = try container.viewContext.fetch(request)
            print("📊 Fetched \(workouts.count) workout(s)")
            return workouts
        } catch {
            print("❌ Failed to fetch workouts: \(error)")
            return []
        }
    }

    func printAllWorkouts() {
        let workouts = fetchAllWorkouts()

        for (index, workout) in workouts.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            print("\n--- Workout \(index + 1) ---")
            print("Date: \(dateFormatter.string(from: workout.date ?? Date()))")
            print("Exercises: \(workout.exercisesArray.count)")

            for exercise in workout.exercisesArray {
                print("  • \(exercise.name ?? "Unknown"): \(exercise.sets) sets × \(exercise.reps) reps @ \(exercise.weight)lbs (RPE \(exercise.rpe))")
                if let notes = exercise.notes, !notes.isEmpty {
                    print("    Notes: \(notes)")
                }
            }
        }
    }
}
