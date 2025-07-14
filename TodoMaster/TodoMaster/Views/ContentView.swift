import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                TodoListView()
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }
                    .tag(1)
                
                CategoriesView()
                    .tabItem {
                        Label("Categories", systemImage: "folder")
                    }
                    .tag(2)
                
                AIView()
                    .tabItem {
                        Label("AI", systemImage: "brain")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(viewModel.currentTheme.isDarkMode ? .dark : .light)
        .accentColor(viewModel.currentTheme.accentColor)
        .onAppear {
            // Initialize default data if needed
            if viewModel.categories.isEmpty {
                viewModel.addDefaultCategories()
            }
        }
    }
} 