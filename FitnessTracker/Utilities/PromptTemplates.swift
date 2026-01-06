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

        Expected JSON format:
        {
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

        Rules:
        1. Extract exercise names, sets, reps, weight, and RPE (Rate of Perceived Exertion, 1-10 scale)
        2. If RPE is not mentioned, omit it or set to null
        3. If weight is not mentioned, assume 0.0 (bodyweight)
        4. Standardize exercise names (e.g., "benching" → "Bench Press", "pullups" → "Pull-ups")
        5. If the user says "same as last time", use the previous workout data provided below
        6. Infer reasonable values when data is incomplete
        7. For notes, capture any relevant comments about form, difficulty, or how it felt
        8. Return ONLY valid JSON, no additional text or explanation

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
            5. Apply any modifications the user mentions:
               - "add 5 pounds to bench press" → Increase bench press weight by 5
               - "but do 12 reps instead" → Change reps to 12 for specified exercise
               - "skip overhead press" → Remove overhead press from output
            6. If the user wants to add exercises, append them to the template exercises
            7. If the user wants to remove exercises, exclude them from the output
            8. Keep all unmodified exercises exactly as they are in the template

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
}
