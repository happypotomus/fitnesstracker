//
//  ChatInputView.swift
//  FitnessTracker
//
//  Input area with text field, voice button, and send button
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    let onVoiceButtonTapped: () -> Void
    let isProcessing: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Voice button
            Button(action: onVoiceButtonTapped) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .disabled(isProcessing)

            // Text field
            TextField("Ask about your workouts...", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isTextFieldFocused)
                .disabled(isProcessing)
                .onSubmit {
                    onSend()
                }

            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                ChatInputView(
                    text: $text,
                    isTextFieldFocused: $isFocused,
                    onSend: { print("Send tapped") },
                    onVoiceButtonTapped: { print("Voice tapped") },
                    isProcessing: false
                )
            }
        }
    }

    return PreviewWrapper()
}
