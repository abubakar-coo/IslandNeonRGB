import SwiftUI

@main
struct IslandNeonRGBApp: App {
    @State private var settings = NeonSettings()
    @State private var activityManager = NeonActivityManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .environment(activityManager)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            activityManager.scenePhaseChanged(phase)
        }
    }
}
