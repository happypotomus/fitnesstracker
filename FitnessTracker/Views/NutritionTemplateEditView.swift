//
//  NutritionTemplateEditView.swift
//  FitnessTracker
//
//  Screen for editing meal templates
//

import SwiftUI

struct NutritionTemplateEditView: View {
    @StateObject private var viewModel: NutritionTemplateEditViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation: Bool = false
    @State private var showSuccessAlert: Bool = false

    var onTemplateSaved: (() -> Void)?

    init(template: MealSession, onTemplateSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: NutritionTemplateEditViewModel(template: template))
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
                    }
                    .padding(.top)

                    // Template Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Template name", text: $viewModel.templateName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Meal Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Meal Type", selection: Binding(
                            get: { viewModel.mealType ?? "" },
                            set: { viewModel.mealType = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Not Set").tag("")
                            Text("Breakfast").tag("breakfast")
                            Text("Lunch").tag("lunch")
                            Text("Dinner").tag("dinner")
                            Text("Snack").tag("snack")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Food Items
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.foodItems.enumerated()), id: \.element.id) { index, foodItem in
                            FoodItemEditCard(
                                foodItem: foodItem,
                                itemNumber: index + 1,
                                onUpdate: { updated in
                                    viewModel.updateFoodItem(at: index, with: updated)
                                },
                                onDelete: {
                                    viewModel.deleteFoodItem(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Add Food Item Button
                    Button(action: {
                        viewModel.addFoodItem()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Food Item")
                        }
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
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
                                Text("Save Template")
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

                    // Delete Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Template")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
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
            .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    let success = viewModel.deleteTemplate()
                    if success {
                        dismiss()
                        onTemplateSaved?()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Template Saved!", isPresented: $showSuccessAlert) {
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
            showSuccessAlert = true
        }
    }
}
