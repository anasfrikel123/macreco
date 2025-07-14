//
//  ContentView.swift
//  TodoMaster
//
//  Created by anas frikel on 12/4/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: TodoViewModel
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                TodoListView()
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(1)
                
                StatisticsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .accentColor(colorScheme == .dark ? .white : .blue)
        }
        .preferredColorScheme(viewModel.currentTheme.colorScheme)
    }
    
    public init() {}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TodoViewModel())
    }
}
#endif
