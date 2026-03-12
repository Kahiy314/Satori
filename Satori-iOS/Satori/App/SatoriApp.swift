import SwiftUI

@main
struct SatoriApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @StateObject private var audioService = AudioService()
    @StateObject private var hapticService = HapticService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioService)
                .environmentObject(hapticService)
                .preferredColorScheme(resolvedScheme)
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // follow system
        }
    }
}
