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
                    if !viewModel.isProcessing && viewModel.parsedMeal == nil && !availableTemplates.isEmpty {
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
                    if !viewModel.isProcessing && viewModel.parsedMeal == nil {
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

                    // Success State - Show Parsed Meal
                    if let meal = viewModel.parsedMeal {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)

                            Text("Meal Parsed!")
                                .font(.title2)
                                .fontWeight(.bold)

                            if let mealType = meal.mealType {
                                Text(mealType.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text("\(meal.foodItems.count) food item(s) detected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Show food items
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(meal.foodItems) { foodItem in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(foodItem.name)
                                                .font(.headline)

                                            if let portion = foodItem.portionSize {
                                                Text(portion)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }

                                            HStack(spacing: 12) {
                                                if let cals = foodItem.calories {
                                                    Text("\(Int(cals)) cal")
                                                        .font(.caption)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.green.opacity(0.1))
                                                        .cornerRadius(8)
                                                }
                                                if let protein = foodItem.protein {
                                                    Text("\(Int(protein))g protein")
                                                        .font(.caption)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.blue.opacity(0.1))
                                                        .cornerRadius(8)
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
                            .frame(maxHeight: 200)

                            // Totals
                            VStack(spacing: 4) {
                                Text("Total: \(Int(meal.totalCalories)) cal")
                                    .font(.headline)
                                Text("\(Int(meal.totalProtein))g protein • \(Int(meal.totalCarbs))g carbs • \(Int(meal.totalFat))g fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)

                            Button(action: {
                                showConfirmation = true
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
                if let meal = viewModel.parsedMeal {
                    MealConfirmationView(meal: meal) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                NutritionTemplatePickerView(onTemplateSelected: { template in
                    viewModel.parsedMeal = MealSession(
                        date: Date(),
                        foodItems: template.foodItems,
                        mealType: template.mealType
                    )
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
