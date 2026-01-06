//
//  FitnessTrackerApp.swift
//  FitnessTracker
//
//  Created by Pranav Menon on 2026-01-04.
//

import SwiftUI
import CoreData

@main
struct FitnessTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
