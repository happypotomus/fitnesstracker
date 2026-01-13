//
//  SettingsView.swift
//  FitnessTracker
//
//  Settings screen with backup/restore functionality
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showExportShare: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var exportURL: URL?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    private let backupService = BackupService()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Backup")) {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export All Data")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }

                    Text("Save all your workouts, meals, and templates to a file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Data Restore")) {
                    Button(action: {
                        showImportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                            Text("Import Data")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }

                    Text("Restore from a previously exported backup file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Export

    private func exportData() {
        guard let url = backupService.exportAllData() else {
            alertTitle = "Export Failed"
            alertMessage = "Failed to create backup file. Please try again."
            showAlert = true
            return
        }

        exportURL = url
        showExportShare = true
    }

    // MARK: - Import

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Access security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Import Failed"
                alertMessage = "Unable to access the selected file."
                showAlert = true
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            let (success, workoutCount, mealCount) = backupService.importData(from: url)

            if success {
                alertTitle = "Import Successful"
                alertMessage = "Imported \(workoutCount) workouts and \(mealCount) meals successfully!"
                showAlert = true
            } else {
                alertTitle = "Import Failed"
                alertMessage = "Failed to import data. Please check the file and try again."
                showAlert = true
            }

        case .failure(let error):
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
