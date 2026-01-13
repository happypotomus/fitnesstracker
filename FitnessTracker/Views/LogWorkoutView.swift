//
//  LogWorkoutView.swift
//  FitnessTracker
//
//  Screen for recording workout via voice
//

import SwiftUI

struct LogWorkoutView: View {
    @StateObject private var viewModel = LogWorkoutViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmation: Bool = false
    @State private var showBatchConfirmation: Bool = false
    @State private var showTemplatePicker: Bool = false
    @State private var availableTemplates: [WorkoutSession] = []

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Log Workout")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Describe your workout using your voice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Use Template Button
                    if !viewModel.isProcessing && viewModel.parsedWorkout == nil && !availableTemplates.isEmpty {
                        Button(action: {
                            showTemplatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Use Template")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .padding(.bottom, 8)
                    }

                    Spacer()

                    // Voice Recording Button
                    if !viewModel.isProcessing && viewModel.parsedWorkout == nil {
                        VoiceRecordButton(
                            speechRecognizer: speechRecognizer,
                            onTranscriptionComplete: { transcription in
                                Task {
                                    await viewModel.processTranscription(transcription)
                                }
                            }
                        )
                    }

                    // Processing State
                    if viewModel.isProcessing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Parsing your workout...")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Using AI to understand your description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }

                    // Error State
                    if !viewModel.errorMessage.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)

                            Text("Oops!")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(viewModel.errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                viewModel.retry()
                                speechRecognizer.reset()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Try Again")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }

                    // Success State - Show Parsed Workout
                    if let workout = viewModel.parsedWorkout {
                        ScrollView {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)

                                Text("Workout Parsed!")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("\(workout.exercises.count) exercise(s) detected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                // Show exercises
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(workout.exercises) { exercise in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.headline)

                                            Text("\(exercise.sets) sets × \(exercise.reps) reps @ \(Int(exercise.weight))lbs")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            if exercise.rpe > 0 {
                                                Text("RPE: \(exercise.rpe)/10")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }

                                            if let notes = exercise.notes, !notes.isEmpty {
                                                Text("Notes: \(notes)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .italic()
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)

                                // Continue to Confirmation Button
                                Button(action: {
                                    if viewModel.isBatchMode {
                                        showBatchConfirmation = true
                                    } else {
                                        showConfirmation = true
                                    }
                                }) {
                                    HStack {
                                        Text("Continue")
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                            }
                            .padding()
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }

                    Spacer()
                }

                // Cancel button (top-left)
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .padding()

                        Spacer()
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showConfirmation) {
                if let workout = viewModel.parsedWorkout {
                    WorkoutConfirmationView(workout: workout) {
                        // When workout is saved, dismiss this view too
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBatchConfirmation) {
                BatchWorkoutConfirmationView(workouts: viewModel.parsedWorkouts) {
                    // When workouts are saved, dismiss this view too
                    dismiss()
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView(
                    templates: availableTemplates,
                    onTemplateSelected: { selectedTemplate in
                        loadTemplate(selectedTemplate)
                    },
                    onMultipleTemplatesSelected: { selectedTemplates in
                        loadMultipleTemplates(selectedTemplates)
                    },
                    onTemplateEdited: {
                        // Refresh templates after editing
                        availableTemplates = WorkoutRepository().fetchTemplates()
                    }
                )
            }
            .onAppear {
                // Fetch templates when view appears
                availableTemplates = WorkoutRepository().fetchTemplates()
            }
        }
    }

    // MARK: - Load Template

    private func loadTemplate(_ template: WorkoutSession) {
        // Create a new workout from template with today's date
        var workout = template
        workout.id = UUID() // New ID
        workout.date = Date() // Today's date
        workout.name = nil // Clear template name (it's now a regular workout)
        workout.isTemplate = false // ← FIX: Mark as regular workout, not template

        // Set parsed workout to show confirmation screen
        viewModel.parsedWorkout = workout
    }

    // MARK: - Load Multiple Templates

    private func loadMultipleTemplates(_ templates: [WorkoutSession]) {
        // Create new workouts from templates with today's date
        let workouts = templates.map { template -> WorkoutSession in
            var workout = template
            workout.id = UUID() // New ID
            workout.date = Date() // Today's date
            workout.isTemplate = false // Mark as regular workout

            return workout
        }

        // Set parsed workouts to show batch confirmation screen
        viewModel.parsedWorkouts = workouts

        // Also set first workout for backward compatibility
        if let first = workouts.first {
            viewModel.parsedWorkout = first
        }

        // Show batch confirmation
        showBatchConfirmation = true
    }
}

#Preview {
    LogWorkoutView()
}
