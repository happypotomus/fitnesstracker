//
//  ReviewWorkoutsView.swift
//  FitnessTracker
//
//  Chat interface for querying workout history with AI
//

import SwiftUI

struct ReviewWorkoutsView: View {
    @StateObject private var viewModel = ReviewWorkoutsViewModel()
    @State private var showVoiceInput = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Example questions (always visible)
                ExampleQuestionsView(
                    questions: viewModel.exampleQuestions,
                    onQuestionTapped: { question in
                        Task {
                            await viewModel.sendQuestion(question)
                        }
                    }
                )

                Divider()

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if viewModel.isProcessing {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        // Auto-scroll to latest message
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isProcessing) { isProcessing in
                        // Auto-scroll to typing indicator
                        if isProcessing {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input area
                ChatInputView(
                    text: $viewModel.inputText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: {
                        Task {
                            await viewModel.sendQuestion(viewModel.inputText)
                        }
                    },
                    onVoiceButtonTapped: {
                        isTextFieldFocused = false
                        showVoiceInput = true
                    },
                    isProcessing: viewModel.isProcessing
                )
            }
            .navigationTitle("Review Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.startNewConversation()
                    }) {
                        Label("New Conversation", systemImage: "plus.message")
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputSheet { transcription in
                    viewModel.handleVoiceInput(transcription)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    ReviewWorkoutsView()
}
