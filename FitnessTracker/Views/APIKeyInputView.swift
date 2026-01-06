//
//  APIKeyInputView.swift
//  FitnessTracker
//
//  Screen for entering OpenAI API key on first launch
//

import SwiftUI

struct APIKeyInputView: View {
    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @State private var errorMessage: String = ""
    @State private var isKeyValid: Bool = false

    var onKeySaved: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon/title
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("FitnessTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Voice-first workout logging")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)

            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Setup Required")
                    .font(.headline)

                Text("This app uses OpenAI to parse your voice workout descriptions. You'll need an API key to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // API Key Input
            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    if showKey {
                        TextField("sk-proj-...", text: $apiKey)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: apiKey) { _, newValue in
                                validateKey(newValue)
                            }
                    } else {
                        SecureField("sk-proj-...", text: $apiKey)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: apiKey) { _, newValue in
                                validateKey(newValue)
                            }
                    }

                    Button(action: {
                        showKey.toggle()
                    }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("Your API key is stored securely on your device and never leaves your phone except to make OpenAI requests.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Cost estimate
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Estimated cost: $0.01 - $0.05 per workout")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Link("Get API key from OpenAI →", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Save button
            Button(action: saveAPIKey) {
                Text("Save & Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isKeyValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isKeyValid)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private func validateKey(_ key: String) {
        errorMessage = ""

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedKey.isEmpty {
            isKeyValid = false
            return
        }

        if !KeychainManager.isValidAPIKeyFormat(trimmedKey) {
            errorMessage = "Invalid key format. OpenAI keys start with 'sk-' or 'sk_'."
            isKeyValid = false
            return
        }

        isKeyValid = true
    }

    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard KeychainManager.isValidAPIKeyFormat(trimmedKey) else {
            errorMessage = "Invalid API key format"
            return
        }

        let success = KeychainManager.shared.saveAPIKey(trimmedKey)

        if success {
            onKeySaved()
        } else {
            errorMessage = "Failed to save API key. Please try again."
        }
    }
}

#Preview {
    APIKeyInputView(onKeySaved: {
        print("Key saved!")
    })
}
