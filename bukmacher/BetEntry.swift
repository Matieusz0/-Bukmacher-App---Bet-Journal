import Foundation
import SwiftData

@Model
final class BetEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var type: String = "Wygrana"
    var stake: Double = 0.0
    var odds: Double = 1.0
    var winAmount: Double = 0.0
    var potentialWin: Double = 0.0
    var note: String = ""

    init(type: String, stake: Double, odds: Double, winAmount: Double = 0, potentialWin: Double = 0, date: Date = .now, note: String = "") {
        self.id = UUID()
        self.type = type
        self.stake = stake
        self.odds = odds
        self.winAmount = winAmount
        self.potentialWin = potentialWin
        self.date = date
        self.note = note
    }
}
