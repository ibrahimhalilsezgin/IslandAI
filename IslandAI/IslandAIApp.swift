import SwiftUI

@main
struct IslandAIApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        if url.scheme == "islandai" && url.host == "record" {
            // Trigger a notification to start recording in MainView
            NotificationCenter.default.post(name: NSNotification.Name("TriggerRecord"), object: nil)
        }
    }
}
