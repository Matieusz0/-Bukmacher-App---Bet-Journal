import SwiftUI
import SwiftData

@main
struct bukmacherApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([BetEntry.self])
            let config = ModelConfiguration(schema: schema, allowsSave: true)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Błąd krytyczny SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}