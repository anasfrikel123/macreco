import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var searchText = ""
    @State private var showingFilter = false
    @State private var showingSort = false
    @State private var showingFocusMode = false
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedSort: SortOption = .dueDate
    @State private var showingDeleteConfirmation = false
    @State private var todoToDelete: Todo?
    @Environment(\.colorScheme) private var colorScheme
    
    private var filteredAndSortedTodos: [Todo] {
        var todos = viewModel.todos
        
        // Apply search filter
        if !searchText.isEmpty {
            todos = todos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all: break
        case .active:
            todos = todos.filter { !$0.isCompleted }
        case .completed:
            todos = todos.filter { $0.isCompleted }
        case .pinned:
            todos = todos.filter { $0.isPinned }
        }
        
        // Apply sorting
        switch selectedSort {
        case .dueDate:
            todos.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .priority:
            todos.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .title:
            todos.sort { $0.title < $1.title }
        case .creationDate:
            todos.sort { $0.createdAt > $1.createdAt }
        }
        
        return todos
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search tasks", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedFilter == .all,
                            action: { selectedFilter = .all }
                        )
                        FilterChip(
                            title: "Active",
                            isSelected: selectedFilter == .active,
                            action: { selectedFilter = .active }
                        )
                        FilterChip(
                            title: "Completed",
                            isSelected: selectedFilter == .completed,
                            action: { selectedFilter = .completed }
                        )
                        FilterChip(
                            title: "Pinned",
                            isSelected: selectedFilter == .pinned,
                            action: { selectedFilter = .pinned }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Task list
                List {
                    ForEach(filteredAndSortedTodos) { todo in
                        TodoRowView(todo: todo) {
                            todoToDelete = todo
                            showingDeleteConfirmation = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                todoToDelete = todo
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                viewModel.togglePin(todo)
                            } label: {
                                Label(todo.isPinned ? "Unpin" : "Pin",
                                      systemImage: todo.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.toggleTodoCompletion(todo)
                            } label: {
                                Label(todo.isCompleted ? "Uncomplete" : "Complete",
                                      systemImage: todo.isCompleted ? "xmark.circle" : "checkmark.circle")
                            }
                            .tint(todo.isCompleted ? .red : .green)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showingAddTodo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Sort options
                        Menu("Sort By") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    selectedSort = option
                                } label: {
                                    Label(
                                        option.rawValue,
                                        systemImage: selectedSort == option ? "checkmark" : ""
                                    )
                                }
                            }
                        }
                        
                        Button {
                            showingFocusMode = true
                        } label: {
                            Label("Focus Mode", systemImage: "timer")
                        }
                        
                        Button {
                            if viewModel.isListening {
                                viewModel.stopVoiceCommand()
                            } else {
                                viewModel.startVoiceCommand()
                            }
                        } label: {
                            Label(viewModel.isListening ? "Stop Voice" : "Voice Command",
                                  systemImage: viewModel.isListening ? "mic.fill" : "mic")
                        }
                        
                        if !filteredAndSortedTodos.isEmpty {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete All", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTodo) {
                AddTodoView()
            }
            .sheet(isPresented: $showingFocusMode) {
                FocusModeView()
            }
            .alert("Delete Task?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let todo = todoToDelete {
                        viewModel.deleteTodo(todo)
                        todoToDelete = nil
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .overlay {
                if viewModel.isListening {
                    VoiceCommandOverlay(feedback: viewModel.voiceCommandFeedback) {
                        viewModel.stopVoiceCommand()
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct VoiceCommandOverlay: View {
    let feedback: String
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text(feedback)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .padding(.trailing)
            }
            .padding(.bottom, 50)
        }
    }
}

struct TodoRowView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    let todo: Todo
    @Environment(\.colorScheme) private var colorScheme
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Checkbox
            Button {
                viewModel.toggleTodoCompletion(todo)
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .blue : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                
                HStack(spacing: 8) {
                    if let dueDate = todo.dueDate {
                        Label(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    if todo.priority != .none {
                        PriorityBadge(priority: todo.priority)
                    }
                    
                    if let category = todo.category {
                        Text(category.name)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: category.colorHex).opacity(0.2))
                            .foregroundColor(Color(hex: category.colorHex))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            if todo.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                viewModel.toggleTodoCompletion(todo)
            } label: {
                Label(
                    todo.isCompleted ? "Mark Incomplete" : "Mark Complete",
                    systemImage: todo.isCompleted ? "xmark.circle" : "checkmark.circle"
                )
            }
            
            Button {
                viewModel.togglePin(todo)
            } label: {
                Label(
                    todo.isPinned ? "Unpin" : "Pin",
                    systemImage: todo.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct PriorityBadge: View {
    let priority: Todo.Priority
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<priority.rawValue, id: \.self) { _ in
                Image(systemName: "exclamationmark")
                    .font(.caption2)
            }
        }
        .foregroundColor(priorityColor)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(priorityColor.opacity(0.2))
        .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        case .none: return .gray
        }
    }
}

// Preview
struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
            .environmentObject(TodoViewModel())
    }
}

enum FilterOption: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case pinned = "Pinned"
}

