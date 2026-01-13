//
//  PromptTemplates.swift
//  FitnessTracker
//
//  Prompt templates for OpenAI API calls
//

import Foundation

struct PromptTemplates {

    // MARK: - Workout Parsing Prompt

    static func workoutParsingPrompt(input: String, previousWorkout: WorkoutSession? = nil, availableTemplates: [WorkoutSession] = []) -> String {
        var prompt = """
        You are a workout parser. Convert the user's natural language workout description into structured JSON.

        The user will describe their workout using voice, so the text may be informal and include filler words.

        Expected JSON format for SINGLE workout:
        {
          "workouts": [
            {
              "name": "Descriptive Workout Name",
              "date": "2026-01-02T08:00:00Z",
              "exercises": [
                {
                  "name": "Exercise Name",
                  "sets": 3,
                  "reps": 10,
                  "weight": 185.0,
                  "rpe": 7,
                  "notes": "optional notes"
                }
              ]
            }
          ]
        }

        Expected JSON format for MULTIPLE workouts (when user mentions multiple templates or workout types):
        {
          "workouts": [
            {
              "name": "Push Day",
              "date": "2026-01-02T08:00:00Z",
              "exercises": [...]
            },
            {
              "name": "Cardio",
              "date": "2026-01-02T08:00:00Z",
              "exercises": [...]
            }
          ]
        }

        Rules:
        1. Extract exercise names, sets, reps, weight, and RPE (Rate of Perceived Exertion, 1-10 scale)
        2. If RPE is not mentioned, omit it or set to null
        3. If weight is not mentioned, assume 0.0 (bodyweight)
        4. Standardize exercise names (e.g., "benching" → "Bench Press", "pullups" → "Pull-ups")
        5. IMPORTANT: Recovery activities like "sauna", "stretching", "foam rolling", "ice bath" are VALID exercises. Include them with sets=1, reps=1, weight=0
        6. Cardio activities like "running", "biking", "swimming" are VALID exercises. Use reps to represent duration in minutes
        7. If the user says "same as last time", use the previous workout data provided below
        8. Infer reasonable values when data is incomplete
        9. For notes, capture any relevant comments about form, difficulty, or how it felt
        10. IMPORTANT: Generate a short, descriptive "name" for each workout based on the exercises (e.g., "Chest & Triceps", "Back Day", "Upper Body", "Leg Day", "Full Body", "Push Workout", "Recovery Session", "Cardio")
        11. If using a template, the name should match the template name
        12. IMPORTANT: Extract the workout date if mentioned (e.g., "on jan 2nd", "yesterday", "last monday", "this past saturday"). Return in ISO 8601 format. If no date is mentioned, set to null (current time will be used)
        13. Current date context: Today is \(Date().formatted(.iso8601)), which is a \(Date().formatted(.dateTime.weekday(.wide))). Use this to calculate relative dates like "yesterday", "last week", or "this past saturday"
        14. CRITICAL: Detect if user is describing MULTIPLE workouts (e.g., "I did push day and cardio", "upperbody + run", "chest workout and stretching")
        15. For multiple workouts, create separate workout objects in the "workouts" array
        16. Return ONLY valid JSON with "workouts" array (even if just one workout), no additional text or explanation

        """

        // Add available templates if any
        if !availableTemplates.isEmpty {
            prompt += """

            Available Templates (you can use these if the user references them by name):

            """

            for template in availableTemplates {
                prompt += formatTemplateForPrompt(template) + "\n\n"
            }

            prompt += """
            Template Usage Rules:
            1. If the user references a template by name (e.g., "use my push day template", "do leg day", "load push day"), start with that template's exercises
            2. Template names are case-insensitive and can be referenced partially (e.g., "push" matches "Push Day A")
            3. If multiple templates match, choose the closest match based on the user's phrasing
            4. If the template name doesn't match any available templates, ignore the reference and parse as a normal workout
            5. CRITICAL: If the user mentions MULTIPLE templates (e.g., "I did push day and cardio", "upperbody + leg day"), match each template separately and create multiple workout objects
            6. Apply any modifications the user mentions:
               - "add 5 pounds to bench press" → Increase bench press weight by 5
               - "but do 12 reps instead" → Change reps to 12 for specified exercise
               - "skip overhead press" → Remove overhead press from output
            7. If the user wants to add exercises, append them to the template exercises
            8. If the user wants to remove exercises, exclude them from the output
            9. Keep all unmodified exercises exactly as they are in the template
            10. When matching multiple templates, create a separate workout object for each template in the "workouts" array

            """
        }

        if let previous = previousWorkout {
            prompt += """

            Previous workout (for "same as last time" reference):
            \(formatWorkoutForPrompt(previous))

            """
        }

        prompt += """

        User input: "\(input)"

        Return the JSON now:
        """

        return prompt
    }

