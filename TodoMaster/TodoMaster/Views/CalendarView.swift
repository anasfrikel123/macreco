import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var selectedDate = Date()
    @State private var showingAddTodo = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }
    
    private func todosForDate(_ date: Date) -> [Todo] {
        viewModel.todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Text(monthTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                // Days of week header
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { date in
                        DayCell(date: date, selectedDate: $selectedDate, todos: todosForDate(date))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal)
                
                // Selected day's todos
                List {
                    let selectedTodos = todosForDate(selectedDate)
                    if selectedTodos.isEmpty {
                        Text("No todos for this day")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(selectedTodos) { todo in
                            TodoRowView(todo: todo, onDelete: {
                                viewModel.deleteTodo(todo)
                            })
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTodo = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView()
            }
        }
    }
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let todos: [Todo]
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        let components = calendar.dateComponents([.day], from: date)
        return "\(components.day ?? 0)"
    }
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
    }
    
    var body: some View {
        Button(action: { selectedDate = date }) {
            VStack {
                Text(dayNumber)
                    .font(isToday ? .headline : .body)
                    .foregroundColor(cellTextColor)
                
                if !todos.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(todos.prefix(3)) { todo in
                            Circle()
                                .fill(priorityColor(todo.priority))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cellBackground)
        }
    }
    
    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
    }
    
    private var cellTextColor: Color {
        if isSelected {
            return .primary
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }
    
    private func priorityColor(_ priority: Todo.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .none: return .gray
        }
    }
}

extension Calendar {
    func generateDates(for dateInterval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(dateInterval.start)
        
        enumerateDates(startingAfter: dateInterval.start,
                      matching: components,
                      matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            
            if date <= dateInterval.end {
                dates.append(date)
            } else {
                stop = true
            }
        }
        
        return dates
    }
} 