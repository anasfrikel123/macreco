import Foundation
import NaturalLanguage
import CoreML
import CoreLocation
import EventKit
import HealthKit

@MainActor
class AIService {
    private let viewModel: TodoViewModel
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
    private let locationManager = CLLocationManager()
    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()
    
    init(viewModel: TodoViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Health & Wellbeing
    private var stressLevel: Double = 0.0
    private var sleepPattern: [Date: TimeInterval] = [:]
    private var exerciseHistory: [Date: TimeInterval] = [:]
    
    func monitorStressLevel() async -> Double {
        // This would integrate with HealthKit to monitor stress
        // For now, return a simulated value
        return Double.random(in: 0...1)
    }
    
    func analyzeWorkLifeBalance() -> (workHours: TimeInterval, personalHours: TimeInterval) {
        let calendar = Calendar.current
        let now = Date()
        _ = calendar.startOfDay(for: now)
        
        var workHours: TimeInterval = 0
        var personalHours: TimeInterval = 0
        
        // Analyze calendar events
        let events = fetchCalendarEvents(around: now)
        for event in events {
            let duration = event.endDate.timeIntervalSince(event.startDate)
            if event.title.lowercased().contains("work") || event.title.lowercased().contains("meeting") {
                workHours += duration
            } else {
                personalHours += duration
            }
        }
        
        return (workHours, personalHours)
    }
    
    // MARK: - Learning & Improvement
    private var userHabits: [String: Int] = [:]
    private var skillProgress: [String: Double] = [:]
    
    func trackHabit(_ habit: String, completed: Bool) {
        if completed {
            userHabits[habit, default: 0] += 1
        }
    }
    
    func getHabitStreak(_ habit: String) -> Int {
        return userHabits[habit] ?? 0
    }
    
    func updateSkillProgress(_ skill: String, progress: Double) {
        skillProgress[skill] = progress
    }
    
    func getLearningPath() -> [String] {
        // This would analyze user's skills and suggest next steps
        return ["Time Management", "Task Prioritization", "Focus Techniques"]
    }
    
    // MARK: - Advanced Analytics
    func analyzeProductivityPatterns() -> (peakHours: [Int], lowHours: [Int]) {
        var hourlyProductivity: [Int: Int] = [:]
        
        // Analyze completed tasks by hour
        for todo in viewModel.todos {
            if todo.isCompleted {
                let hour = Calendar.current.component(.hour, from: todo.dueDate ?? Date())
                hourlyProductivity[hour, default: 0] += 1
            }
        }
        
        // Find peak and low hours
        let sortedHours = hourlyProductivity.sorted { $0.value > $1.value }
        let peakHours = Array(sortedHours.prefix(3)).map { $0.key }
        let lowHours = Array(sortedHours.suffix(3)).map { $0.key }
        
        return (peakHours, lowHours)
    }
    
    func predictTaskDependencies() -> [(task: Todo, dependencies: [Todo])] {
        var dependencies: [(Todo, [Todo])] = []
        
        // Analyze task relationships
        for todo in viewModel.todos {
            var relatedTasks: [Todo] = []
            
            // Find tasks with similar tags or categories
            for otherTodo in viewModel.todos {
                if todo.id != otherTodo.id {
                    let commonTags = Set(todo.tags).intersection(Set(otherTodo.tags))
                    if !commonTags.isEmpty || todo.category?.id == otherTodo.category?.id {
                        relatedTasks.append(otherTodo)
                    }
                }
            }
            
            dependencies.append((todo, relatedTasks))
        }
        
        return dependencies
    }
    
    // MARK: - Smart Notifications
    func calculateNotificationPriority(for todo: Todo) -> Double {
        var priority = 0.0
        
        // Consider due date
        if let dueDate = todo.dueDate {
            let timeUntilDue = dueDate.timeIntervalSinceNow
            if timeUntilDue < 3600 { // Less than 1 hour
                priority += 1.0
            } else if timeUntilDue < 86400 { // Less than 1 day
                priority += 0.7
            }
        }
        
        // Consider task priority
        switch todo.priority {
        case .high:
            priority += 0.8
        case .medium:
            priority += 0.5
        case .low:
            priority += 0.2
        case .none:
            break
        }
        
        // Consider completion status
        if !todo.isCompleted {
            priority += 0.3
        }
        
        return min(priority, 1.0)
    }
    
    // MARK: - Gamification
    private var achievements: [String: Bool] = [:]
    private var points: Int = 0
    
    func checkAchievements() -> [String] {
        var unlocked: [String] = []
        
        // Check for completion streaks
        let completedCount = viewModel.todos.filter { $0.isCompleted }.count
        if completedCount >= 10 && !achievements["task_master", default: false] {
            achievements["task_master"] = true
            unlocked.append("Task Master")
            points += 100
        }
        
        // Check for category completion
        let categories = Set(viewModel.todos.compactMap { $0.category?.name })
        if categories.count >= 5 && !achievements["category_explorer", default: false] {
            achievements["category_explorer"] = true
            unlocked.append("Category Explorer")
            points += 150
        }
        
        return unlocked
    }
    
    func getPoints() -> Int {
        return points
    }
    
    // MARK: - Integration Features
    func extractTasksFromEmail(_ email: String) -> [String] {
        // This would integrate with email services
        // For now, return a simulated result
        return ["Review project proposal", "Schedule team meeting"]
    }
    
    func analyzeMeetingNotes(_ notes: String) -> [String] {
        // This would use NLP to extract action items
        var tasks: [String] = []
        
        tagger.string = notes
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: notes.startIndex..<notes.endIndex, unit: .sentence, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag, tag == .other {
                let sentence = String(notes[tokenRange])
                if sentence.lowercased().contains("action item") || sentence.lowercased().contains("todo") {
                    tasks.append(sentence)
                }
            }
            return true
        }
        
        return tasks
    }
    
