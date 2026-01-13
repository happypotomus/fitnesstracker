//
//  BulkMealConfirmationView.swift
//  FitnessTracker
//
//  Screen for reviewing and editing multiple meals before saving
//

import SwiftUI

struct BulkMealConfirmationView: View {
    @StateObject private var viewModel: BulkMealConfirmationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var expandedMealIndices: Set<Int> = []
    @State private var showFinalSuccess: Bool = false

    var onMealsSaved: (() -> Void)?

    init(meals: [MealSession], onMealsSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BulkMealConfirmationViewModel(meals: meals))
        self.onMealsSaved = onMealsSaved
        // Expand all meals by default
        _expandedMealIndices = State(initialValue: Set(meals.indices))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Review \(viewModel.meals.count) Meals")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Tap any field to edit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Daily Totals
                    let totalCals = viewModel.meals.reduce(0) { $0 + $1.totalCalories }
                    let totalProtein = viewModel.meals.reduce(0) { $0 + $1.totalProtein }
                    let totalCarbs = viewModel.meals.reduce(0) { $0 + $1.totalCarbs }
                    let totalFat = viewModel.meals.reduce(0) { $0 + $1.totalFat }

                    VStack(spacing: 8) {
                        Text("Daily Total")
                            .font(.headline)
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(Int(totalCals))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("calories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(Int(totalProtein))g")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(Int(totalCarbs))g")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(Int(totalFat))g")
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

                    // Meals List
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.meals.enumerated()), id: \.element.id) { index, meal in
                            ExpandableMealCard(
                                meal: Binding(
                                    get: { viewModel.meals[index] },
                                    set: { viewModel.updateMeal(at: index, with: $0) }
                                ),
                                mealNumber: index + 1,
                                isExpanded: Binding(
                                    get: { expandedMealIndices.contains(index) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedMealIndices.insert(index)
                                        } else {
                                            expandedMealIndices.remove(index)
                                        }
                                    }
                                ),
                                onUpdateFoodItem: { foodIndex, updatedFoodItem in
                                    viewModel.updateFoodItem(mealIndex: index, foodIndex: foodIndex, with: updatedFoodItem)
                                },
                                onDeleteFoodItem: { foodIndex in
                                    viewModel.deleteFoodItem(mealIndex: index, foodIndex: foodIndex)
                                },
                                onAddFoodItem: {
                                    viewModel.addFoodItem(to: index)
                                },
                                onDeleteMeal: {
                                    viewModel.deleteMeal(at: index)
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
                    Button(action: saveAllMeals) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save All Meals")
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
            // Alert: Final Success
            .alert("Meals Saved!", isPresented: $showFinalSuccess) {
                Button("OK") {
                    dismiss()
                    onMealsSaved?()
                }
            } message: {
                Text("\(viewModel.meals.count) meals have been saved successfully!")
            }
        }
    }

    private func saveAllMeals() {
        let success = viewModel.saveAllMeals()

        if success {
            showFinalSuccess = true
        }
    }
}

// MARK: - Expandable Meal Card

struct ExpandableMealCard: View {
    @Binding var meal: MealSession
    let mealNumber: Int
    @Binding var isExpanded: Bool
    let onUpdateFoodItem: (Int, MealFood) -> Void
    let onDeleteFoodItem: (Int) -> Void
    let onAddFoodItem: () -> Void
    let onDeleteMeal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - Always visible
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if let mealType = meal.mealType {
                                Text(mealType.capitalized)
                                    .font(.headline)
                            } else {
                                Text("Meal \(mealNumber)")
                                    .font(.headline)
                            }
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }

                        Text("\(Int(meal.totalCalories)) cal • \(meal.foodItems.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded Content
            if isExpanded {
                Divider()

                // Date Picker
                DatePicker(
                    "Date",
                    selection: $meal.date,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.subheadline)

                // Meal Type Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Meal Type", selection: Binding(
                        get: { meal.mealType ?? "" },
                        set: { meal.mealType = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Not Set").tag("")
                        Text("Breakfast").tag("breakfast")
                        Text("Lunch").tag("lunch")
                        Text("Dinner").tag("dinner")
                        Text("Snack").tag("snack")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Food Items
                VStack(spacing: 8) {
                    ForEach(Array(meal.foodItems.enumerated()), id: \.element.id) { index, foodItem in
                        CompactFoodItemEditCard(
                            foodItem: foodItem,
                            itemNumber: index + 1,
                            onUpdate: { updated in
                                onUpdateFoodItem(index, updated)
                            },
                            onDelete: {
                                onDeleteFoodItem(index)
                            }
                        )
                    }
                }

                // Add Food Item Button
                Button(action: onAddFoodItem) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Food Item")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }

                // Delete Meal Button
                Button(action: onDeleteMeal) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete This Meal")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Compact Food Item Edit Card

struct CompactFoodItemEditCard: View {
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
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Item \(itemNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Name and Portion
            TextField("Food name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.caption)
                .onChange(of: name) { _ in updateFoodItem() }

            TextField("Portion", text: $portionSize)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.caption)
                .onChange(of: portionSize) { _ in updateFoodItem() }

            // Macros in compact grid
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0", text: $calories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)
                        .onChange(of: calories) { _ in updateFoodItem() }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("P")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0", text: $protein)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)
                        .onChange(of: protein) { _ in updateFoodItem() }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("C")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0", text: $carbs)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)
                        .onChange(of: carbs) { _ in updateFoodItem() }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("F")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0", text: $fat)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)
                        .onChange(of: fat) { _ in updateFoodItem() }
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
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
            notes: nil,
            order: foodItem.order
        )
        onUpdate(updated)
    }
}
