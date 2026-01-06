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
    @State private var showLogMeal: Bool = false
    @State private var showReviewNutrition: Bool = false

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

            // Main action buttons - 2x2 grid
            VStack(spacing: 16) {
                // Workout section header
                Text("WORKOUTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Button(action: {
                        showLogWorkout = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                            Text("Log Workout")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        showReviewWorkouts = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title)
                            Text("Review Workouts")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                // Nutrition section header
                Text("NUTRITION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                HStack(spacing: 12) {
                    Button(action: {
                        showLogMeal = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                            Text("Log Meal")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.green)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        showReviewNutrition = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title)
                            Text("Review Nutrition")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
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
        .sheet(isPresented: $showLogMeal) {
            LogMealView()
        }
        .sheet(isPresented: $showReviewNutrition) {
            ReviewNutritionView()
        }
    }
}

#Preview {
    HomeView()
}
