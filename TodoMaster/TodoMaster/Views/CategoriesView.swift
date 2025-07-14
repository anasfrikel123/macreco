import SwiftUI

public struct CategoriesView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var showingAddCategory = false
    @State private var showingEditCategory = false
    @State private var selectedCategory: Todo.Category?
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.categories) { category in
                    CategoryRowView(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                            showingEditCategory = true
                        }
                }
                .onDelete { indexSet in
                    viewModel.deleteCategories(at: indexSet)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingEditCategory) {
                if let category = selectedCategory {
                    CategoryEditView(viewModel: viewModel, existingCategory: category)
                }
            }
        }
    }
    
    public init() { }
}

struct CategoryRowView: View {
    let category: Todo.Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(Color(hex: category.colorHex) ?? .blue)
            
            Text(category.name)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
    }
}

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodoViewModel
    @State private var name: String = ""
    @State private var selectedColorHex: String = Todo.Category.defaultColors[0].hex
    @State private var selectedIcon: String = "folder"
    var existingCategory: Todo.Category?
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name", text: $name)
                    
                    Section(header: Text("Color")) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Todo.Category.defaultColors, id: \.hex) { color in
                                Circle()
                                    .fill(Color(hex: color.hex) ?? .blue)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == color.hex ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColorHex = color.hex
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    NavigationLink(destination: IconPickerView(selectedIcon: $selectedIcon)) {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: selectedIcon)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle(existingCategory == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let category = existingCategory {
                            viewModel.updateCategory(category, name: name, colorHex: selectedColorHex, icon: selectedIcon)
                        } else {
                            viewModel.addCategory(name: name, colorHex: selectedColorHex, icon: selectedIcon)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            if let category = existingCategory {
                name = category.name
                selectedColorHex = category.colorHex
                selectedIcon = category.icon
            }
        }
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    
    private let icons = [
        "folder", "tag", "calendar", "star", "flag",
        "bell", "house", "person", "heart", "cart",
        "book", "pencil", "doc", "envelope", "gear",
        "trash", "lock", "cloud", "link", "bookmark"
    ]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedIcon = icon
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Select Icon")
    }
} 
