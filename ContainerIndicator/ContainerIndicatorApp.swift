import SwiftUI

@main
struct ContainerIndicatorApp: App {
    @State private var containerManager = ContainerManager()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(containerManager)
        } label: {
            Label("Container", systemImage: containerManager.systemStatus.iconName)
        }
        
        WindowGroup(id: "main") {
            ContentView()
                .environment(containerManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 750, height: 500)
        .windowResizability(.contentSize)
    }
}
