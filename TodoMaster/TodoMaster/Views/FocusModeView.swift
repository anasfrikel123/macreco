import SwiftUI

struct FocusModeView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var selectedTodo: Todo?
    @State private var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var showingTodoPicker = false
    @State private var showingBreakAlert = false
    @State private var isBreak = false
    
    private let workDuration = 25 * 60 // 25 minutes
    private let shortBreakDuration = 5 * 60 // 5 minutes
    private let longBreakDuration = 15 * 60 // 15 minutes
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: Double {
        let total = isBreak ? (selectedTodo?.pomodoroCount ?? 0) % 4 == 0 ? longBreakDuration : shortBreakDuration : workDuration
        return 1 - (Double(timeRemaining) / Double(total))
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Timer Circle
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(isBreak ? .green : .red)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
                
                VStack {
                    Text(timeString)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text(isBreak ? "Break Time" : "Focus Time")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 300, height: 300)
            .padding()
            
            // Selected Todo
            if let todo = selectedTodo {
                VStack(spacing: 8) {
                    Text("Current Task")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(todo.title)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                Button(action: { showingTodoPicker = true }) {
                    Label("Select a Task", systemImage: "checklist")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // Controls
            HStack(spacing: 30) {
                Button(action: resetTimer) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Button(action: skipTimer) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            // Stats
            if let todo = selectedTodo {
                VStack(spacing: 12) {
                    Text("Session Stats")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Completed",
                            value: "\(todo.completedPomodoros)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        StatCard(
                            title: "Total",
                            value: "\(todo.pomodoroCount)",
                            icon: "timer",
                            color: .blue
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Focus Mode")
        .sheet(isPresented: $showingTodoPicker) {
            TodoPickerView(selectedTodo: $selectedTodo)
        }
        .alert("Break Time!", isPresented: $showingBreakAlert) {
            Button("Start Break", role: .none) {
                startBreak()
            }
        } message: {
            Text("Time to take a break. You've earned it!")
        }
        .onChange(of: timeRemaining) { newValue in
            if newValue == 0 {
                if isBreak {
                    endBreak()
                } else {
                    showingBreakAlert = true
                }
            }
        }
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        timeRemaining = isBreak ? (selectedTodo?.pomodoroCount ?? 0) % 4 == 0 ? longBreakDuration : shortBreakDuration : workDuration
    }
    
    private func skipTimer() {
        if isBreak {
            endBreak()
        } else {
            showingBreakAlert = true
        }
    }
    
    private func startBreak() {
        isBreak = true
        timeRemaining = (selectedTodo?.pomodoroCount ?? 0) % 4 == 0 ? longBreakDuration : shortBreakDuration
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private func endBreak() {
        isBreak = false
        if let todo = selectedTodo {
            let updatedTodo = todo
            updatedTodo.pomodoroCount += 1
            updatedTodo.completedPomodoros += 1
            viewModel.updateTodo(updatedTodo)
        }
        timeRemaining = workDuration
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}

struct TodoPickerView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @Binding var selectedTodo: Todo?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(viewModel.todos.filter { !$0.isCompleted }) { todo in
                Button(action: {
                    selectedTodo = todo
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(todo.title)
                                .foregroundColor(.primary)
                            if let dueDate = todo.dueDate {
                                Text(dueDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if todo.priority != .none {
                            Circle()
                                .fill(priorityColor(todo.priority))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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