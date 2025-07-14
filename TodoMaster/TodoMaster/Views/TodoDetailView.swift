import SwiftUI
import PhotosUI
import UIKit
import Foundation

public struct TodoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: TodoViewModel
    @StateObject var todo: Todo
    @State private var isEditing = false
    
    public var body: some View {
        List {
            Section {
                HStack {
                    Text(todo.title)
                        .font(.headline)
                    Spacer()
                    if todo.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                HStack {
                    Label("Priority", systemImage: todo.priority.icon)
                    Spacer()
                    Text(todo.priority.name)
                        .foregroundColor(.secondary)
                }
                
                if let category = todo.category {
                    HStack {
                        Label(category.name, systemImage: category.icon)
                            .foregroundColor(category.color)
                        Spacer()
                    }
                }
                
                if !todo.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(todo.tags) { tag in
                                Text(tag.name)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if let dueDate = todo.dueDate {
                Section {
                    HStack {
                        Label("Due Date", systemImage: "calendar")
                        Spacer()
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let reminderDate = todo.reminderDate {
                Section {
                    HStack {
                        Label("Reminder", systemImage: "bell")
                        Spacer()
                        Text(reminderDate.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !todo.attachments.isEmpty {
                Section("Attachments") {
                    ForEach(todo.attachments) { attachment in
                        HStack {
                            Image(systemName: attachment.type.icon)
                            Text(attachment.filename)
                            Spacer()
                            Button(action: { /* Open attachment */ }) {
                                Image(systemName: "arrow.up.forward.square")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Todo Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isEditing = true }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            TodoEditView(todo: todo)
        }
    }
}

struct TodoEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: TodoViewModel
    @ObservedObject var todo: Todo
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var priority: Todo.Priority
    @State private var category: Todo.Category?
    @State private var tags: Set<Todo.Tag>
    @State private var isPinned: Bool
    @State private var showingTagPicker = false
    
    init(todo: Todo) {
        self.todo = todo
        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes)
        _dueDate = State(initialValue: todo.dueDate ?? Date())
        _priority = State(initialValue: todo.priority)
        _category = State(initialValue: todo.category)
        _tags = State(initialValue: Set(todo.tags))
        _isPinned = State(initialValue: todo.isPinned)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Title", text: $title)
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Todo.Priority.allCases, id: \.self) { priority in
                            Label(priority.name, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    
                    Toggle("Pinned", isOn: $isPinned)
                }
                
                Section {
                    if let category = category {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.name)
                            Spacer()
                            Button("Clear") {
                                self.category = nil
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        NavigationLink("Select Category") {
                            CategoryPickerView(selectedCategory: $category)
                        }
                    }
                }
                
                Section {
                    Button(action: { showingTagPicker = true }) {
                        HStack {
                            Text(tags.isEmpty ? "Add Tags" : "Selected Tags: \(tags.count)")
                            Spacer()
                            Image(systemName: "tag")
                        }
                    }
                }
            }
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateTodo()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerView(selectedTags: $tags)
            }
        }
    }
    
    private func updateTodo() {
        todo.title = title
        todo.notes = notes
        todo.dueDate = dueDate
        todo.priority = priority
        todo.category = category
        todo.tags = Array(tags)
        todo.isPinned = isPinned
        viewModel.updateTodo(todo)
    }
}

struct TodoEditView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Todo.Category(
            name: "Work",
            colorHex: "#007AFF",
            icon: "briefcase"
        )
        
        let todo = Todo(
            title: "Sample Todo",
            notes: "This is a sample todo",
            isCompleted: false,
            dueDate: Date(),
            priority: .high,
            category: sampleCategory,
            tags: [],
            reminderDate: Date(),
            isPinned: false,
            estimatedTime: 3600,
            attachments: []
        )
        
        return TodoEditView(todo: todo)
            .environmentObject(TodoViewModel())
    }
}

struct TodoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Todo.Category(
            name: "Work",
            colorHex: "#007AFF",
            icon: "briefcase"
        )
        
        let todo = Todo(
            title: "Sample Todo",
            notes: "This is a sample todo",
            isCompleted: false,
            dueDate: Date(),
            priority: .high,
            category: sampleCategory,
            tags: [],
            reminderDate: Date(),
            isPinned: false,
            estimatedTime: 3600,
            attachments: []
        )
        
        return TodoDetailView(todo: todo)
            .environmentObject(TodoViewModel())
    }
} 
