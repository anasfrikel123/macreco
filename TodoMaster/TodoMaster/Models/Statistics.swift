import Foundation

public struct Statistics: Codable {
    public var streak: Int = 0
    public var lastCompletionDate: Date?
    public var completionRate: Double = 0
    public var productivityScore: Double = 0
    public var todosByPriority: [Int: Int] = [:]
    public var todosByCategory: [String: Int] = [:]
    public var averageCompletionTime: TimeInterval = 0
    public var streakDays: Int = 0
    public var totalTodos: Int = 0
    public var completedTodos: Int = 0
    public var pendingTodos: Int = 0
    
    private enum CodingKeys: String, CodingKey {
        case streak, lastCompletionDate, completionRate, productivityScore
        case todosByPriority, todosByCategory, averageCompletionTime, streakDays
        case totalTodos, completedTodos, pendingTodos
    }
    
    public init() {}
    
    public mutating func updateStats(todos: [Todo]) {
        // Basic stats
        totalTodos = todos.count
        completedTodos = todos.filter { $0.isCompleted }.count
        pendingTodos = totalTodos - completedTodos
        
        // Update completion rate
        completionRate = totalTodos > 0 ? Double(completedTodos) / Double(totalTodos) * 100 : 0
        
        // Update todos by priority
        var priorityCount: [Int: Int] = [:]
        for todo in todos {
            let priorityRaw = todo.priority.rawValue
            priorityCount[priorityRaw, default: 0] += 1
        }
        todosByPriority = priorityCount
        
        // Update todos by category
        var categoryCount: [String: Int] = [:]
        for todo in todos {
            if let category = todo.category {
                categoryCount[category.name, default: 0] += 1
            }
        }
        todosByCategory = categoryCount
        
        // Update streak and last completion date
        if let lastCompleted = todos.filter({ $0.isCompleted }).max(by: { $0.updatedAt < $1.updatedAt })?.updatedAt {
            let calendar = Calendar.current
            if let previousDate = lastCompletionDate {
                let daysBetween = calendar.dateComponents([.day], from: previousDate, to: lastCompleted).day ?? 0
                if daysBetween <= 1 {
                    streak += 1
                } else {
                    streak = 1
                }
            } else {
                streak = 1
            }
            lastCompletionDate = lastCompleted
            streakDays = streak
        }
        
        // Calculate productivity score (0-100)
        let completionWeight = 0.4
        let priorityWeight = 0.3
        let streakWeight = 0.3
        
        let completionScore = completionRate
        let priorityScore = calculatePriorityScore(todos: todos)
        let streakScore = Double(streak) * 10 // 10 points per streak day, max 100
        
        productivityScore = (completionScore * completionWeight) +
                          (priorityScore * priorityWeight) +
                          (min(streakScore, 100) * streakWeight)
        
        // Calculate average completion time
        let completedTodos = todos.filter { $0.isCompleted }
        if !completedTodos.isEmpty {
            let totalTime = completedTodos.reduce(0) { sum, todo in
                if let estimatedTime = todo.estimatedTime {
                    return sum + estimatedTime
                }
                return sum
            }
            averageCompletionTime = totalTime / Double(completedTodos.count)
        }
    }
    
    private func calculatePriorityScore(todos: [Todo]) -> Double {
        let total = todos.count
        guard total > 0 else { return 0 }
        
        let priorityWeights: [Todo.Priority: Double] = [
            .high: 1.0,
            .medium: 0.6,
            .low: 0.3,
            .none: 0.1
        ]
        
        let priorityScore = todos.reduce(0.0) { sum, todo in
            sum + (priorityWeights[todo.priority] ?? 0.0)
        }
        
        return (priorityScore / Double(total)) * 100
    }
} 
