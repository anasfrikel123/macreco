import Foundation
import SwiftUI
import UserNotifications
import Speech
import EventKit
import Intents
import IntentsUI
import NaturalLanguage
import CoreML
import CoreLocation
import HealthKit
import CloudKit

@MainActor
public class TodoViewModel: NSObject, ObservableObject {
    @Published public var todos: [Todo] = []
    @Published public var categories: [Todo.Category] = []
    @Published public var tags: [Todo.Tag] = []
    @Published public var currentTheme: Theme = .system
    @Published public var statistics = Statistics()
    @Published public var isSyncing = false
    @Published public var lastSyncDate: Date?
    @Published public var editingCategory: Todo.Category?
    @Published public var showingAddCategory = false
    @Published public var showingAddTodo = false
    @Published public var isListening = false
    @Published public var voiceCommandFeedback = ""
    @Published public var syncError: Error?
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let saveKey = "SavedTodos"
    private let categoriesKey = "SavedCategories"
    private let tagsKey = "SavedTags"
    private let themeKey = "CurrentTheme"
    private let statsKey = "Statistics"
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let eventStore = EKEventStore()
    private var calendarAccessGranted = false
    
    // MARK: - AI Integration
    private lazy var aiService: AIService = {
        return AIService(viewModel: self)
    }()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    // MARK: - Initialization
    override public init() {
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        super.init()
        
        // Initialize properties
        self.todos = []
        self.categories = []
        self.tags = []
        self.currentTheme = .system
        self.statistics = Statistics()
        self.isSyncing = false
        self.lastSyncDate = nil
        self.editingCategory = nil
        self.showingAddCategory = false
        self.showingAddTodo = false
        self.isListening = false
        self.voiceCommandFeedback = ""
        
        // Load saved data
        loadSavedData()
        
        // Setup other features
        setupNotifications()
        
        // Request calendar access
        requestCalendarAccess()
        
        // Setup Cloud Sync
        setupCloudSync()
    }
    
    private func setupCloudSync() {
        Task {
            do {
                let status = try await container.accountStatus()
                if status == .available {
                    await syncWithCloud()
                }
            } catch {
                print("iCloud account status error: \(error)")
            }
        }
    }
    
    private func loadSavedData() {
        // Load todos
        if let data = userDefaults.data(forKey: saveKey),
           let decoded = try? decoder.decode([Todo].self, from: data) {
            self.todos = decoded
        }
        
        // Load categories
        if let data = userDefaults.data(forKey: categoriesKey),
           let decoded = try? decoder.decode([Todo.Category].self, from: data) {
            self.categories = decoded
        }
        
        // Load tags
        if let data = userDefaults.data(forKey: tagsKey),
           let decoded = try? decoder.decode([Todo.Tag].self, from: data) {
            self.tags = decoded
        }
        
        // Load theme
        if let data = userDefaults.data(forKey: themeKey),
           let decoded = try? decoder.decode(Theme.self, from: data) {
            self.currentTheme = decoded
        }
        
        // Load statistics
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? decoder.decode(Statistics.self, from: data) {
            self.statistics = decoded
        }
        
        // Update statistics after loading todos
        updateStatistics()
    }
    
    // MARK: - Todo Management
    public func addTodo(_ todo: Todo) {
        todos.append(todo)
        saveTodos()
        updateStatistics()
        scheduleNotification(for: todo)
        addToCalendar(todo)
        
        Task {
            await syncWithCloud()
        }
    }
    
