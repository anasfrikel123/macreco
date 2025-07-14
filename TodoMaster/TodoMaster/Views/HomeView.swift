import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var showingAddSheet = false
    @State private var showingFocusMode = false
    @State private var showingCalendar = false
    @State private var showingReports = false
    @State private var quickNote = ""
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting Card
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("All caught up! Great job!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue)
                .cornerRadius(16)
                
                // Statistics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatBox(
                        title: "Completed Today",
                        value: "\(viewModel.completedToday.count)"
                    )
                    StatBox(
                        title: "Upcoming Deadlines",
                        value: "\(viewModel.upcomingDeadlines.count)"
                    )
                    StatBox(
                        title: "High Priority",
                        value: "\(viewModel.highPriorityTasks.count)"
                    )
                    StatBox(
                        title: "Completion Rate",
                        value: "\(Int(viewModel.completionRate))%"
                    )
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QuickActionButton(
                            title: "Add Task",
                            icon: "plus",
                            color: .blue,
                            backgroundColor: Color.blue.opacity(0.1)
                        ) {
                            showingAddSheet = true
                        }
                        
                        QuickActionButton(
                            title: "Focus Mode",
                            icon: "timer",
                            color: .red,
                            backgroundColor: Color.red.opacity(0.1)
                        ) {
                            showingFocusMode = true
                        }
                        
                        QuickActionButton(
                            title: "Calendar",
                            icon: "calendar",
                            color: .blue,
                            backgroundColor: Color.blue.opacity(0.1)
                        ) {
                            showingCalendar = true
                        }
                        
                        QuickActionButton(
                            title: "Reports",
                            icon: "chart.bar",
                            color: .purple,
                            backgroundColor: Color.purple.opacity(0.1)
                        ) {
                            showingReports = true
                        }
                    }
                }
                
                // Quick Note
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Note")
                        .font(.headline)
                    
                    TextEditor(text: $quickNote)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            Text("Add a quick note or reminder here...")
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                                .padding(.top, 16)
                                .opacity(quickNote.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
                }
                
                // Productivity Tip
                VStack(alignment: .leading, spacing: 8) {
                    Text("Productivity Tip")
                        .font(.headline)
                    Text("Try the new Focus Mode with our Pomodoro timer to boost your productivity! Work in focused 25-minute intervals for better concentration.")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            AddTodoView()
        }
        .sheet(isPresented: $showingFocusMode) {
            FocusModeView()
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarView()
        }
        .sheet(isPresented: $showingReports) {
            StatisticsView()
        }
    }
}

extension TodoViewModel {
    var completedToday: [Todo] {
        let calendar = Calendar.current
        return todos.filter { todo in
            todo.isCompleted && calendar.isDateInToday(todo.dueDate ?? Date())
        }
    }
    
    var upcomingDeadlines: [Todo] {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return !todo.isCompleted && dueDate <= nextWeek
        }
    }
    
    var highPriorityTasks: [Todo] {
        todos.filter { $0.priority == .high && !$0.isCompleted }
    }
    
    var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }
    }
    
    var completionRate: Double {
        guard !todos.isEmpty else { return 0.0 }
        let completed = Double(completedTodos.count)
        let total = Double(todos.count)
        guard total > 0, completed.isFinite, total.isFinite else { return 0.0 }
        return min((completed / total) * 100, 100.0)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TodoViewModel())
    }
} 