    // MARK: - Workout Query Prompt

    static func workoutQueryPrompt(question: String, workouts: [WorkoutSession]) -> String {
        let workoutData = workouts.map { formatWorkoutForPrompt($0) }.joined(separator: "\n\n")

        return """
        You are a fitness data analyst. Answer the user's question about their workout history.

        You have access to their complete workout history in the format below. Analyze the data and provide a clear, concise answer.

        Guidelines:
        1. Be conversational and friendly
        2. Use specific numbers and dates when relevant
        3. Identify trends and patterns
        4. Provide actionable insights when appropriate
        5. If the data doesn't support answering the question, say so honestly
        6. Do NOT use charts, tables, or formatted output - just natural language text

        Workout History:
        \(workoutData)

        User Question: "\(question)"

        Answer:
        """
    }

    // MARK: - Workout Query with Conversation Context

    static func workoutQueryPromptWithContext(
        question: String,
        workouts: [WorkoutSession],
        context: ConversationContext
    ) -> String {
        let workoutData = workouts.map { formatWorkoutForPrompt($0) }.joined(separator: "\n\n")
        let conversationHistory = context.formatForPrompt()

        var prompt = """
        You are a fitness data analyst having a conversation with a user about their workout history.

        Guidelines:
        1. Be conversational, friendly, and concise (2-3 paragraphs max)
        2. Use specific numbers, dates, and exercise names from the data
        3. Reference previous questions/answers when relevant for continuity
        4. Identify trends, patterns, and progress over time
        5. Provide actionable insights and encouragement
        6. If the data doesn't support the question, explain what's missing
        7. Avoid charts, tables, or complex formatting - use natural language only
        8. Keep responses brief enough to fit in a chat bubble

        Workout History Data:
        \(workoutData)

        """

        if !conversationHistory.isEmpty {
            prompt += """

            Previous Conversation:
            \(conversationHistory)

            """
        }

        prompt += """

        Current User Question: "\(question)"

        Provide a concise, helpful answer:
        """

        return prompt
    }

    // MARK: - Helper Methods

    private static func formatWorkoutForPrompt(_ workout: WorkoutSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var formatted = "Workout on \(dateFormatter.string(from: workout.date)):"

        if let name = workout.name {
            formatted += " (Template: \(name))"
        }

        formatted += "\n"

        for exercise in workout.exercises {
            formatted += "  - \(exercise.name): \(exercise.sets) sets × \(exercise.reps) reps"

            if exercise.weight > 0 {
                formatted += " @ \(exercise.weight)lbs"
            }

            if exercise.rpe > 0 {
                formatted += " (RPE \(exercise.rpe))"
            }

            if let notes = exercise.notes, !notes.isEmpty {
                formatted += " - Notes: \(notes)"
            }

            formatted += "\n"
        }

        return formatted
    }

    private static func formatTemplateForPrompt(_ template: WorkoutSession) -> String {
        guard let templateName = template.name else {
            return "Unnamed Template"
        }

        var formatted = "Template: \"\(templateName)\"\nExercises:\n"

        for exercise in template.exercises {
            formatted += "  - \(exercise.name): \(exercise.sets) sets × \(exercise.reps) reps"

            if exercise.weight > 0 {
                formatted += " @ \(Int(exercise.weight))lbs"
            }

            if exercise.rpe > 0 {
                formatted += " (RPE \(exercise.rpe))"
            }

            formatted += "\n"
        }

        return formatted
    }

    // MARK: - Nutrition Parsing Prompt

