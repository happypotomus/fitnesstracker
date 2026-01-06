//
//  VoiceRecordButton.swift
//  FitnessTracker
//
//  Reusable voice recording button with visual feedback
//

import SwiftUI

struct VoiceRecordButton: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer

    var onTranscriptionComplete: ((String) -> Void)?

    @State private var isPulsing: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Microphone button with pulsing animation
            Button(action: toggleRecording) {
                ZStack {
                    // Pulsing circle background (when recording)
                    if speechRecognizer.isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                            .opacity(isPulsing ? 0 : 1)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                    }

                    // Main button circle
                    Circle()
                        .fill(speechRecognizer.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                        .shadow(color: speechRecognizer.isRecording ? .red.opacity(0.4) : .blue.opacity(0.4), radius: 10)

                    // Microphone icon
                    Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                if speechRecognizer.isRecording {
                    isPulsing = true
                }
            }
            .onChange(of: speechRecognizer.isRecording) { _, isRecording in
                isPulsing = isRecording
            }

            // Status text
            Text(speechRecognizer.isRecording ? "Listening..." : "Tap to speak")
                .font(.subheadline)
                .foregroundColor(speechRecognizer.isRecording ? .red : .secondary)
                .fontWeight(speechRecognizer.isRecording ? .semibold : .regular)

            // Live transcription
            if !speechRecognizer.transcription.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "text.quote")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Transcription:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(speechRecognizer.transcription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut, value: speechRecognizer.transcription)
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            // Stop recording
            speechRecognizer.stopRecording()

            // Call completion handler with final transcription
            let finalTranscription = speechRecognizer.transcription
            if !finalTranscription.isEmpty {
                onTranscriptionComplete?(finalTranscription)
            }
        } else {
            // Start recording
            do {
                try speechRecognizer.startRecording()
            } catch {
                print("❌ Failed to start recording: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    VoiceRecordButton(
        speechRecognizer: SpeechRecognizer(),
        onTranscriptionComplete: { transcription in
            print("Completed: \(transcription)")
        }
    )
}
