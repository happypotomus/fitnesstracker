//
//  MealDayListView.swift
//  FitnessTracker
//
//  Shows list of meals for a selected date with edit/delete
//

import SwiftUI

struct MealDayListView: View {
    let meals: [MealSession]
    let selectedDate: Date
    let onEdit: (MealSession) -> Void
    let onDelete: (MealSession) -> Void

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: selectedDate)
    }

    private var totalCalories: Double {
        meals.reduce(0) { $0 + $1.totalCalories }
    }

    private var totalProtein: Double {
        meals.reduce(0) { $0 + $1.totalProtein }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.headline)
                    Text("\(meals.count) meal\(meals.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Daily totals
                if !meals.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(totalCalories)) cal")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("\(Int(totalProtein))g protein")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            if meals.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No meals on this day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Meal list
                ForEach(meals) { meal in
                    MealDayCard(
                        meal: meal,
                        onEdit: { onEdit(meal) },
                        onDelete: { onDelete(meal) }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Meal Day Card

struct MealDayCard: View {
    let meal: MealSession
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded: Bool = false
    @State private var showDeleteAlert: Bool = false

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meal.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(timeString)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if let mealType = meal.mealType {
                            Text(mealType.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }

                    Text("\(meal.foodItems.count) item\(meal.foodItems.count == 1 ? "" : "s") • \(Int(meal.totalCalories)) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            // Food items summary (expandable)
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Hide Details" : "Show Details")
                        .font(.caption)
                        .foregroundColor(.green)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.green)

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(meal.foodItems) { foodItem in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(foodItem.name)
                                    .font(.subheadline)
                                Spacer()
                                if let cals = foodItem.calories {
                                    Text("\(Int(cals)) cal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if let portion = foodItem.portionSize {
                                Text(portion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                if let protein = foodItem.protein {
                                    Text("\(Int(protein))g P")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                if let carbs = foodItem.carbs {
                                    Text("\(Int(carbs))g C")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                                if let fat = foodItem.fat {
                                    Text("\(Int(fat))g F")
                                        .font(.caption2)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Totals
                    Divider()
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(Int(meal.totalCalories)) cal • \(Int(meal.totalProtein))g P • \(Int(meal.totalCarbs))g C • \(Int(meal.totalFat))g F")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Delete Meal?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
