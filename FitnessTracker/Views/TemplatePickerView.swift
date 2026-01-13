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
    @State private var isMultiSelectMode = false
    @State private var selectedTemplateIDs: Set<UUID> = []

    let templates: [WorkoutSession]
    let onTemplateSelected: (WorkoutSession) -> Void
    var onMultipleTemplatesSelected: (([WorkoutSession]) -> Void)?
    var onTemplateEdited: (() -> Void)?

    private let repository = WorkoutRepository()
    private let maxMultiSelect = 5 // Limit for batch selection

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
                    // Mode Toggle
                    Picker("Selection Mode", selection: $isMultiSelectMode) {
                        Text("Single").tag(false)
                        Text("Multiple").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

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
                                    isSelected: selectedTemplateIDs.contains(template.id),
                                    showCheckbox: isMultiSelectMode,
                                    onEdit: {
                                        templateToEdit = template
                                    },
                                    onDelete: {
                                        templateToDelete = template
                                        showDeleteConfirmation = true
                                    }
                                )
                                .onTapGesture {
                                    handleTemplateTap(template)
                                }
                            }
                        }
                        .padding()
                    }

                    // Select Button (for multi-select mode)
                    if isMultiSelectMode && !selectedTemplateIDs.isEmpty {
                        Button(action: handleMultipleSelection) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Select \(selectedTemplateIDs.count) Template\(selectedTemplateIDs.count == 1 ? "" : "s")")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
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

    // MARK: - Template Selection Handlers

    private func handleTemplateTap(_ template: WorkoutSession) {
        if isMultiSelectMode {
            // Toggle selection
            if selectedTemplateIDs.contains(template.id) {
                selectedTemplateIDs.remove(template.id)
            } else {
                if selectedTemplateIDs.count < maxMultiSelect {
                    selectedTemplateIDs.insert(template.id)
                }
            }
        } else {
            // Single select mode
            onTemplateSelected(template)
            dismiss()
        }
    }

    private func handleMultipleSelection() {
        let selectedTemplates = templates.filter { selectedTemplateIDs.contains($0.id) }
        onMultipleTemplatesSelected?(selectedTemplates)
        dismiss()
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
    var isSelected: Bool = false
    var showCheckbox: Bool = false
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            // Checkbox (multi-select mode only)
            if showCheckbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }

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

            // Edit button (hidden in multi-select mode)
            if !showCheckbox {
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
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
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
