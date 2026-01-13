//
//  WorkoutDayListView.swift
//  FitnessTracker
//
//  Shows list of workouts for a selected date with edit/delete
//

import SwiftUI

struct WorkoutDayListView: View {
    let workouts: [WorkoutSession]
    let selectedDate: Date
    let onEdit: (WorkoutSession) -> Void
    let onDelete: (WorkoutSession) -> Void

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.headline)
                    Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)

            if workouts.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No workouts on this day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Workout list
                ForEach(workouts) { workout in
                    WorkoutDayCard(
                        workout: workout,
                        onEdit: { onEdit(workout) },
                        onDelete: { onDelete(workout) }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Workout Day Card

struct WorkoutDayCard: View {
    let workout: WorkoutSession
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded: Bool = false
    @State private var showDeleteAlert: Bool = false

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name ?? timeString)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        if workout.name != nil {
                            Text(timeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s") • \(workout.totalSets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            // Exercise summary (expandable)
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Hide Details" : "Show Details")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workout.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(exercise.sets)×\(exercise.reps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if exercise.weight > 0 {
                                Text("@ \(Int(exercise.weight))lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
