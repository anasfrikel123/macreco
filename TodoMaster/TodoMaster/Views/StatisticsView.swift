import SwiftUI

struct DailyCompletion: Equatable {
    let date: Date
    let completed: Double
    
    static func == (lhs: DailyCompletion, rhs: DailyCompletion) -> Bool {
        return lhs.date == rhs.date && lhs.completed == rhs.completed
    }
}

struct StatisticsView: View {
    @EnvironmentObject var viewModel: TodoViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : .white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                overallProgressSection
                
                completionTrendsSection
                
                categoryBreakdownSection
                
                productivityInsightsSection
                
                timeDistributionSection
                
                taskPrioritySection
                
                priorityDistribution
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Analytics")
    }
    
    private var overallProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Overall Progress")
                .font(.headline)
            
            HStack(spacing: 20) {
                CircularProgressView(
                    progress: viewModel.statistics.completionRate / 100,
                    color: .blue,
                    title: "Completion",
                    subtitle: "\(Int(viewModel.statistics.completionRate))%"
                )
                
                CircularProgressView(
                    progress: Double(viewModel.statistics.streak) / 10,
                    color: .green,
                    title: "Streak",
                    subtitle: "\(viewModel.statistics.streak) days"
                )
                
                CircularProgressView(
                    progress: viewModel.statistics.productivityScore / 100,
                    color: .purple,
                    title: "Score",
                    subtitle: "\(Int(viewModel.statistics.productivityScore))%"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var completionTrendsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Completion Trends")
                            .font(.headline)
                        
            let data = getDailyCompletionData()
            let maxValue = data.map { $0.completed }.max() ?? 1
            
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]
                        VStack(spacing: 4) {
                            Text("\(Int(item.completed))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentGradient)
                                .frame(height: CGFloat(item.completed / maxValue) * 150)
                            
                            Text(formatDate(item.date))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .frame(height: 200)
                .animation(.easeInOut, value: data)
                
                Text("Last 7 Days")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
                    }
                    .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category Distribution")
                            .font(.headline)
            
            if viewModel.categories.isEmpty {
                Text("No categories yet")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(getCategoryStats(), id: \.category.id) { stat in
                    HStack(spacing: 12) {
                        Image(systemName: stat.category.icon)
                            .foregroundColor(Color(hex: stat.category.colorHex) ?? .gray)
                            .font(.system(size: 20))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill((Color(hex: stat.category.colorHex) ?? .gray).opacity(0.2))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(stat.category.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(stat.count)")
                                .foregroundColor(.secondary)
                        }
                        
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: stat.category.colorHex) ?? .gray)
                                    .frame(width: geometry.size.width * CGFloat(stat.percentage), height: 6)
                                    .animation(.easeInOut, value: stat.percentage)
                            }
                            .frame(height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            // You can add interaction here if needed
                        }
                    }
                }
                        }
                    }
                    .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var productivityInsightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Productivity Insights")
                            .font(.headline)
                        
            VStack(alignment: .leading, spacing: 10) {
                InsightRow(
                    title: "Most Productive Day",
                    value: getMostProductiveDay(),
                    icon: "star.fill",
                    color: .yellow
                )
                
                InsightRow(
                    title: "Total Tasks",
                    value: "\(viewModel.todos.count)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                InsightRow(
                    title: "Task Streak",
                    value: "\(viewModel.statistics.streak) days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                InsightRow(
                    title: "Completion Rate",
                    value: "\(Int(viewModel.statistics.completionRate))%",
                    icon: "timer",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var timeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Time Distribution")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(getHourlyDistribution(), id: \.hour) { data in
                    VStack {
                        Text("\(data.count)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentGradient)
                            .frame(height: CGFloat(data.count) * 20)
                        
                        Text("\(data.hour)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
            .frame(height: 150)
                    }
                    .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var taskPrioritySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Task Priority Distribution")
                                .font(.headline)
                            
            HStack(spacing: 20) {
                PriorityPieSlice(
                    priority: .high,
                    count: viewModel.todos.filter { $0.priority == .high }.count,
                    total: viewModel.todos.count
                )
                
                PriorityPieSlice(
                    priority: .medium,
                    count: viewModel.todos.filter { $0.priority == .medium }.count,
                    total: viewModel.todos.count
                )
                
                PriorityPieSlice(
                    priority: .low,
                    count: viewModel.todos.filter { $0.priority == .low }.count,
                    total: viewModel.todos.count
                )
            }
            .frame(height: 100)
                        }
                        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var priorityDistribution: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Priority Distribution")
                .font(.headline)
            
            ForEach([Todo.Priority.high, .medium, .low], id: \.self) { priority in
                HStack(spacing: 12) {
                    Circle()
                        .fill(priority.color)
                        .frame(width: 12, height: 12)
                    
                    Text(priorityString(for: priority))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Text("\(viewModel.todos.filter { $0.priority == priority }.count)")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(priority.color.opacity(0.15))
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        // You can add interaction here if needed
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func priorityString(for priority: Todo.Priority) -> String {
        switch priority {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .none: return "None"
        }
    }
    
    // Helper functions
    private func getDailyCompletionData() -> [DailyCompletion] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        return calendar.generateDates(
            inside: DateInterval(start: startDate, end: endDate),
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        ).map { date in
            let completedCount = viewModel.todos.filter {
                $0.isCompleted && calendar.isDate($0.updatedAt, inSameDayAs: date)
            }.count
            return DailyCompletion(date: date, completed: Double(completedCount))
        }
    }
    
    private func getCategoryStats() -> [(category: Todo.Category, count: Int, percentage: Double)] {
        let total = Double(viewModel.todos.count)
        return viewModel.categories.map { category in
            let count = viewModel.todos.filter { $0.category?.id == category.id }.count
            return (category: category, count: count, percentage: Double(count) / total)
        }.sorted { $0.count > $1.count }
    }
    
    private func getMostProductiveDay() -> String {
        let calendar = Calendar.current
        var dayCounts: [Int: Int] = [:]
        
        for todo in viewModel.todos where todo.isCompleted {
            let weekday = calendar.component(.weekday, from: todo.updatedAt)
            dayCounts[weekday, default: 0] += 1
        }
        
        guard let maxDay = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return "N/A"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.weekdaySymbols[maxDay - 1]
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    private func getHourlyDistribution() -> [(hour: Int, count: Int)] {
        var hourCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        
        for todo in viewModel.todos {
            let hour = calendar.component(.hour, from: todo.createdAt)
            hourCounts[hour, default: 0] += 1
        }
        
        return (0...23).map { hour in
            (hour: hour, count: hourCounts[hour] ?? 0)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(subtitle)
                    .font(.caption)
                    .bold()
            }
            .frame(width: 60, height: 60)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

struct PriorityPieSlice: View {
    let priority: Todo.Priority
    let count: Int
    let total: Int
    
    private var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .none: return .gray
        }
    }
    
    private var priorityString: String {
        switch priority {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .none: return "None"
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .trim(from: 0, to: total == 0 ? 0 : CGFloat(count) / CGFloat(total))
                    .stroke(color, lineWidth: 10)
                    .rotationEffect(.degrees(-90))
                
                Text(total == 0 ? "0%" : "\(Int(min(100, (Double(count) / Double(total)) * 100)))%")
                    .font(.caption)
                    .bold()
            }
            .frame(width: 60, height: 60)
            
            Text(priorityString)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(TodoViewModel())
    }
} 
