//
//  VoiceInputSheet.swift
//  FitnessTracker
//
//  Sheet for recording voice input for chat queries
//

import SwiftUI

struct VoiceInputSheet: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @Environment(\.dismiss) private var dismiss
    let onTranscriptionComplete: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Transcription display
                if !speechRecognizer.transcription.isEmpty {
                    ScrollView {
                        Text(speechRecognizer.transcription)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxHeight: 200)
                    .padding(.horizontal)
                } else {
                    Text("Tap the microphone and ask your question")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Voice recording button
                VoiceRecordButton(speechRecognizer: speechRecognizer)
                    .padding()

                // Done button (only show when there's transcription)
                if !speechRecognizer.transcription.isEmpty {
                    Button(action: {
                        onTranscriptionComplete(speechRecognizer.transcription)
                        dismiss()
                    }) {
                        Text("Use This Question")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }

                Spacer()
            }
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VoiceInputSheet { transcription in
        print("Transcription: \(transcription)")
    }
}
