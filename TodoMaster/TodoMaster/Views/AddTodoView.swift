import SwiftUI
import PhotosUI

public struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: TodoViewModel
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var priority = Todo.Priority.none
    @State private var selectedCategory: Todo.Category?
    @State private var selectedTags: Set<Todo.Tag> = []
    @State private var showingTagPicker = false
    @State private var hasReminder = false
    @State private var reminderDate = Date()
    @State private var estimatedTime: TimeInterval?
    @State private var hasEstimatedTime = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachments: [Todo.Attachment] = []
    
    public var body: some View {
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
                }
                
                Section {
                    if let category = selectedCategory {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.name)
                            Spacer()
                            Button("Clear") {
                                selectedCategory = nil
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        NavigationLink("Select Category") {
                            CategoryPickerView(selectedCategory: $selectedCategory)
                        }
                    }
                }
                
                Section {
                    Button(action: { showingTagPicker = true }) {
                        HStack {
                            Text(selectedTags.isEmpty ? "Add Tags" : "Selected Tags: \(selectedTags.count)")
                            Spacer()
                            Image(systemName: "tag")
                        }
                    }
                }
                
                Section {
                    Toggle("Set Reminder", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("Reminder Time",
                                 selection: $reminderDate,
                                 displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section {
                    Toggle("Has Time Estimate", isOn: $hasEstimatedTime)
                    if hasEstimatedTime {
                        Picker("Estimated Time", selection: Binding(
                            get: { estimatedTime.map { Int($0 / 3600) } ?? 1 },
                            set: { estimatedTime = TimeInterval($0 * 3600) }
                        )) {
                            ForEach(1...8, id: \.self) { hours in
                                Text("\(hours) hour\(hours == 1 ? "" : "s")")
                            }
                        }
                    }
                }
                
                if !selectedPhotos.isEmpty {
                    Section {
                        PhotosPicker(selection: $selectedPhotos,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            Label("Add Photos", systemImage: "photo")
                        }
                        
                        ForEach(attachments, id: \.id) { attachment in
                            if let uiImage = UIImage(data: attachment.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTodo()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
            .onChange(of: selectedPhotos) { _ in
                Task {
                    await loadPhotos()
                }
            }
        }
    }
    
    private func addTodo() {
        let todo = Todo(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            category: selectedCategory,
            tags: Array(selectedTags),
            reminderDate: hasReminder ? reminderDate : nil,
            estimatedTime: hasEstimatedTime ? estimatedTime : nil,
            attachments: attachments
        )
        viewModel.addTodo(todo)
    }
    
    private func loadPhotos() async {
        var newAttachments: [Todo.Attachment] = []
        
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let attachment = Todo.Attachment(
                    data: data,
                    filename: "photo_\(Date().timeIntervalSince1970).jpg",
                    type: .image
                )
                newAttachments.append(attachment)
            }
        }
        
        await MainActor.run {
            attachments.append(contentsOf: newAttachments)
        }
    }
}

struct CategoryPickerView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Todo.Category?
    
    var body: some View {
        List(viewModel.categories) { category in
            Button {
                selectedCategory = category
                dismiss()
            } label: {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(Color(hex: category.colorHex) ?? .blue)
                    Text(category.name)
                    Spacer()
                    if selectedCategory?.id == category.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .foregroundColor(.primary)
        }
        .navigationTitle("Select Category")
    }
}

struct TagPickerView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<Todo.Tag>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tags) { tag in
                    Button {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    } label: {
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
