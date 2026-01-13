//
//  LogMealView.swift
//  FitnessTracker
//
//  Screen for recording meal via voice
//

import SwiftUI

struct LogMealView: View {
    @StateObject private var viewModel = LogMealViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmation: Bool = false
    @State private var showBulkConfirmation: Bool = false
    @State private var showTemplatePicker: Bool = false
    @State private var availableTemplates: [MealSession] = []

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Log Meal")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Describe your meal using your voice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Use Template Button
                    if !viewModel.isProcessing && viewModel.parsedMeals.isEmpty && !availableTemplates.isEmpty {
                        Button(action: {
                            showTemplatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Use Template")
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .padding(.bottom, 8)
                    }

                    Spacer()

                    // Voice Recording Button
                    if !viewModel.isProcessing && viewModel.parsedMeals.isEmpty {
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

                            Text("Parsing your meal...")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Using AI to estimate nutrition data")
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
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }

                    // Success State - Show Parsed Meal(s)
                    if !viewModel.parsedMeals.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)

                            if viewModel.parsedMeals.count == 1 {
                                Text("Meal Parsed!")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                if let mealType = viewModel.parsedMeals[0].mealType {
                                    Text(mealType.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Text("\(viewModel.parsedMeals[0].foodItems.count) food item(s) detected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(viewModel.parsedMeals.count) Meals Parsed!")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Bulk logging detected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Show meals preview
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(viewModel.parsedMeals.enumerated()), id: \.element.id) { index, meal in
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Meal header
                                            HStack {
                                                if let mealType = meal.mealType {
                                                    Text(mealType.capitalized)
                                                        .font(.headline)
                                                } else {
                                                    Text("Meal \(index + 1)")
                                                        .font(.headline)
                                                }
                                                Spacer()
                                                Text("\(Int(meal.totalCalories)) cal")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }

                                            // Food items for this meal
                                            ForEach(meal.foodItems) { foodItem in
                                                HStack {
                                                    Text(foodItem.name)
                                                        .font(.subheadline)
                                                    Spacer()
                                                    if let portion = foodItem.portionSize {
                                                        Text(portion)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(maxHeight: 250)

                            // Total nutrition across all meals
                            if viewModel.parsedMeals.count > 1 {
                                VStack(spacing: 4) {
                                    let totalCals = viewModel.parsedMeals.reduce(0) { $0 + $1.totalCalories }
                                    let totalProtein = viewModel.parsedMeals.reduce(0) { $0 + $1.totalProtein }
                                    let totalCarbs = viewModel.parsedMeals.reduce(0) { $0 + $1.totalCarbs }
                                    let totalFat = viewModel.parsedMeals.reduce(0) { $0 + $1.totalFat }

                                    Text("Daily Total: \(Int(totalCals)) cal")
                                        .font(.headline)
                                    Text("\(Int(totalProtein))g protein • \(Int(totalCarbs))g carbs • \(Int(totalFat))g fat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }

                            Button(action: {
                                if viewModel.parsedMeals.count == 1 {
                                    showConfirmation = true
                                } else {
                                    showBulkConfirmation = true
                                }
                            }) {
                                Text("Continue")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .sheet(isPresented: $showConfirmation) {
                if viewModel.parsedMeals.count == 1 {
                    MealConfirmationView(meal: viewModel.parsedMeals[0]) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBulkConfirmation) {
                BulkMealConfirmationView(meals: viewModel.parsedMeals) {
                    dismiss()
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                NutritionTemplatePickerView(onTemplateSelected: { template in
                    viewModel.parsedMeals = [MealSession(
                        date: Date(),
                        foodItems: template.foodItems,
                        mealType: template.mealType
                    )]
                    showTemplatePicker = false
                })
            }
        }
        .onAppear {
            let repository = NutritionRepository()
            availableTemplates = repository.fetchTemplates()
        }
    }
}
