import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct ContainerIndicatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
