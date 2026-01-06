//
//  ExampleQuestionsView.swift
//  FitnessTracker
//
//  Example question chips that user can tap to immediately ask
//

import SwiftUI

struct ExampleQuestionsView: View {
    let questions: [String]
    let onQuestionTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Example questions:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(questions, id: \.self) { question in
                        Button(action: {
                            onQuestionTapped(question)
                        }) {
                            Text(question)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ExampleQuestionsView(
        questions: [
            "What exercises did I do most last month?",
            "Show me my bench press progress",
            "How many workouts this week?",
            "What was my heaviest squat?"
        ],
        onQuestionTapped: { question in
            print("Tapped: \(question)")
        }
    )
}