    static func mealParsingPrompt(input: String, previousMeal: MealSession? = nil, availableTemplates: [MealSession] = []) -> String {
        var prompt = """
        You are a nutrition parser. Convert the user's natural language meal description into structured JSON with estimated nutrition data.

        The user will describe their meal(s) using voice, so the text may be informal and include filler words.

        Expected JSON format for SINGLE meal:
        {
          "meals": [
            {
              "mealType": "breakfast|lunch|dinner|snack",
              "date": "2026-01-05T08:00:00Z",
              "foodItems": [
                {
                  "name": "Food Name",
                  "portionSize": "2 eggs",
                  "calories": 140,
                  "protein": 12,
                  "carbs": 2,
                  "fat": 10,
                  "notes": "optional notes"
                }
              ]
            }
          ]
        }

        Expected JSON format for MULTIPLE meals (bulk logging):
        {
          "meals": [
            {
              "mealType": "breakfast",
              "date": "2026-01-05T08:00:00Z",
              "foodItems": [...]
            },
            {
              "mealType": "lunch",
              "date": "2026-01-05T12:00:00Z",
              "foodItems": [...]
            },
            {
              "mealType": "dinner",
              "date": "2026-01-05T18:00:00Z",
              "foodItems": [...]
            }
          ]
        }

        Rules:
        1. Estimate ALL nutrition values (calories, protein, carbs, fat) based on typical serving sizes
        2. If the user provides specific values (e.g., "200 calories"), use those exact values
        3. For portionSize, extract quantities like "2 eggs", "1 cup", "150g", "1 serving"
        4. Standardize food names (e.g., "eggs" → "Scrambled Eggs", "chicken breast" → "Grilled Chicken Breast")
        5. Infer meal type (breakfast/lunch/dinner/snack) from context or time of day
        6. If meal type can't be determined, omit it or set to null
        7. Be reasonable with estimates - use USDA nutrition data as reference
        8. If the user says "same as last time", use the previous meal data provided below
        9. For notes, capture cooking method, condiments, or other relevant details
        10. CRITICAL: Detect if user is describing MULTIPLE meals (e.g., "breakfast was X, lunch was Y, dinner was Z")
        11. For multiple meals, create separate meal objects with appropriate times:
            - breakfast: 08:00 (8am)
            - lunch: 12:00 (12pm)
            - dinner: 18:00 (6pm)
            - snack: 15:00 (3pm)
        12. Extract date if mentioned (e.g., "on jan 2nd", "yesterday", "this past saturday"). Return in ISO 8601 format. If no date mentioned, set to null.
        13. Current date context: Today is \(Date().formatted(.iso8601)), which is a \(Date().formatted(.dateTime.weekday(.wide))). Use this to calculate relative dates like "yesterday", "last week", or "this past saturday"
        14. Return ONLY valid JSON with "meals" array (even if just one meal), no additional text or explanation

        """

        // Add available templates if any
        if !availableTemplates.isEmpty {
            prompt += """

            Available Meal Templates (you can use these if the user references them by name):

            """

            for template in availableTemplates {
                prompt += formatMealTemplateForPrompt(template) + "\n\n"
            }

            prompt += """
            Template Usage Rules:
            1. If the user references a template by name (e.g., "I had my usual breakfast", "my standard lunch"), start with that template's food items
            2. Template names are case-insensitive and can be referenced partially
            3. If multiple templates match, choose the closest match
            4. If the template name doesn't match, ignore the reference and parse as a normal meal
            5. Apply any modifications the user mentions:
               - "but with 3 eggs instead of 2" → Adjust portion and recalculate nutrition
               - "add a banana" → Add banana with estimated nutrition
               - "skip the toast" → Remove toast from output
            6. Keep all unmodified food items exactly as they are in the template

            """
        }

        if let previous = previousMeal {
            prompt += """

            Previous meal (for "same as last time" reference):
            \(formatMealForPrompt(previous))

            """
        }

        prompt += """

        User input: "\(input)"

        Return the JSON now:
        """

        return prompt
    }

    // MARK: - Nutrition Query Prompt

