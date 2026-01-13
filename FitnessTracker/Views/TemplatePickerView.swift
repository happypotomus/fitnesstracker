//
//  TemplatePickerView.swift
//  FitnessTracker
//
//  Template selection UI for loading workouts from templates
//

import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var templateToEdit: WorkoutSession?
    @State private var templateToDelete: WorkoutSession?
    @State private var showDeleteConfirmation = false

    let templates: [WorkoutSession]
    let onTemplateSelected: (WorkoutSession) -> Void
    var onTemplateEdited: (() -> Void)?

    private let repository = WorkoutRepository()

    var filteredTemplates: [WorkoutSession] {
        if searchText.isEmpty {
            return templates
        }
        return templates.filter {
            $0.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if templates.isEmpty {
                    // Empty state
                    EmptyTemplateView()
                } else {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search templates", text: $searchText)
                            .textFieldStyle(.plain)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()

                    // Template list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredTemplates) { template in
                                TemplateCard(
                                    template: template,
                                    onEdit: {
                                        templateToEdit = template
                                    },
                                    onDelete: {
                                        templateToDelete = template
                                        showDeleteConfirmation = true
                                    }
                                )
                                .onTapGesture {
                                    onTemplateSelected(template)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $templateToEdit) { template in
                TemplateEditView(template: template) {
                    // When template is saved, notify parent to refresh
                    onTemplateEdited?()
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        deleteTemplate(template)
                    }
                }
            } message: {
                Text("This template will be permanently deleted. This action cannot be undone.")
            }
        }
    }

    // MARK: - Delete Template

    private func deleteTemplate(_ template: WorkoutSession) {
        if repository.deleteWorkout(id: template.id) {
            print("✅ Template deleted successfully")
            onTemplateEdited?() // Notify parent to refresh
        } else {
            print("❌ Failed to delete template")
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: WorkoutSession
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(template.name ?? "Unnamed")
                    .font(.headline)

                Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Show first 2-3 exercises as preview
                Text(exercisePreview)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var exercisePreview: String {
        let previewExercises = template.exercises.prefix(3)
        return previewExercises.map { $0.name }.joined(separator: ", ")
    }
}

// MARK: - Empty State

struct EmptyTemplateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Templates Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Save a workout as a template from the confirmation screen")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    TemplatePickerView(
        templates: [WorkoutSession.sampleWorkout],
        onTemplateSelected: { _ in },
        onTemplateEdited: { }
    )
}
