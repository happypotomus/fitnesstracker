//
//  BatchWorkoutConfirmationView.swift
//  FitnessTracker
//
//  Screen for reviewing and editing multiple workouts before batch saving
//

import SwiftUI

struct BatchWorkoutConfirmationView: View {
    @StateObject private var viewModel: BatchWorkoutConfirmationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var expandedWorkoutIndex: Int? = nil
    @State private var workoutToEdit: (index: Int, workout: WorkoutSession)? = nil
    @State private var showFinalSuccess: Bool = false

    var onWorkoutsSaved: (() -> Void)?

    init(workouts: [WorkoutSession], onWorkoutsSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BatchWorkoutConfirmationViewModel(workouts: workouts))
        self.onWorkoutsSaved = onWorkoutsSaved
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Review Workouts")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Logging \(viewModel.workouts.count) workout\(viewModel.workouts.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Shared Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date for All Workouts")
                            .font(.headline)
                            .padding(.horizontal)

                        DatePicker(
                            "Date",
                            selection: $viewModel.sharedDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Workouts List
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                            WorkoutSummaryCard(
                                workout: workout,
                                workoutNumber: index + 1,
                                isExpanded: expandedWorkoutIndex == index,
                                onToggleExpand: {
                                    withAnimation {
                                        expandedWorkoutIndex = expandedWorkoutIndex == index ? nil : index
                                    }
                                },
                                onEdit: {
                                    workoutToEdit = (index, workout)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Error Message
                    if !viewModel.saveError.isEmpty {
                        Text(viewModel.saveError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }

                    // Save All Button
                    Button(action: saveAllWorkouts) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save All Workouts")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: Binding(
                get: { workoutToEdit.map { IdentifiableWorkout(index: $0.index, workout: $0.workout) } },
                set: { workoutToEdit = $0.map { ($0.index, $0.workout) } }
            )) { identifiableWorkout in
                WorkoutConfirmationView(
                    workout: identifiableWorkout.workout,
                    isEditMode: false
                ) {
                    // Update the workout in the batch when editing is done
                    if let index = workoutToEdit?.index,
                       let updatedWorkout = workoutToEdit?.workout {
                        viewModel.updateWorkout(at: index, with: updatedWorkout)
                    }
                }
            }
            .alert("Workouts Saved!", isPresented: $showFinalSuccess) {
                Button("OK") {
                    dismiss()
                    onWorkoutsSaved?()
                }
            } message: {
                if viewModel.saveFailureCount > 0 {
                    Text("Saved \(viewModel.saveSuccessCount) workout(s) successfully. \(viewModel.saveFailureCount) failed.")
                } else {
                    Text("All \(viewModel.saveSuccessCount) workout(s) saved successfully!")
                }
            }
        }
    }

    private func saveAllWorkouts() {
        let success = viewModel.saveAllWorkouts()

        if success {
            showFinalSuccess = true
        }
    }
}

// MARK: - Workout Summary Card

struct WorkoutSummaryCard: View {
    let workout: WorkoutSession
    let workoutNumber: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout \(workoutNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(workout.name ?? "Unnamed Workout")
                        .font(.headline)
                }

                Spacer()

                // Edit Button
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                // Expand/Collapse Button
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Exercise Count (always visible)
            Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)

            // Expanded Content
            if isExpanded {
                Divider()

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
                                Text("\(Int(exercise.weight))lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if exercise.rpe > 0 {
                                Text("RPE \(exercise.rpe)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            onToggleExpand()
        }
    }
}

// MARK: - Helper for Sheet Binding

struct IdentifiableWorkout: Identifiable {
    let id = UUID()
    let index: Int
    let workout: WorkoutSession
}

#Preview {
    BatchWorkoutConfirmationView(
        workouts: [WorkoutSession.sampleWorkout, WorkoutSession.sampleWorkout]
    )
}
