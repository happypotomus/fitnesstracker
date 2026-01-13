//
//  WorkoutConfirmationView.swift
//  FitnessTracker
//
//  Screen for reviewing and editing workout before saving
//

import SwiftUI

struct WorkoutConfirmationView: View {
    @StateObject private var viewModel: WorkoutConfirmationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showTemplatePrompt: Bool = false
    @State private var showTemplateNameInput: Bool = false
    @State private var templateName: String = ""
    @State private var showFinalSuccess: Bool = false

    let isEditMode: Bool
    var onWorkoutSaved: (() -> Void)?

    init(workout: WorkoutSession, isEditMode: Bool = false, onWorkoutSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: WorkoutConfirmationViewModel(workout: workout))
        self.isEditMode = isEditMode
        self.onWorkoutSaved = onWorkoutSaved
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Review Workout")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Tap any field to edit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Workout Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        TextField("e.g., Chest & Triceps, Back Day", text: Binding(
                            get: { viewModel.workout.name ?? "" },
                            set: { viewModel.workout.name = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Date Picker
                    DatePicker(
                        "Date",
                        selection: Binding(
                            get: { viewModel.workout.date },
                            set: { viewModel.workout.date = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Exercises
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseEditCard(
                                exercise: exercise,
                                exerciseNumber: index + 1,
                                onUpdate: { updated in
                                    viewModel.updateExercise(at: index, with: updated)
                                },
                                onDelete: {
                                    viewModel.deleteExercise(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Add Exercise Button
                    Button(action: {
                        viewModel.addExercise()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Exercise")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
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

                    // Save Button
                    Button(action: saveWorkout) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Workout")
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
            // Alert 1: Save as Template?
            .alert("Save as Template?", isPresented: $showTemplatePrompt) {
                Button("Yes") {
                    print("🔍 User clicked YES to save as template")
                    showTemplateNameInput = true
                }
                Button("No", role: .cancel) {
                    print("🔍 User clicked NO to save as template")
                    // Skip template, go to final success
                    showFinalSuccess = true
                }
            } message: {
                Text("Would you like to save this workout as a reusable template?")
            }
            // Alert 2: Template Name Input
            .alert("Template Name", isPresented: $showTemplateNameInput) {
                TextField("Enter template name", text: $templateName)
                Button("Save") {
                    let success = viewModel.saveAsTemplate(name: templateName)
                    if success {
                        showFinalSuccess = true
                    }
                    templateName = "" // Reset for next time
                }
                Button("Cancel", role: .cancel) {
                    templateName = ""
                    showFinalSuccess = true
                }
            } message: {
                Text("Give this template a name so you can reuse it later")
            }
            // Alert 3: Final Success
            .alert(isEditMode ? "Workout Updated!" : "Workout Saved!", isPresented: $showFinalSuccess) {
                Button("OK") {
                    // Dismiss confirmation view
                    dismiss()
                    // Call callback to dismiss log workout view
                    onWorkoutSaved?()
                }
            } message: {
                Text(isEditMode ? "Your workout has been updated successfully!" : "Your workout has been saved successfully!")
            }
        }
    }

    private func saveWorkout() {
        let success = viewModel.saveWorkout()

        if success {
            if isEditMode {
                // Skip template prompt when editing
                showFinalSuccess = true
            } else {
                // Show template prompt when creating new workout
                showTemplatePrompt = true
            }
        }
    }
}

// MARK: - Exercise Edit Card

struct ExerciseEditCard: View {
    let exercise: WorkoutExercise
    let exerciseNumber: Int
    let onUpdate: (WorkoutExercise) -> Void
    let onDelete: () -> Void

    @State private var name: String
    @State private var sets: String
    @State private var reps: String
    @State private var weight: String
    @State private var rpe: Int
    @State private var notes: String

    init(exercise: WorkoutExercise, exerciseNumber: Int, onUpdate: @escaping (WorkoutExercise) -> Void, onDelete: @escaping () -> Void) {
        self.exercise = exercise
        self.exerciseNumber = exerciseNumber
        self.onUpdate = onUpdate
        self.onDelete = onDelete

        _name = State(initialValue: exercise.name)
        _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: "\(exercise.reps)")
        _weight = State(initialValue: exercise.weight > 0 ? "\(Int(exercise.weight))" : "")
        _rpe = State(initialValue: exercise.rpe)
        _notes = State(initialValue: exercise.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with delete button
            HStack {
                Text("Exercise \(exerciseNumber)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            // Exercise Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Exercise name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: name) { _, _ in updateExercise() }
            }

            // Sets, Reps, Weight in a row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Sets", text: $sets)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .onChange(of: sets) { _, _ in updateExercise() }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Reps", text: $reps)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .onChange(of: reps) { _, _ in updateExercise() }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight (lbs)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("0", text: $weight)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .onChange(of: weight) { _, _ in updateExercise() }
                }
            }

            // RPE Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("RPE (Rate of Perceived Exertion)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("RPE", selection: $rpe) {
                    Text("Not set").tag(0)
                    ForEach(1...10, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: rpe) { _, _ in updateExercise() }
            }

            // Notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Add notes...", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .onChange(of: notes) { _, _ in updateExercise() }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func updateExercise() {
        let updatedExercise = WorkoutExercise(
            id: exercise.id,
            name: name,
            sets: Int(sets) ?? 0,
            reps: Int(reps) ?? 0,
            weight: Double(weight) ?? 0.0,
            rpe: rpe,
            notes: notes.isEmpty ? nil : notes,
            order: exercise.order
        )
        onUpdate(updatedExercise)
    }
}

#Preview {
    WorkoutConfirmationView(workout: WorkoutSession.sampleWorkout)
}