    // MARK: - Accessibility Features
    func generateVoiceDescription(for todo: Todo) -> String {
        var description = "Task: \(todo.title)"
        
        if let dueDate = todo.dueDate {
            description += ". Due \(dueDate.formatted(date: .abbreviated, time: .shortened))"
        }
        
        if let category = todo.category {
            description += ". Category: \(category.name)"
        }
        
        if !todo.tags.isEmpty {
            description += ". Tags: \(todo.tags.map { $0.name }.joined(separator: ", "))"
        }
        
        return description
    }
    
    // MARK: - Security & Privacy
    func detectAnomalies() -> [String] {
        var anomalies: [String] = []
        
        // Check for unusual access patterns
        let recentAccesses = UserDefaults.standard.object(forKey: "recent_accesses") as? [Date] ?? []
        if recentAccesses.count > 100 {
            anomalies.append("Unusual number of app accesses")
        }
        
        // Check for data export patterns
        let exports = UserDefaults.standard.object(forKey: "data_exports") as? [Date] ?? []
        if exports.count > 10 {
            anomalies.append("Frequent data exports detected")
        }
        
        return anomalies
    }
    
    // MARK: - Smart Task Suggestions
    func suggestTasks(timeOfDay: Date, location: CLLocation? = nil) -> [String] {
        var suggestions: [String] = []
        
        // Time-based suggestions
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timeOfDay)
        
        switch hour {
        case 6...9:
            suggestions.append("Morning routine")
            suggestions.append("Plan your day")
        case 12...14:
            suggestions.append("Lunch break")
            suggestions.append("Afternoon planning")
        case 17...19:
            suggestions.append("Evening review")
            suggestions.append("Plan tomorrow")
        default:
            break
        }
        
        // Location-based suggestions
        if location != nil {
            // Add location-specific tasks
            // This would require integration with a location service
        }
        
        return suggestions
    }
    
    // MARK: - Natural Language Processing
    func parseTaskDescription(_ text: String) -> (title: String, dueDate: Date?, priority: Todo.Priority, tags: [String]) {
        var title = text
        var dueDate: Date? = nil
        var priority = Todo.Priority.none
        var tags: [String] = []
        
        // Extract due date
        if let dateRange = text.range(of: #"\b(today|tomorrow|next week|next month)\b"#, options: .regularExpression) {
            let dateString = String(text[dateRange])
            dueDate = parseDate(from: dateString)
            title = text.replacingCharacters(in: dateRange, with: "").trimmingCharacters(in: .whitespaces)
        }
        
        // Extract priority
        if text.lowercased().contains("urgent") || text.lowercased().contains("important") {
            priority = .high
        } else if text.lowercased().contains("medium") {
            priority = .medium
        } else if text.lowercased().contains("low") {
            priority = .low
        }
        
        // Extract tags
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tag == .personalName || tag == .organizationName {
                let word = String(text[tokenRange])
                tags.append(word)
            }
            return true
        }
        
        return (title, dueDate, priority, tags)
    }
    
    // MARK: - Predictive Analytics
    func predictCompletionTime(for task: Todo) -> TimeInterval {
        // This would require historical data analysis
        // For now, return a simple estimate based on priority
        switch task.priority {
        case .high:
            return 3600 // 1 hour
        case .medium:
            return 7200 // 2 hours
        case .low:
            return 14400 // 4 hours
        case .none:
            return 10800 // 3 hours
        }
    }
    
    // MARK: - Smart Reminders
    func calculateOptimalReminderTime(for task: Todo) -> Date? {
        guard let dueDate = task.dueDate else { return nil }
        
        // Consider user's calendar events
        let events = fetchCalendarEvents(around: dueDate)
        
        // Find a suitable time slot
        var reminderTime = dueDate.addingTimeInterval(-3600) // Default: 1 hour before
        
        for event in events {
            if event.startDate < dueDate && event.endDate > reminderTime {
                reminderTime = event.startDate.addingTimeInterval(-1800) // 30 minutes before event
            }
        }
        
        return reminderTime
    }
    
    // MARK: - Focus & Productivity
    func calculateOptimalWorkSession() -> (duration: TimeInterval, breakTime: TimeInterval) {
        // This would require user behavior analysis
        // For now, return standard Pomodoro times
        return (1500, 300) // 25 minutes work, 5 minutes break
    }
    
    // MARK: - Helper Methods
    private func parseDate(from string: String) -> Date? {
        let calendar = Calendar.current
        var date = Date()
        
        switch string.lowercased() {
        case "today":
            break
        case "tomorrow":
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case "next week":
            date = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case "next month":
            date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        default:
            return nil
        }
        
        return date
    }
    
    private func fetchCalendarEvents(around date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        let endDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }
} 