    @MainActor
    func toggleTodoCompletion(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
            updateStatistics()
        }
    }
    
    @MainActor
    func togglePin(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isPinned.toggle()
            saveTodos()
        }
    }
    
    @MainActor
    func deleteTodo(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
        updateStatistics()
        cancelNotifications(for: [todo])
        removeFromCalendar(todo)
        
        Task {
            do {
                let recordID = CKRecord.ID(recordName: todo.id.uuidString)
                try await database.deleteRecord(withID: recordID)
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
    
    public func updateTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            removeFromCalendar(todos[index])
            
            todos[index] = todo
            saveTodos()
            updateStatistics()
            scheduleNotification(for: todo)
            
            addToCalendar(todo)
            
            Task {
                await syncWithCloud()
    }
        }
    }
    
    // MARK: - Category Management
    public func addCategory(name: String, colorHex: String, icon: String) {
        let category = Todo.Category(name: name, colorHex: colorHex, icon: icon)
        categories.append(category)
        saveCategories()
    }
    
    public func updateCategory(_ category: Todo.Category, name: String, colorHex: String, icon: String) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = Todo.Category(id: category.id, name: name, colorHex: colorHex, icon: icon)
            saveCategories()
        }
    }
    
    public func deleteCategories(at indexSet: IndexSet) {
        categories.remove(atOffsets: indexSet)
        saveCategories()
    }
    
    // MARK: - Tag Management
    public func addTag(_ tag: Todo.Tag) {
        tags.append(tag)
        saveTags()
    }
    
    public func deleteTag(_ tag: Todo.Tag) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags.remove(at: index)
            saveTags()
        }
    }
    
    func addTag(to todo: Todo, tag: Todo.Tag) {
        if !todo.tags.contains(where: { $0.id == tag.id }) {
            todo.tags.append(tag)
            saveTodos()
        }
    }
    
    func removeTag(from todo: Todo, tag: Todo.Tag) {
        todo.tags.removeAll { $0.id == tag.id }
        saveTodos()
    }
    
    func addTagByName(to todo: Todo, tagName: String) {
        if let existingTag = tags.first(where: { $0.name == tagName }) {
            addTag(to: todo, tag: existingTag)
        } else {
            let newTag = Todo.Tag(name: tagName, color: "#000000") // Default black color
            addTag(to: todo, tag: newTag)
        }
    }
    
    // MARK: - Filtering and Sorting
    public func filterTodos(by priority: Todo.Priority? = nil,
                    category: Todo.Category? = nil,
                    tag: Todo.Tag? = nil,
                    isCompleted: Bool? = nil) -> [Todo] {
        return todos.filter { todo in
            var matches = true
            if let priority = priority {
                matches = matches && todo.priority == priority
            }
            if let category = category {
                matches = matches && todo.category?.id == category.id
            }
            if let tag = tag {
                matches = matches && todo.tags.contains { $0.id == tag.id }
            }
            if let isCompleted = isCompleted {
                matches = matches && todo.isCompleted == isCompleted
            }
            return matches
        }
    }
    
    public func sortTodos(by criteria: SortCriteria) -> [Todo] {
        return todos.sorted { todo1, todo2 in
            switch criteria {
            case .dueDate:
                return (todo1.dueDate ?? .distantFuture) < (todo2.dueDate ?? .distantFuture)
            case .priority:
                return todo1.priority.rawValue > todo2.priority.rawValue
            case .creationDate:
                return todo1.createdAt > todo2.createdAt
            case .title:
                return todo1.title < todo2.title
            }
        }
    }
    
    public enum SortCriteria {
        case dueDate, priority, creationDate, title
    }
    
    // MARK: - Theme Management
    public func setTheme(_ theme: Theme) {
        currentTheme = theme
    }
    
    // MARK: - Statistics Management
    public func updateStatistics() {
        statistics.updateStats(todos: todos)
        saveStatistics()
    }
    
    // MARK: - Data Persistence
    public func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }
    
    private func saveTags() {
        if let encoded = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(encoded, forKey: tagsKey)
        }
    }
    
    private func saveTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(encoded, forKey: themeKey)
        }
    }
    
    public func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }
    
    // MARK: - iCloud Sync
    public func syncWithCloud() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { 
            isSyncing = false
            lastSyncDate = Date()
        }
        
        do {
            try await performCloudSync()
        } catch {
            print("Sync error: \(error)")
            // Optionally notify the user about the sync error
            await MainActor.run {
                // You can set a published property here to show an error alert
                syncError = error
            }
        }
    }
    
    private func performCloudSync() async throws {
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        // Upload local changes
        let localTodos = todos
        var records: [CKRecord] = []
        
        for todo in localTodos {
            let record = CKRecord(recordType: "Todo")
            record.setValue(todo.id.uuidString, forKey: "id")
            record.setValue(todo.title, forKey: "title")
            record.setValue(todo.notes, forKey: "notes")
            record.setValue(todo.isCompleted, forKey: "isCompleted")
            record.setValue(todo.priority.rawValue, forKey: "priority")
            record.setValue(todo.dueDate, forKey: "dueDate")
            record.setValue(todo.category?.name, forKey: "category")
            record.setValue(todo.tags.map { $0.name }, forKey: "tags")
            record.setValue(todo.updatedAt, forKey: "lastModified")
            records.append(record)
        }
        
        // Save records in batches of 100
        let batchSize = 100
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let end = min(i + batchSize, records.count)
            let batch = Array(records[i..<end])
            let operation = CKModifyRecordsOperation(recordsToSave: batch)
            operation.savePolicy = .changedKeys
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success(_):
                        continuation.resume(returning: ())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                database.add(operation)
            }
        }
        
        // Fetch remote changes
        let query = CKQuery(recordType: "Todo", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        let remoteTodos = results.compactMap { result -> Todo? in
            guard let record = try? result.1.get() else { return nil }
            
            guard let idString = record["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = record["title"] as? String,
                  let lastModified = record["lastModified"] as? Date else {
                return nil
            }
            
            let notes = record["notes"] as? String ?? ""
            let isCompleted = record["isCompleted"] as? Bool ?? false
            let priorityRaw = record["priority"] as? Int ?? 0
            let priority = Todo.Priority(rawValue: priorityRaw) ?? .medium
            let dueDate = record["dueDate"] as? Date
            let categoryName = record["category"] as? String
            let tagNames = record["tags"] as? [String] ?? []
            
            let category = categoryName.map { name in
                if let existingCategory = categories.first(where: { $0.name == name }) {
                    return existingCategory
                } else {
                    let newCategory = Todo.Category(name: name, colorHex: "#000000", icon: "folder")
                    categories.append(newCategory)
                    return newCategory
                }
            }
            
            let todoTags = tagNames.map { name in
                if let existingTag = self.tags.first(where: { $0.name == name }) {
                    return existingTag
                } else {
                    let newTag = Todo.Tag(name: name, color: "#000000")
                    self.tags.append(newTag)
                    return newTag
                }
            }
            
            return Todo(id: id,
                       title: title,
                       notes: notes,
                       isCompleted: isCompleted,
                       dueDate: dueDate,
                       priority: priority,
                       category: category,
                       tags: todoTags,
                       createdAt: lastModified,
                       updatedAt: lastModified,
                       reminderDate: nil,
                       isPinned: false,
                       estimatedTime: nil,
                       attachments: [])
        }
        
        // Merge changes on the main actor
        await MainActor.run {
            var updatedTodos = todos
            for remoteTodo in remoteTodos {
                if let index = updatedTodos.firstIndex(where: { $0.id == remoteTodo.id }) {
                    // Update existing todo if remote version is newer
                    if remoteTodo.updatedAt > updatedTodos[index].updatedAt {
                        updatedTodos[index] = remoteTodo
                    }
                } else {
                    // Add new todo
                    updatedTodos.append(remoteTodo)
                }
            }
            todos = updatedTodos
            
            // Save merged changes
            saveTodos()
            updateStatistics()
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        // Implement your notification setup logic here
    }
    
    private func scheduleNotification(for todo: Todo) {
        guard let reminderDate = todo.reminderDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Todo Reminder"
        content.body = todo.title
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications(for todos: [Todo]) {
        let identifiers = todos.map { $0.id.uuidString }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Data Export/Import
    public func exportData() -> Data? {
        try? JSONEncoder().encode(ExportData(
            todos: todos,
            categories: categories,
            tags: tags,
            statistics: statistics
        ))
    }
    
    public func importData(_ data: Data) throws {
        let imported = try JSONDecoder().decode(ExportData.self, from: data)
        todos = imported.todos
        categories = imported.categories
        tags = imported.tags
        statistics = imported.statistics
        saveTodos()
        saveCategories()
        saveTags()
        saveStatistics()
    }
    
    public func deleteAllData() {
        todos.removeAll()
        categories.removeAll()
        tags.removeAll()
        statistics = Statistics()
        
        UserDefaults.standard.removeObject(forKey: saveKey)
        UserDefaults.standard.removeObject(forKey: categoriesKey)
        UserDefaults.standard.removeObject(forKey: tagsKey)
        UserDefaults.standard.removeObject(forKey: statsKey)
    }
    
    // MARK: - Voice Commands
    public func startVoiceCommand() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.startRecording()
                case .denied:
                    self.voiceCommandFeedback = "Speech recognition permission denied"
                case .restricted:
                    self.voiceCommandFeedback = "Speech recognition not available on this device"
                case .notDetermined:
                    self.voiceCommandFeedback = "Speech recognition not yet authorized"
                @unknown default:
                    self.voiceCommandFeedback = "Speech recognition not available"
                }
            }
        }
    }
    
    public func stopVoiceCommand() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }
    
    private func startRecording() {
        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            voiceCommandFeedback = "Failed to set up audio session"
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            voiceCommandFeedback = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let command = result.bestTranscription.formattedString.lowercased()
                Task {
                    await self.processVoiceCommand(command)
                }
            }
            
            if error != nil {
                self.stopVoiceCommand()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isListening = true
            voiceCommandFeedback = "Listening..."
        } catch {
            voiceCommandFeedback = "Failed to start audio engine"
            return
        }
    }
    
    // MARK: - Alert Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    @MainActor
    func processVoiceCommand(_ command: String) async {
        // Convert command to lowercase for easier matching
        let lowercasedCommand = command.lowercased()
        
        // Define command patterns
        let addPatterns = [
            "add (?:task|todo) (.+)",
            "create (?:task|todo) (.+)",
            "new (?:task|todo) (.+)",
            "remind me (.+)",
            "remind me to (.+)",
            "remind me tomorrow to (.+)",
            "set (?:task|todo) (.+)",
            "make (?:task|todo) (.+)",
            "schedule (?:task|todo) (.+)",
            "put (?:task|todo) (.+)"
        ]
        
        // Check if command matches any pattern
        var todoTitle: String?
        var dueDate: Date?
        
        for pattern in addPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercasedCommand, options: [], range: NSRange(lowercasedCommand.startIndex..., in: lowercasedCommand)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: lowercasedCommand) {
                    todoTitle = String(lowercasedCommand[swiftRange])
                    
                    // Check for time-related keywords
                    if lowercasedCommand.contains("tomorrow") {
                        dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                    } else if lowercasedCommand.contains("next week") {
                        dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                    } else if lowercasedCommand.contains("next month") {
                        dueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                    }
                    break
                }
            }
        }
        
        guard let title = todoTitle else {
            // If no pattern matched, show error
            showAlert(title: "Invalid Command", message: "Please use a valid command format like 'add task [title]' or 'remind me to [task]'")
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Confirm Todo",
            message: "Do you want to add this todo?\nTitle: \(title)\(dueDate != nil ? "\nDue: \(dueDate!.formatted())" : "")",
            preferredStyle: .alert
        )
        
        // Add action
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Create the todo
            let todo = Todo(
                id: UUID(),
                title: title,
                notes: "",
                isCompleted: false,
                dueDate: dueDate,
                priority: .medium,
                category: self.categories.first(where: { $0.name == "Personal" }),
                tags: [],
                createdAt: Date(),
                updatedAt: Date(),
                reminderDate: nil,
                isPinned: false,
                estimatedTime: nil,
                attachments: []
            )
            
            self.todos.append(todo)
            self.saveTodos()
        })
        
        // Modify action
        alert.addAction(UIAlertAction(title: "Modify", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Show modification alert
            let modifyAlert = UIAlertController(
                title: "Modify Todo",
                message: "Edit the todo details",
                preferredStyle: .alert
            )
            
            modifyAlert.addTextField { textField in
                textField.text = title
                textField.placeholder = "Todo title"
            }
            
            modifyAlert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let self = self,
                      let modifiedTitle = modifyAlert.textFields?.first?.text,
                      !modifiedTitle.isEmpty else { return }
                
                // Create the todo with modified title
                let todo = Todo(
                    id: UUID(),
                    title: modifiedTitle,
                    notes: "",
                    isCompleted: false,
                    dueDate: dueDate,
                    priority: .medium,
                    category: self.categories.first(where: { $0.name == "Personal" }),
                    tags: [],
                    createdAt: Date(),
                    updatedAt: Date(),
                    reminderDate: nil,
                    isPinned: false,
                    estimatedTime: nil,
                    attachments: []
                )
                
                self.todos.append(todo)
                self.saveTodos()
            })
            
            modifyAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Present the modify alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(modifyAlert, animated: true)
            }
        })
        
        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Calendar Integration
    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.calendarAccessGranted = granted
                if !granted {
                    print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func addToCalendar(_ todo: Todo) {
        guard calendarAccessGranted else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = todo.title
        event.notes = todo.notes
        
        // Set event time
        if let dueDate = todo.dueDate {
            event.startDate = dueDate
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: dueDate) ?? dueDate
        } else {
            let now = Date()
            event.startDate = now
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        }
        
        // Set priority
        switch todo.priority {
        case .high:
            event.title = "❗️❗️❗️ " + event.title
        case .medium:
            event.title = "❗️❗️ " + event.title
        case .low:
            event.title = "❗️ " + event.title
        case .none:
            break
        }
        
        // Set category as calendar
        if let category = todo.category?.name {
            event.title = "[\(category)] " + event.title
        }
        
        // Add reminder if specified
        if let reminderDate = todo.reminderDate {
            let alarm = EKAlarm(absoluteDate: reminderDate)
            event.addAlarm(alarm)
        }
        
        // Set calendar
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Successfully added todo to calendar: \(todo.title)")
        } catch {
            print("Failed to add todo to calendar: \(error.localizedDescription)")
        }
    }
    
    private func removeFromCalendar(_ todo: Todo) {
        guard calendarAccessGranted else { return }
        
        // Find and remove matching events
        let predicate = eventStore.predicateForEvents(
            withStart: Date().addingTimeInterval(-30*24*60*60), // Last 30 days
            end: Date().addingTimeInterval(365*24*60*60),       // Next year
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        let matchingEvents = events.filter { $0.title.contains(todo.title) }
        
        for event in matchingEvents {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("Successfully removed todo from calendar: \(todo.title)")
            } catch {
                print("Failed to remove todo from calendar: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - AI Integration
    func getTaskSuggestions() -> [String] {
        return aiService.suggestTasks(timeOfDay: Date())
    }
    
    func calculateOptimalReminder(for todo: Todo) -> Date? {
        return aiService.calculateOptimalReminderTime(for: todo)
    }
    
    func getWorkSessionTiming() -> (duration: TimeInterval, breakTime: TimeInterval) {
        return aiService.calculateOptimalWorkSession()
    }
    
    func predictTaskCompletionTime(for todo: Todo) -> TimeInterval {
        return aiService.predictCompletionTime(for: todo)
    }
}

// MARK: - Export Data Structure
public struct ExportData: Codable {
    public let todos: [Todo]
    public let categories: [Todo.Category]
    public let tags: [Todo.Tag]
    public let statistics: Statistics
    
    public init(todos: [Todo], categories: [Todo.Category], tags: [Todo.Tag], statistics: Statistics) {
        self.todos = todos
        self.categories = categories
        self.tags = tags
        self.statistics = statistics
    }
}