    static func nutritionQueryPrompt(question: String, meals: [MealSession]) -> String {
        let mealData = meals.map { formatMealForPrompt($0) }.joined(separator: "\n\n")

        return """
        You are a nutrition data analyst. Answer the user's question about their meal history and nutrition.

        You have access to their complete meal history in the format below. Analyze the data and provide a clear, concise answer.

        Guidelines:
        1. Be conversational and friendly
        2. Use specific numbers (calories, macros) and dates when relevant
        3. Identify trends and patterns in eating habits
        4. Provide actionable nutrition insights when appropriate
        5. If the data doesn't support answering the question, say so honestly
        6. Do NOT use charts, tables, or formatted output - just natural language text

        Meal History:
        \(mealData)

        User Question: "\(question)"

        Answer:
        """
    }

    // MARK: - Nutrition Query with Conversation Context

    static func nutritionQueryPromptWithContext(
        question: String,
        meals: [MealSession],
        context: ConversationContext
    ) -> String {
        let mealData = meals.map { formatMealForPrompt($0) }.joined(separator: "\n\n")
        let conversationHistory = context.formatForPrompt()

        var prompt = """
        You are a nutrition data analyst having a conversation with a user about their meal history and nutrition.

        Guidelines:
        1. Be conversational, friendly, and concise (2-3 paragraphs max)
        2. Use specific numbers (calories, protein, carbs, fat) and dates from the data
        3. Reference previous questions/answers when relevant for continuity
        4. Identify trends, patterns, and balance in their nutrition
        5. Provide actionable insights and encouragement
        6. If the data doesn't support the question, explain what's missing
        7. Avoid charts, tables, or complex formatting - use natural language only
        8. Keep responses brief enough to fit in a chat bubble

        Meal History Data:
        \(mealData)

        """

        if !conversationHistory.isEmpty {
            prompt += """

            Previous Conversation:
            \(conversationHistory)

            """
        }

        prompt += """

        Current User Question: "\(question)"

        Provide a concise, helpful answer:
        """

        return prompt
    }

    // MARK: - Nutrition Helper Methods

    private static func formatMealForPrompt(_ meal: MealSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var formatted = "Meal on \(dateFormatter.string(from: meal.date)):"

        if let mealType = meal.mealType {
            formatted += " (\(mealType.capitalized))"
        }

        if let name = meal.name {
            formatted += " [Template: \(name)]"
        }

        formatted += "\n"

        for foodItem in meal.foodItems {
            formatted += "  - \(foodItem.name)"

            if let portion = foodItem.portionSize {
                formatted += " (\(portion))"
            }

            formatted += ":"

            if let cals = foodItem.calories {
                formatted += " \(Int(cals))cal"
            }

            if let protein = foodItem.protein {
                formatted += ", \(Int(protein))g protein"
            }

            if let carbs = foodItem.carbs {
                formatted += ", \(Int(carbs))g carbs"
            }

            if let fat = foodItem.fat {
                formatted += ", \(Int(fat))g fat"
            }

            if let notes = foodItem.notes, !notes.isEmpty {
                formatted += " - Notes: \(notes)"
            }

            formatted += "\n"
        }

        // Add totals
        formatted += "  Total: \(Int(meal.totalCalories))cal, \(Int(meal.totalProtein))g protein, \(Int(meal.totalCarbs))g carbs, \(Int(meal.totalFat))g fat\n"

        return formatted
    }

    private static func formatMealTemplateForPrompt(_ template: MealSession) -> String {
        guard let templateName = template.name else {
            return "Unnamed Template"
        }

        var formatted = "Template: \"\(templateName)\""

        if let mealType = template.mealType {
            formatted += " (\(mealType.capitalized))"
        }

        formatted += "\nFood Items:\n"

        for foodItem in template.foodItems {
            formatted += "  - \(foodItem.name)"

            if let portion = foodItem.portionSize {
                formatted += " (\(portion))"
            }

            if let cals = foodItem.calories {
                formatted += ": \(Int(cals))cal"
            }

            if let protein = foodItem.protein {
                formatted += ", \(Int(protein))g protein"
            }

            if let carbs = foodItem.carbs {
                formatted += ", \(Int(carbs))g carbs"
            }

            if let fat = foodItem.fat {
                formatted += ", \(Int(fat))g fat"
            }

            formatted += "\n"
        }

        return formatted
    }
}
