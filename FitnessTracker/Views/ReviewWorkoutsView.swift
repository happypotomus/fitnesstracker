//
//  ReviewWorkoutsView.swift
//  FitnessTracker
//
//  Calendar view for reviewing workout history with floating chat
//

import SwiftUI

struct ReviewWorkoutsView: View {
    @StateObject private var viewModel = ReviewWorkoutsViewModel()
    @StateObject private var calendarViewModel = CalendarViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showChat: Bool = false
    @State private var workoutToEdit: WorkoutSession?
    @State private var refreshTrigger: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Calendar at top
                    CalendarView(viewModel: calendarViewModel, accentColor: .blue)
                        .background(Color(.systemBackground))

                    Divider()

                    // Workout list below
                    ScrollView {
                        if let selectedDate = calendarViewModel.selectedDate {
                            let workouts = viewModel.fetchWorkouts(for: selectedDate)
                            WorkoutDayListView(
                                workouts: workouts,
                                selectedDate: selectedDate,
                                onEdit: { workout in
                                    workoutToEdit = workout
                                },
                                onDelete: { workout in
                                    if viewModel.deleteWorkout(workout) {
                                        refreshTrigger.toggle()
                                        updateCalendarHighlights()
                                    }
                                }
                            )
                            .padding(.top)
                        } else {
                            // No date selected
                            VStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)

                                Text("Select a date to view workouts")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                }

                // Floating chat button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingChatButton(accentColor: .blue) {
                            showChat = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
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
                    Button {
                        calendarViewModel.goToToday()
                    } label: {
                        Text("Today")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showChat) {
                ReviewWorkoutsChatView(viewModel: viewModel)
            }
            .sheet(item: $workoutToEdit) { workout in
                WorkoutConfirmationView(workout: workout, isEditMode: true) {
                    workoutToEdit = nil
                    refreshTrigger.toggle()
                    updateCalendarHighlights()
                }
            }
            .onAppear {
                updateCalendarHighlights()
            }
            .onChange(of: calendarViewModel.currentMonth) { _ in
                updateCalendarHighlights()
            }
            .onChange(of: refreshTrigger) { _ in
                // Trigger refresh
            }
        }
    }

    private func updateCalendarHighlights() {
        let dates = viewModel.getDatesWithWorkouts(in: calendarViewModel.currentMonth)
        calendarViewModel.updateDatesWithData(dates)
    }
}

// MARK: - Review Workouts Chat View

struct ReviewWorkoutsChatView: View {
    @ObservedObject var viewModel: ReviewWorkoutsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var showVoiceInput: Bool = false

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
                .padding(.top, 8)

                // Chat messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 12) {
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
                        .padding()
                        .padding(.bottom, 100)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isProcessing) { isProcessing in
                        if isProcessing {
                            withAnimation {
                                scrollProxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

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
                        showVoiceInput = true
                    },
                    isProcessing: viewModel.isProcessing
                )
            }
            .navigationTitle("Ask About Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.startNewConversation()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("New")
                        }
                        .font(.subheadline)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputSheet { transcription in
                    showVoiceInput = false
                    Task {
                        await viewModel.sendQuestion(transcription)
                    }
                }
            }
        }
    }
}
