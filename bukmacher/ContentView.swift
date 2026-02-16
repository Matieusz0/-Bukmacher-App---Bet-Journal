import SwiftUI
import SwiftData

@Model
final class BetEntry {
    var id: UUID
    var date: Date
    var type: String
    var stake: Double
    var odds: Double
    var winAmount: Double
    var potentialWin: Double
    var note: String

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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BetEntry.date, order: .reverse) private var entries: [BetEntry]
    
    @State private var isShowingAddSheet = false
    
    // Grupowanie po dniach
    var groupedEntries: [(key: Date, value: [BetEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // Bilans: Wygrana (Zysk netto) / Przegrana (Strata stawki)
    var totalBalance: Double {
        entries.reduce(0) { result, entry in
            if entry.type == "Wygrana" {
                return result + (entry.winAmount - entry.stake)
            } else {
                return result - entry.stake
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if entries.isEmpty {
                    ContentUnavailableView("Brak kuponów", systemImage: "ticket", description: Text("Dodaj swój pierwszy kupon, aby śledzić bilans."))
                } else {
                    List {
                        // Karta Bilansu 2026
                        Section {
                            VStack(spacing: 12) {
                                Text("Bilans całkowity")
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)
                                
                                Text(String(format: "%@%.2f PLN", totalBalance >= 0 ? "+" : "", totalBalance))
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: totalBalance >= 0 ? [.green, .teal] : [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: (totalBalance >= 0 ? Color.green : Color.red).opacity(0.2), radius: 10, y: 5)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial))
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        // Historia
                        ForEach(groupedEntries, id: \.key) { date, dayEntries in
                            Section(header: Text(formatDate(date))) {
                                ForEach(dayEntries) { entry in
                                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                                        entryRow(entry)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteEntries(offsets: offsets, from: dayEntries)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                // FAB Button
                Button(action: { isShowingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Dziennik")
            .safeAreaInset(edge: .bottom) {
                Text("v1.1 | made by Matieusz")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddEntrySheet()
            }
            .sensoryFeedback(.success, trigger: entries.count)
        }
    }
    
    private func entryRow(_ entry: BetEntry) -> some View {
        HStack {
            Image(systemName: entry.type == "Wygrana" ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(entry.type == "Wygrana" ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading) {
                Text(entry.note.isEmpty ? entry.type : entry.note)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("Kurs: \(String(format: "%.2f", entry.odds))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            let value = entry.type == "Wygrana" ? (entry.winAmount - entry.stake) : entry.stake
            Text(String(format: "%@%.2f", entry.type == "Wygrana" ? "+" : "-", value))
                .font(.system(.body, design: .rounded).bold())
                .foregroundColor(entry.type == "Wygrana" ? .green : .red)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Dzisiaj" }
        if Calendar.current.isDateInYesterday(date) { return "Wczoraj" }
        return date.formatted(date: .long, time: .omitted)
    }
    
    private func deleteEntries(offsets: IndexSet, from dayEntries: [BetEntry]) {
        for index in offsets {
            modelContext.delete(dayEntries[index])
        }
    }
}

struct AddEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var type = "Wygrana"
    @State private var stakeText = ""
    @State private var oddsText = ""
    @State private var winAmountText = ""
    @State private var note = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Typ", selection: $type) {
                        Text("Wygrana").tag("Wygrana")
                        Text("Przegrana").tag("Przegrana")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Kwota Główna") {
                    TextField("Stawka (np. 10.00)", text: $stakeText)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                }
                
                Section("Szczegóły") {
                    HStack {
                        Text("Kurs")
                        TextField("1.00", text: $oddsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(type == "Wygrana" ? "Wygrana" : "Potencjalna")
                        TextField("0.00", text: $winAmountText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Dodatkowe") {
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                    TextField("Notatka", text: $note)
                }
            }
            .navigationTitle("Nowy Kupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dodaj") {
                        save()
                        dismiss()
                    }
                    .disabled(stakeText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func save() {
        let stake = Double(stakeText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let odds = Double(oddsText.replacingOccurrences(of: ",", with: ".")) ?? 1.0
        let winVal = Double(winAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        let newEntry = BetEntry(
            type: type,
            stake: stake,
            odds: odds,
            winAmount: type == "Wygrana" ? winVal : 0,
            potentialWin: type == "Przegrana" ? winVal : 0,
            date: date,
            note: note
        )
        modelContext.insert(newEntry)
    }
}

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: BetEntry
    
    @State private var isShowingEditSheet = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 15) {
                    Image(systemName: entry.type == "Wygrana" ? "trophy.fill" : "xmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(entry.type == "Wygrana" ? .yellow : .red)
                    
                    Text(entry.type)
                        .font(.title.bold())
                    
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .listRowBackground(Color.clear)
            
            Section("Dane finansowe") {
                DetailRow(label: "Stawka", value: String(format: "%.2f PLN", entry.stake))
                DetailRow(label: "Kurs", value: String(format: "%.2f", entry.odds))
                
                if entry.type == "Wygrana" {
                    DetailRow(label: "Wygrana brutto", value: String(format: "%.2f PLN", entry.winAmount))
                    DetailRow(label: "Zysk netto", value: String(format: "%.2f PLN", entry.winAmount - entry.stake), color: .green)
                } else {
                    DetailRow(label: "Potencjalna wygrana", value: String(format: "%.2f PLN", entry.potentialWin))
                    DetailRow(label: "Strata", value: String(format: "%.2f PLN", entry.stake), color: .red)
                }
            }
            
            Section("Data") {
                DetailRow(label: "Dzień", value: entry.date.formatted(date: .long, time: .omitted))
            }
            
            Section {
                Button(role: .destructive) {
                    modelContext.delete(entry)
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Usuń kupon")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Szczegóły")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edytuj") {
                    isShowingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditEntrySheet(entry: entry)
        }
    }
}

struct EditEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: BetEntry
    
    @State private var stakeText: String = ""
    @State private var oddsText: String = ""
    @State private var winAmountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Typ", selection: $entry.type) {
                        Text("Wygrana").tag("Wygrana")
                        Text("Przegrana").tag("Przegrana")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Kwota Główna") {
                    TextField("Stawka", text: $stakeText)
                        .keyboardType(.decimalPad)
                }
                
                Section("Szczegóły") {
                    HStack {
                        Text("Kurs")
                        TextField("1.00", text: $oddsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(entry.type == "Wygrana" ? "Wygrana" : "Potencjalna")
                        TextField("0.00", text: $winAmountText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Dodatkowe") {
                    DatePicker("Data", selection: $entry.date, displayedComponents: .date)
                    TextField("Notatka", text: $entry.note)
                }
            }
            .navigationTitle("Edytuj Kupon")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                stakeText = String(format: "%.2f", entry.stake)
                oddsText = String(format: "%.2f", entry.odds)
                winAmountText = String(format: "%.2f", entry.type == "Wygrana" ? entry.winAmount : entry.potentialWin)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        let stake = Double(stakeText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let odds = Double(oddsText.replacingOccurrences(of: ",", with: ".")) ?? 1.0
        let winVal = Double(winAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        entry.stake = stake
        entry.odds = odds
        entry.winAmount = entry.type == "Wygrana" ? winVal : 0
        entry.potentialWin = entry.type == "Przegrana" ? winVal : 0
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.bold).foregroundStyle(color)
        }
    }
}