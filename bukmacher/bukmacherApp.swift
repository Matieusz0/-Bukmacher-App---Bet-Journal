import SwiftUI
import SwiftData

@main
struct bukmacherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: BetEntry.self)
    }
}
