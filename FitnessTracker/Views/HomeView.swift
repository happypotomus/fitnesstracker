//
//  HomeView.swift
//  FitnessTracker
//
//  Main home screen with Log Workout and Review Workouts buttons
//

import SwiftUI

struct HomeView: View {
    @State private var showLogWorkout: Bool = false
    @State private var showReviewWorkouts: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App title
            VStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("FitnessTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            Spacer()

            // Main action buttons
            VStack(spacing: 16) {
                Button(action: {
                    showLogWorkout = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Log New Workout")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: {
                    showReviewWorkouts = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                        Text("Review Workouts")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showLogWorkout) {
            LogWorkoutView()
        }
        .sheet(isPresented: $showReviewWorkouts) {
            ReviewWorkoutsView()
        }
    }
}

#Preview {
    HomeView()
}
