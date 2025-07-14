import SwiftUI

struct AIView: View {
    @EnvironmentObject var viewModel: TodoViewModel
    @State private var stressLevel: Double = 0.5
    @State private var workLifeBalance: Double = 0.7
    @State private var productivityPatterns: [String] = ["Morning", "Afternoon", "Evening"]
    @State private var achievements: [String] = ["Consistent Morning Routine", "Task Completion Streak"]
    @State private var learningPaths: [String] = ["Time Management", "Focus Techniques"]
    @State private var anomalies: [String] = ["Unusual late-night activity", "High task volume"]
    @State private var showingTaskSuggestion = false
    @State private var showingFocusSession = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Health & Wellbeing Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Health & Wellbeing")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Stress Level")
                                    .font(.subheadline)
                                ProgressView(value: stressLevel)
                                    .tint(stressLevel > 0.7 ? .red : .green)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Work-Life Balance")
                                    .font(.subheadline)
                                ProgressView(value: workLifeBalance)
                                    .tint(workLifeBalance > 0.7 ? .green : .orange)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Smart Features Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Smart Features")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            Button(action: { showingTaskSuggestion = true }) {
                                VStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title)
                                    Text("Task Suggestion")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                            }
                            
                            Button(action: { showingFocusSession = true }) {
                                VStack {
                                    Image(systemName: "timer")
                                        .font(.title)
                                    Text("Focus Session")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                            }
                        }
                    }
                    
                    // Learning & Improvement Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Learning & Improvement")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(learningPaths, id: \.self) { path in
                            HStack {
                                Image(systemName: "book.fill")
                                Text(path)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                    
                    // Analytics Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Analytics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Productivity Patterns")
                                .font(.subheadline)
                            ForEach(productivityPatterns, id: \.self) { pattern in
                                Text("• \(pattern)")
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Achievements Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Achievements")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(achievements, id: \.self) { achievement in
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(achievement)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                    
                    // Security Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Security")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Anomalies Detected")
                                .font(.subheadline)
                            ForEach(anomalies, id: \.self) { anomaly in
                                Text("⚠️ \(anomaly)")
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Voice Commands Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Voice Commands")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "mic.fill")
                            Text("Try saying: 'Add a task for tomorrow'")
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .sheet(isPresented: $showingTaskSuggestion) {
                TaskSuggestionView()
            }
            .sheet(isPresented: $showingFocusSession) {
                FocusSessionView()
            }
        }
    }
}

struct TaskSuggestionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var suggestedTasks: [String] = ["Review project timeline", "Schedule team meeting", "Update documentation"]
    
    var body: some View {
        NavigationView {
            List(suggestedTasks, id: \.self) { task in
                Text(task)
            }
            .navigationTitle("Suggested Tasks")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct FocusSessionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var duration: Double = 25
    @State private var isActive = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\(Int(duration)) minutes")
                    .font(.largeTitle)
                
                Slider(value: $duration, in: 5...60, step: 5)
                    .padding()
                
                Button(action: { isActive = true }) {
                    Text("Start Focus Session")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Focus Session")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct AIView_Previews: PreviewProvider {
    static var previews: some View {
        AIView()
            .environmentObject(TodoViewModel())
    }
} 