import SwiftUI

@main
struct TodoMasterApp: App {
    @StateObject private var todoViewModel = TodoViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(todoViewModel)
                .preferredColorScheme(todoViewModel.currentTheme.colorScheme)
        }
    }
}
