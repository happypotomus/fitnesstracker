//
//  Meal+Extensions.swift
//  FitnessTracker
//
//  Extensions for Meal CoreData entity
//

import Foundation

extension Meal {
    /// Returns food items as a sorted array (by order)
    var foodItemsArray: [FoodItem] {
        let set = foodItems as? Set<FoodItem> ?? []
        return set.sorted { $0.order < $1.order }
    }
}
