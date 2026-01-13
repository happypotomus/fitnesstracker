//
//  OpenAIService.swift
//  FitnessTracker
//
//  Service for communicating with OpenAI API
//

import Foundation

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case jsonParsingError(Error)
    case rateLimitExceeded
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key found. Please configure your OpenAI API key."
        case .invalidURL:
            return "Invalid API URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from OpenAI."
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .jsonParsingError(let error):
            return "Failed to parse workout data: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key."
        }
    }
}

class OpenAIService {
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Cost-effective model, can upgrade to gpt-4 if needed
    private var apiKey: String?

    init() {
        self.apiKey = KeychainManager.shared.getAPIKey()
    }

    // MARK: - Workout Parsing

    /// Parses natural language workout description into structured WorkoutSession
    func parseWorkoutText(_ text: String, previousWorkout: WorkoutSession? = nil, availableTemplates: [WorkoutSession] = []) async throws -> WorkoutSession {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = PromptTemplates.workoutParsingPrompt(input: text, previousWorkout: previousWorkout, availableTemplates: availableTemplates)

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a workout data parser. Respond only with valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3 // Lower temperature for more consistent parsing
        ]

        let responseText = try await makeAPIRequest(apiKey: apiKey, body: requestBody)

        // Parse the JSON response into WorkoutSession
        return try parseWorkoutJSON(responseText)
    }

    // MARK: - Workout History Query

    /// Queries workout history with natural language question
    func queryWorkoutHistory(_ question: String, context: [WorkoutSession]) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = PromptTemplates.workoutQueryPrompt(question: question, workouts: context)

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful fitness data analyst."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7 // Higher temperature for more natural conversation
        ]

        return try await makeAPIRequest(apiKey: apiKey, body: requestBody)
    }

    /// Queries workout history with conversation context for follow-up questions
    func queryWorkoutHistoryWithContext(
        _ question: String,
        workouts: [WorkoutSession],
        conversationContext: ConversationContext
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = PromptTemplates.workoutQueryPromptWithContext(
            question: question,
            workouts: workouts,
            context: conversationContext
        )

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful fitness data analyst."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500 // Limit response length for chat UI
        ]

        return try await makeAPIRequest(apiKey: apiKey, body: requestBody)
    }

    // MARK: - Nutrition Parsing

    /// Parses natural language meal description into structured MealSession(s)
    /// Returns array to support bulk logging (can be single meal or multiple meals)
    func parseMealText(_ text: String, previousMeal: MealSession? = nil, availableTemplates: [MealSession] = []) async throws -> [MealSession] {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = PromptTemplates.mealParsingPrompt(input: text, previousMeal: previousMeal, availableTemplates: availableTemplates)

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a nutrition data parser. Respond only with valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3 // Lower temperature for more consistent parsing
        ]

        let responseText = try await makeAPIRequest(apiKey: apiKey, body: requestBody)

        // Parse the JSON response into MealSession array
        return try parseMealJSON(responseText)
    }

    // MARK: - Nutrition History Query

    /// Queries meal history with natural language question
    func queryNutritionHistory(_ question: String, context: [MealSession]) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = PromptTemplates.nutritionQueryPrompt(question: question, meals: context)

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful nutrition data analyst."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7 // Higher temperature for more natural conversation
        ]

        return try await makeAPIRequest(apiKey: apiKey, body: requestBody)
    }

    /// Queries meal history with conversation context for follow-up questions
    func queryNutritionHistoryWithContext(
        _ question: String,
        meals: [MealSession],
        conversationContext: ConversationContext
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = PromptTemplates.nutritionQueryPromptWithContext(
            question: question,
            meals: meals,
            context: conversationContext
        )

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful nutrition data analyst."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500 // Limit response length for chat UI
        ]

        return try await makeAPIRequest(apiKey: apiKey, body: requestBody)
    }

    // MARK: - Private Methods

    private func makeAPIRequest(apiKey: String, body: [String: Any]) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw OpenAIError.jsonParsingError(error)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status code
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                throw OpenAIError.invalidAPIKey
            case 429:
                throw OpenAIError.rateLimitExceeded
            default:
                // Try to extract error message from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                } else {
                    throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
                }
            }
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ Invalid response structure: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw OpenAIError.invalidResponse
        }

        return content
    }

    private func parseWorkoutJSON(_ jsonString: String) throws -> WorkoutSession {
        guard let data = jsonString.data(using: .utf8) else {
            throw OpenAIError.jsonParsingError(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert string to data"]))
        }

        struct WorkoutResponse: Codable {
            let name: String?
            let date: String?
            let exercises: [ExerciseResponse]
        }

        struct ExerciseResponse: Codable {
            let name: String
            let sets: Int
            let reps: Int
            let weight: Double?
            let rpe: Int?
            let notes: String?
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(WorkoutResponse.self, from: data)

            let exercises = response.exercises.enumerated().map { index, ex in
                WorkoutExercise(
                    name: ex.name,
                    sets: ex.sets,
                    reps: ex.reps,
                    weight: ex.weight ?? 0.0,
                    rpe: ex.rpe ?? 0,
                    notes: ex.notes,
                    order: index
                )
            }

            // Parse date from ISO 8601 string if provided, otherwise use current time
            var workoutDate = Date()
            if let dateString = response.date {
                print("🔍 DIAGNOSTIC: AI returned date string: '\(dateString)'")

                // Parse the ISO8601 date
                let isoFormatter = ISO8601DateFormatter()
                if let parsedDate = isoFormatter.date(from: dateString) {
                    // Convert to local timezone at 8:00 AM
                    // This fixes the timezone bug where "January 9th" in UTC becomes "January 8th" in PST
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month, .day], from: parsedDate)

                    // Create date at 8:00 AM in user's local timezone
                    var newComponents = DateComponents()
                    newComponents.year = components.year
                    newComponents.month = components.month
                    newComponents.day = components.day
                    newComponents.hour = 8
                    newComponents.minute = 0
                    newComponents.second = 0
                    newComponents.timeZone = TimeZone.current

                    if let localDate = calendar.date(from: newComponents) {
                        workoutDate = localDate

                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        print("🔍 DIAGNOSTIC: Parsed to local date: \(formatter.string(from: localDate))")
                    } else {
                        workoutDate = parsedDate
                        print("⚠️ Could not convert to local timezone, using UTC date")
                    }
                } else {
                    print("⚠️ Could not parse date '\(dateString)', using current time")
                }
            } else {
                print("🔍 DIAGNOSTIC: No date in AI response, using current time")
            }

            return WorkoutSession(
                date: workoutDate,
                exercises: exercises,
                name: response.name,
                isTemplate: false
            )
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 JSON string: \(jsonString)")
            throw OpenAIError.jsonParsingError(error)
        }
    }

    private func parseMealJSON(_ jsonString: String) throws -> [MealSession] {
        guard let data = jsonString.data(using: .utf8) else {
            throw OpenAIError.jsonParsingError(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert string to data"]))
        }

        struct BulkMealResponse: Codable {
            let meals: [SingleMealResponse]
        }

        struct SingleMealResponse: Codable {
            let mealType: String?
            let date: String?
            let foodItems: [FoodItemResponse]
        }

        struct FoodItemResponse: Codable {
            let name: String
            let portionSize: String?
            let calories: Double?
            let protein: Double?
            let carbs: Double?
            let fat: Double?
            let notes: String?
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(BulkMealResponse.self, from: data)

            let isoFormatter = ISO8601DateFormatter()

            return response.meals.map { meal in
                let foodItems = meal.foodItems.enumerated().map { index, food in
                    MealFood(
                        name: food.name,
                        portionSize: food.portionSize,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        notes: food.notes,
                        order: index
                    )
                }

                // Parse date from ISO 8601 string if provided, otherwise use current time
                var mealDate = Date()
                if let dateString = meal.date {
                    if let parsedDate = isoFormatter.date(from: dateString) {
                        // Convert to local timezone at 8:00 AM (or appropriate meal time)
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: parsedDate)

                        var newComponents = DateComponents()
                        newComponents.year = components.year
                        newComponents.month = components.month
                        newComponents.day = components.day
                        newComponents.hour = 8
                        newComponents.minute = 0
                        newComponents.second = 0
                        newComponents.timeZone = TimeZone.current

                        if let localDate = calendar.date(from: newComponents) {
                            mealDate = localDate
                        } else {
                            mealDate = parsedDate
                        }
                    } else {
                        print("⚠️ Could not parse date '\(dateString)', using current time")
                    }
                }

                return MealSession(
                    date: mealDate,
                    foodItems: foodItems,
                    mealType: meal.mealType
                )
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 JSON string: \(jsonString)")
            throw OpenAIError.jsonParsingError(error)
        }
    }
}
