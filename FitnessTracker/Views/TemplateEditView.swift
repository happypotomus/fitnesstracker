//
//  TemplateEditView.swift
//  FitnessTracker
//
//  Screen for editing existing templates
//

import SwiftUI

struct TemplateEditView: View {
    @StateObject private var viewModel: TemplateEditViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showSaveAlert = false

    var onTemplateSaved: (() -> Void)?

    init(template: WorkoutSession, onTemplateSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TemplateEditViewModel(template: template))
        self.onTemplateSaved = onTemplateSaved
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Edit Template")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Update template name and exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Template Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template Name")
                            .font(.headline)
                            .padding(.horizontal)

                        TextField("Template name", text: $viewModel.templateName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Exercises
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
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
                    Button(action: saveTemplate) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Changes")
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
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Template Saved!", isPresented: $showSaveAlert) {
                Button("OK") {
                    dismiss()
                    onTemplateSaved?()
                }
            } message: {
                Text("Your template has been updated successfully!")
            }
        }
    }

    private func saveTemplate() {
        let success = viewModel.saveTemplate()
        if success {
            showSaveAlert = true
        }
    }
}

#Preview {
    TemplateEditView(template: WorkoutSession.sampleWorkout)
}
