//
//  NutritionTemplatePickerView.swift
//  FitnessTracker
//
//  Template selection UI for loading meals from templates
//

import SwiftUI

struct NutritionTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var templateToEdit: MealSession?
    @State private var templateToDelete: MealSession?
    @State private var showDeleteConfirmation = false
    @State private var templates: [MealSession] = []

    let onTemplateSelected: (MealSession) -> Void
    var onTemplateEdited: (() -> Void)?

    private let repository = NutritionRepository()

    var filteredTemplates: [MealSession] {
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
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Templates Yet")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Save a meal as a template to see it here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
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
                                NutritionTemplateCard(
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
            .navigationTitle("Select Meal Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $templateToEdit) { template in
                NutritionTemplateEditView(template: template) {
                    loadTemplates()
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
        .onAppear {
            loadTemplates()
        }
    }

    private func loadTemplates() {
        templates = repository.fetchTemplates()
    }

    // MARK: - Delete Template

    private func deleteTemplate(_ template: MealSession) {
        if repository.deleteMeal(id: template.id) {
            print("✅ Meal template deleted successfully")
            loadTemplates()
            onTemplateEdited?()
        } else {
            print("❌ Failed to delete meal template")
        }
    }
}

// MARK: - Nutrition Template Card

struct NutritionTemplateCard: View {
    let template: MealSession
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name ?? "Unnamed")
                        .font(.headline)

                    if let mealType = template.mealType {
                        Text(mealType.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                Text("\(template.foodItems.count) food items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Label("\(Int(template.totalCalories)) cal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Label("\(Int(template.totalProtein))g protein", systemImage: "leaf.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(BorderlessButtonStyle())

            Button(action: onDelete) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
