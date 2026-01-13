//
//  WorkoutModel.swift
//  FitnessTracker
//
//  Swift model structs for Workout data
//

import Foundation

/// Represents a single exercise within a workout
struct WorkoutExercise: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var rpe: Int  // Rate of Perceived Exertion (1-10 scale)
    var notes: String?
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: Int,
        weight: Double,
        rpe: Int,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.notes = notes
        self.order = order
    }
}

/// Represents a complete workout session or template
struct WorkoutSession: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var exercises: [WorkoutExercise]
    var name: String?  // Descriptive name for the workout (e.g., "Chest & Triceps", "Back Day")
    var isTemplate: Bool  // True if this is a saved template

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        exercises: [WorkoutExercise] = [],
        name: String? = nil,
        isTemplate: Bool = false
    ) {
        self.id = id
        self.date = date
        self.exercises = exercises
        self.name = name
        self.isTemplate = isTemplate
    }

    /// Total number of sets across all exercises
    var totalSets: Int {
        return exercises.reduce(0) { $0 + $1.sets }
    }

    /// Total number of reps across all exercises
    var totalReps: Int {
        return exercises.reduce(0) { $0 + ($1.sets * $1.reps) }
    }
}

// MARK: - Sample Data for Previews and Testing

extension WorkoutSession {
    static let sampleBenchPress = WorkoutExercise(
        name: "Bench Press",
        sets: 3,
        reps: 10,
        weight: 185.0,
        rpe: 7,
        notes: "Felt strong today"
    )

    static let sampleSquats = WorkoutExercise(
        name: "Squats",
        sets: 5,
        reps: 5,
        weight: 225.0,
        rpe: 8,
        notes: "Heavy but manageable",
        order: 1
    )

    static let sampleDeadlift = WorkoutExercise(
        name: "Deadlift",
        sets: 3,
        reps: 8,
        weight: 315.0,
        rpe: 9,
        notes: "PR attempt",
        order: 2
    )

    static let sampleWorkout = WorkoutSession(
        date: Date(),
        exercises: [sampleBenchPress, sampleSquats],
        name: "Upper Body",
        isTemplate: false
    )

    static let sampleTemplate = WorkoutSession(
        date: Date(),
        exercises: [sampleBenchPress, sampleSquats, sampleDeadlift],
        name: "Push Day A",
        isTemplate: true
    )
}
