//
//  MealConfirmationView.swift
//  FitnessTracker
//
//  Screen for reviewing and editing meal before saving
//

import SwiftUI

struct MealConfirmationView: View {
    @StateObject private var viewModel: MealConfirmationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showTemplatePrompt: Bool = false
    @State private var showTemplateNameInput: Bool = false
    @State private var templateName: String = ""
    @State private var showFinalSuccess: Bool = false

    var onMealSaved: (() -> Void)?

    init(meal: MealSession, onMealSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: MealConfirmationViewModel(meal: meal))
        self.onMealSaved = onMealSaved
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Review Meal")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Tap any field to edit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Date Picker
                    DatePicker(
                        "Date",
                        selection: Binding(
                            get: { viewModel.meal.date },
                            set: { viewModel.meal.date = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Meal Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Meal Type", selection: Binding(
                            get: { viewModel.meal.mealType ?? "" },
                            set: { viewModel.meal.mealType = $0.isEmpty ? nil : $0 }
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

                    // Totals
                    VStack(spacing: 8) {
                        Text("Total Nutrition")
                            .font(.headline)
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(Int(viewModel.meal.totalCalories))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("calories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(Int(viewModel.meal.totalProtein))g")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(Int(viewModel.meal.totalCarbs))g")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(Int(viewModel.meal.totalFat))g")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Text("fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Food Items
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.meal.foodItems.enumerated()), id: \.element.id) { index, foodItem in
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
                    Button(action: saveMeal) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Meal")
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
                    showTemplateNameInput = true
                }
                Button("No", role: .cancel) {
                    showFinalSuccess = true
                }
            } message: {
                Text("Would you like to save this meal as a reusable template?")
            }
            // Alert 2: Template Name Input
            .alert("Template Name", isPresented: $showTemplateNameInput) {
                TextField("Enter template name", text: $templateName)
                Button("Save") {
                    let success = viewModel.saveAsTemplate(name: templateName)
                    if success {
                        showFinalSuccess = true
                    }
                    templateName = ""
                }
                Button("Cancel", role: .cancel) {
                    templateName = ""
                    showFinalSuccess = true
                }
            } message: {
                Text("Give this template a name so you can reuse it later")
            }
            // Alert 3: Final Success
            .alert("Meal Saved!", isPresented: $showFinalSuccess) {
                Button("OK") {
                    dismiss()
                    onMealSaved?()
                }
            } message: {
                Text("Your meal has been saved successfully!")
            }
        }
    }

    private func saveMeal() {
        let success = viewModel.saveMeal()

        if success {
            showTemplatePrompt = true
        }
    }
}

// MARK: - Food Item Edit Card

struct FoodItemEditCard: View {
    let foodItem: MealFood
    let itemNumber: Int
    let onUpdate: (MealFood) -> Void
    let onDelete: () -> Void

    @State private var name: String
    @State private var portionSize: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var notes: String

    init(foodItem: MealFood, itemNumber: Int, onUpdate: @escaping (MealFood) -> Void, onDelete: @escaping () -> Void) {
        self.foodItem = foodItem
        self.itemNumber = itemNumber
        self.onUpdate = onUpdate
        self.onDelete = onDelete

        _name = State(initialValue: foodItem.name)
        _portionSize = State(initialValue: foodItem.portionSize ?? "")
        _calories = State(initialValue: foodItem.calories != nil ? String(Int(foodItem.calories!)) : "")
        _protein = State(initialValue: foodItem.protein != nil ? String(Int(foodItem.protein!)) : "")
        _carbs = State(initialValue: foodItem.carbs != nil ? String(Int(foodItem.carbs!)) : "")
        _fat = State(initialValue: foodItem.fat != nil ? String(Int(foodItem.fat!)) : "")
        _notes = State(initialValue: foodItem.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Delete Button
            HStack {
                Text("Food Item \(itemNumber)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            // Name
            TextField("Food name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: name) { _ in updateFoodItem() }

            // Portion Size
            TextField("Portion size (e.g., 1 cup)", text: $portionSize)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: portionSize) { _ in updateFoodItem() }

            // Macros
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $calories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: calories) { _ in updateFoodItem() }
                }

                VStack(alignment: .leading) {
                    Text("Protein (g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $protein)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: protein) { _ in updateFoodItem() }
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Carbs (g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $carbs)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: carbs) { _ in updateFoodItem() }
                }

                VStack(alignment: .leading) {
                    Text("Fat (g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $fat)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: fat) { _ in updateFoodItem() }
                }
            }

            // Notes
            TextField("Notes (optional)", text: $notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: notes) { _ in updateFoodItem() }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func updateFoodItem() {
        let updated = MealFood(
            id: foodItem.id,
            name: name,
            portionSize: portionSize.isEmpty ? nil : portionSize,
            calories: Double(calories),
            protein: Double(protein),
            carbs: Double(carbs),
            fat: Double(fat),
            notes: notes.isEmpty ? nil : notes,
            order: foodItem.order
        )
        onUpdate(updated)
    }
}
