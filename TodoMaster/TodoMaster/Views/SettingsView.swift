import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var showingThemePicker = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var iCloudSync = true
    @State private var notificationsEnabled = true
    @State private var defaultReminderTime = Date()
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("iCloud Sync")) {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                        Text("iCloud Sync")
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Last synced")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.syncWithCloud()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                    }
                    .disabled(viewModel.isSyncing)
                }
                
                Section(header: Text("Appearance")) {
                    Button(action: { showingThemePicker = true }) {
                        HStack {
                            Text("Theme")
                            Spacer()
                            Text(viewModel.currentTheme.name)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    DatePicker("Default Reminder Time", selection: $defaultReminderTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Sync")) {
                    Toggle("iCloud Sync", isOn: $iCloudSync)
                        .onChange(of: iCloudSync) { newValue in
                            if newValue {
                                Task {
                                    await viewModel.syncWithCloud()
                                }
                            }
                        }
                }
                
                Section(header: Text("Data")) {
                    Button(action: { showingExportSheet = true }) {
                        Text("Export Data")
                    }
                    
                    Button(action: { showingImportSheet = true }) {
                        Text("Import Data")
                    }
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        Text("Delete All Data")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .formStyle(.grouped)
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView()
        }
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAllData()
            }
        } message: {
            Text("Are you sure you want to delete all data? This action cannot be undone.")
        }
    }
    
    public init() { }
}

public struct ThemePickerView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationView {
            List(Theme.allCases, id: \.self) { theme in
                Button(action: {
                    viewModel.currentTheme = theme
                    dismiss()
                }) {
                    HStack {
                        Text(theme.name)
                        Spacer()
                        if theme == viewModel.currentTheme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Choose Theme")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    public init() { }
}

public struct ExportView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    
    public var body: some View {
        NavigationView {
            VStack {
                Text("Export your todos as a JSON file")
                    .padding()
                
                Button("Export") {
                    showingDocumentPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Export Data")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(isExporting: true)
            }
        }
    }
}

public struct ImportView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    
    public var body: some View {
        NavigationView {
            VStack {
                Text("Import todos from a JSON file")
                    .padding()
                
                Button("Import") {
                    showingDocumentPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Import Data")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(isExporting: false)
            }
        }
    }
}

public struct DocumentPicker: UIViewControllerRepresentable {
    let isExporting: Bool
    @EnvironmentObject private var viewModel: TodoViewModel
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        if isExporting {
            // Create temporary file with todos data
            let todos = viewModel.todos
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            do {
                let data = try encoder.encode(todos)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("todos.json")
                try data.write(to: tempURL)
                picker = UIDocumentPickerViewController(forExporting: [tempURL])
            } catch {
                print("Error creating export file: \(error)")
                picker = UIDocumentPickerViewController(forExporting: [])
            }
        } else {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, isExporting: isExporting)
    }
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let viewModel: TodoViewModel
        let isExporting: Bool
        
        init(viewModel: TodoViewModel, isExporting: Bool) {
            self.viewModel = viewModel
            self.isExporting = isExporting
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard !urls.isEmpty else { return }
            
            if isExporting {
                // Export is handled by the picker itself
                return
            }
            
            // Handle import
            let url = urls[0]
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource")
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let importedTodos = try decoder.decode([Todo].self, from: data)
                
                // Add imported todos to the view model
                DispatchQueue.main.async {
                    for todo in importedTodos {
                        self.viewModel.addTodo(todo)
                    }
                }
            } catch {
                print("Error importing todos: \(error)")
            }
        }
    }
} 