enum SortOption: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"
    case creationDate = "Creation Date"
}

struct FilterView: View {
    @Binding var selectedFilter: FilterOption
    @Binding var selectedSort: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter")) {
                    ForEach(FilterOption.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                Spacer()
                                if filter == selectedFilter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SortView: View {
    @Binding var selectedSort: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sort By")) {
                    ForEach(SortOption.allCases, id: \.self) { sort in
                        Button {
                            selectedSort = sort
                            dismiss()
                        } label: {
                            HStack {
                                Text(sort.rawValue)
                                Spacer()
                                if sort == selectedSort {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }
    
    private var statistics: TaskStatistics {
        let allTodos = viewModel.todos
        let completedTodos = allTodos.filter(\.isCompleted)
        let activeTodos = allTodos.filter { !$0.isCompleted }
        
        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }
        
        let recentTodos = allTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return dueDate >= startDate
        }
        
        let recentCompletedTodos = recentTodos.filter(\.isCompleted)
        
        return TaskStatistics(
            totalTasks: allTodos.count,
            completedTasks: completedTodos.count,
            activeTasks: activeTodos.count,
            completionRate: allTodos.isEmpty ? 0 : Double(completedTodos.count) / Double(allTodos.count),
            recentCompletionRate: recentTodos.isEmpty ? 0 : Double(recentCompletedTodos.count) / Double(recentTodos.count),
            priorityDistribution: calculatePriorityDistribution(todos: allTodos),
            categoryDistribution: calculateCategoryDistribution(todos: allTodos),
            completionTrend: calculateCompletionTrend(todos: allTodos, startDate: startDate)
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Overview cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Completion Rate",
                            value: "\(Int(statistics.completionRate * 100))%",
                            icon: "chart.pie.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Tasks",
                            value: "\(statistics.totalTasks)",
                            icon: "checklist",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Active Tasks",
                            value: "\(statistics.activeTasks)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Completed Tasks",
                            value: "\(statistics.completedTasks)",
                            icon: "checkmark.circle.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Priority distribution
                    ChartSection(
                        title: "Priority Distribution",
                        data: statistics.priorityDistribution.map { (String($0.key.rawValue), $0.value) }
                    )
                    
                    // Category distribution
                    if !statistics.categoryDistribution.isEmpty {
                        ChartSection(
                            title: "Category Distribution",
                            data: statistics.categoryDistribution.map { ($0.key, $0.value) }
                        )
                    }
                    
                    // Completion trend
                    TrendSection(
                        title: "Completion Trend",
                        data: statistics.completionTrend,
                        timeRange: selectedTimeRange
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func calculatePriorityDistribution(todos: [Todo]) -> [Todo.Priority: Int] {
        var distribution: [Todo.Priority: Int] = [:]
        for priority in Todo.Priority.allCases {
            distribution[priority] = todos.filter { $0.priority == priority }.count
        }
        return distribution
    }
    
    private func calculateCategoryDistribution(todos: [Todo]) -> [String: Int] {
        var distribution: [String: Int] = [:]
        for todo in todos {
            if let category = todo.category {
                let categoryName = String(describing: category)
                distribution[categoryName, default: 0] += 1
            }
        }
        return distribution
    }
    
    private func calculateCompletionTrend(todos: [Todo], startDate: Date) -> [(Date, Int)] {
        var trend: [(Date, Int)] = []
        var currentDate = startDate
        let endDate = Date()
        
        while currentDate <= endDate {
            let completedCount = todos.filter { todo in
                guard let completionDate = todo.dueDate,
                      todo.isCompleted else { return false }
                return calendar.isDate(completionDate, inSameDayAs: currentDate)
            }.count
            
            trend.append((currentDate, completedCount))
            
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return trend
    }
}

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let activeTasks: Int
    let completionRate: Double
    let recentCompletionRate: Double
    let priorityDistribution: [Todo.Priority: Int]
    let categoryDistribution: [String: Int]
    let completionTrend: [(Date, Int)]
}

struct ChartSection: View {
    let title: String
    let data: [(String, Int)]
    
    private var total: Int {
        data.reduce(0) { $0 + $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(data.sorted(by: { $0.1 > $1.1 }), id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                            .frame(width: 100, alignment: .leading)
                        
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * CGFloat(item.1) / CGFloat(total)),
                                    alignment: .leading
                                )
                        }
                        .frame(height: 8)
                        
                        Text("\(item.1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

struct TrendSection: View {
    let title: String
    let data: [(Date, Int)]
    let timeRange: ReportsView.TimeRange
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch timeRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d MMM"
        case .year:
            formatter.dateFormat = "MMM"
        }
        return formatter
    }
    
    private var groupedData: [(String, Int)] {
        var grouped: [String: Int] = [:]
        
        for (date, count) in data {
            let key = dateFormatter.string(from: date)
            grouped[key, default: 0] += count
        }
        
        return grouped.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(groupedData, id: \.0) { item in
                        VStack {
                            Text("\(item.1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: 20, height: CGFloat(item.1) * 10 + 4)
                            
                            Text(item.0)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
} 

