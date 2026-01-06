//
//  SpeechRecognizer.swift
//  FitnessTracker
//
//  Service for speech recognition using Apple Speech framework
//

import Foundation
import Speech
import AVFoundation
import Combine

enum SpeechRecognitionError: Error, LocalizedError {
    case notAuthorized
    case notAvailable
    case audioEngineError
    case recognitionError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable it in Settings."
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .audioEngineError:
            return "Failed to start audio recording."
        case .recognitionError(let message):
            return "Recognition error: \(message)"
        }
    }
}

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcription: String = ""
    @Published var isRecording: Bool = false
    @Published var isAuthorized: Bool = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        Task {
            await checkAuthorization()
        }
    }

    // MARK: - Authorization

    func checkAuthorization() async {
        let status = SFSpeechRecognizer.authorizationStatus()

        switch status {
        case .authorized:
            isAuthorized = true
            print("✅ Speech recognition authorized")
        case .notDetermined:
            // Request authorization
            let authorized = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            isAuthorized = authorized
            print(authorized ? "✅ Speech recognition authorized" : "❌ Speech recognition denied")
        case .denied, .restricted:
            isAuthorized = false
            print("❌ Speech recognition not authorized")
        @unknown default:
            isAuthorized = false
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        // Cancel any ongoing recognition task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        // Check authorization
        guard isAuthorized else {
            throw SpeechRecognitionError.notAuthorized
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.notAvailable
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.audioEngineError
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.transcription = result.bestTranscription.formattedString
                    print("📝 Transcription: \(self.transcription)")
                }
            }

            if let error = error {
                print("❌ Recognition error: \(error.localizedDescription)")
                Task { @MainActor in
                    self.stopRecording()
                }
            }

            // Check if recognition is finished
            if result?.isFinal == true {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }

        isRecording = true
        print("🎤 Recording started")
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
        print("⏹️ Recording stopped")
    }

    // MARK: - Reset

    func reset() {
        transcription = ""
        stopRecording()
    }

    // MARK: - Get Final Transcription

    func getFinalTranscription() -> String {
        let final = transcription
        reset()
        return final
    }
}
