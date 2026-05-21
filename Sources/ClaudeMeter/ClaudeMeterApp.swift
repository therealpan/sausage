import SwiftUI

@main
struct ClaudeMeterApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            DetailPanel()
                .environment(appState)
        } label: {
            MenuBarLabel()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
