//
//  Workout+Extensions.swift
//  FitnessTracker
//
//  Extensions for Workout CoreData entity
//

import Foundation

extension Workout {
    /// Returns exercises as a sorted array (by order)
    var exercisesArray: [Exercise] {
        let set = exercises as? Set<Exercise> ?? []
        return set.sorted { $0.order < $1.order }
    }
}
