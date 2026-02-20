import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BetEntry.date, order: .reverse) private var entries: [BetEntry]
    
    @AppStorage("username") var username: String = ""
    @AppStorage("selectedCurrency") var selectedCurrency: String = "PLN"
    @AppStorage("appLanguage") var appLanguage: String = "PL"
    
    @State private var isShowingAddSheet = false
    @State private var isShowingNameSetup = false
    @State private var isShowingSettings = false
    @State private var tempName: String = ""
    
    // Przeniesienie tłumaczeń do statycznej stałej odciąża kompilator Xcode 15.4
    private static let translations: [String: [String: String]] = [
        "PL": [
            "welcome": "Witaj",
            "ready": "Gotowy na emocje?",
            "balance": "Bilans całkowity",
            "total_stake": "Łącznie postawione",
            "total_win": "Zysk z wygranych",
            "no_bets": "Brak kuponów",
            "add_first": "Dodaj swój pierwszy kupon, aby śledzić bilans.",
            "settings": "Ustawienia",
            "today": "Dzisiaj",
            "yesterday": "Wczoraj",
            "new_bet": "Nowy Kupon",
            "type": "Typ",
            "win": "Wygrana",
            "loss": "Przegrana",
            "stake": "Stawka",
            "odds": "Kurs",
            "details": "Szczegóły",
            "potential": "Potencjalna",
            "additional": "Dodatkowe",
            "date": "Data",
            "note": "Notatka",
            "cancel": "Anuluj",
            "add": "Dodaj",
            "save": "Zapisz",
            "edit": "Edytuj",
            "delete": "Usuń kupon",
            "financial_data": "Dane finansowe",
            "gross_win": "Wygrana brutto",
            "net_profit": "Zysk netto",
            "loss_label": "Strata",
            "day": "Dzień",
            "details_title": "Szczegóły",
            "edit_title": "Edytuj Kupon"
        ],
        "EN": [
            "welcome": "Welcome",
            "ready": "Ready for the thrills?",
            "balance": "Total Balance",
            "total_stake": "Total Stake",
            "total_win": "Total Winnings",
            "no_bets": "No Bets Yet",
            "add_first": "Add your first bet to track your balance.",
            "settings": "Settings",
            "today": "Today",
            "yesterday": "Yesterday",
            "new_bet": "New Bet",
            "type": "Type",
            "win": "Win",
            "loss": "Loss",
            "stake": "Stake",
            "odds": "Odds",
            "details": "Details",
            "potential": "Potential",
            "additional": "Additional",
            "date": "Date",
            "note": "Note",
            "cancel": "Cancel",
            "add": "Add",
            "save": "Save",
            "edit": "Edit",
            "delete": "Delete Bet",
            "financial_data": "Financial Data",
            "gross_win": "Gross Win",
            "net_profit": "Net Profit",
            "loss_label": "Loss",
            "day": "Day",
            "details_title": "Details",
            "edit_title": "Edit Bet"
        ]
    ]

    // Prosty system tłumaczeń
    private func t(_ key: String) -> String {
        return Self.translations[appLanguage]?[key] ?? key
    }

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
    
    var totalStake: Double {
        entries.reduce(0) { $0 + $1.stake }
    }
    
    var totalWinnings: Double {
        entries.reduce(0) { result, entry in
            if entry.type == "Wygrana" {
                return result + (entry.winAmount - entry.stake)
            }
            return result
        }
    }
    
    // Pomocnik do formatowania walut z przelicznikiem
    private func formatValue(_ value: Double, showPlus: Bool = false) -> String {
        let converted: Double
        let symbol: String
        
        switch selectedCurrency {
        case "EUR":
            converted = value / 4.30
            symbol = "€"
        case "USD":
            converted = value / 4.00
            symbol = "$"
        default:
            converted = value
            symbol = "PLN"
        }
        
        let plusSign = (showPlus && value > 0) ? "+" : ""
        
        if selectedCurrency == "PLN" {
            return String(format: "%@%.2f PLN", plusSign, converted)
        } else {
            return String(format: "%@%@%.2f", plusSign, symbol, converted)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if entries.isEmpty {
                    ContentUnavailableView(t("no_bets"), systemImage: "ticket", description: Text(t("add_first")))
                } else {
                    List {
                        // Nagłówek powitalny 2026
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(t("welcome")), \(username)!")
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.primary, .primary.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                    )
                                
                                Text(t("ready"))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 20))

                        // Karuzela Statystyk v1.2
                        Section {
                            TabView {
                                statCard(title: t("balance"), 
                                         value: totalBalance, 
                                         isCurrency: true, 
                                         colors: totalBalance >= 0 ? [.green, .teal] : [.red, .orange], 
                                         icon: "chart.line.uptrend.xyaxis")
                                
                                statCard(title: t("total_stake"), 
                                         value: totalStake, 
                                         isCurrency: false, 
                                         colors: [.blue, .indigo], 
                                         icon: "arrow.up.forward.circle")
                                
                                statCard(title: t("total_win"), 
                                         value: totalWinnings, 
                                         isCurrency: false, 
                                         colors: [.mint, .green],
                                         icon: "trophy.fill")
                            }
                            .frame(height: 180)
                            .tabViewStyle(.page(indexDisplayMode: .always))
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.top, -10)

                        // Historia
                        ForEach(groupedEntries, id: \.key) { date, dayEntries in
                            Section(header: 
                                Text(formatDate(date))
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, -8)
                                    .padding(.top, 5)
                            ) {
                                ForEach(dayEntries) { entry in
                                    ZStack {
                                        NavigationLink(destination: EntryDetailView(entry: entry)) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        entryRow(entry)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 3, leading: 20, bottom: 3, trailing: 20))
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in
                                    deleteEntries(offsets: offsets, from: dayEntries)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 100, for: .scrollContent)
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
            .safeAreaInset(edge: .bottom) {
                Text("v1.2 | made by Matieusz")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                if username.isEmpty { isShowingNameSetup = true }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddEntrySheet().presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $isShowingNameSetup) {
                nameSetupView
            }
            .sensoryFeedback(.success, trigger: entries.count)
        }
    }
    
    // Nowoczesny komponent karty statystyk 2026
    private func statCard(title: String, value: Double, isCurrency: Bool, colors: [Color], icon: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2.bold())
                Text(title)
                    .font(.caption.bold())
                    .textCase(.uppercase)
            }
            .foregroundStyle(.secondary)
            
            Text(formatValue(value, showPlus: isCurrency))
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: colors[0].opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 35)
    }
    
    // Nowoczesny ekran ustawiania nazwy
    private var nameSetupView: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom))
                    
                    Text("Jak Cię nazywać?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                
                TextField("Twoje imię (np. Matieusz)", text: $tempName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                    .padding(.horizontal, 40)
                
                Button(action: {
                    if !tempName.isEmpty {
                        username = tempName
                        isShowingNameSetup = false
                    }
                }) {
                    Text("Zaczynamy")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tempName.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 60)
                .disabled(tempName.isEmpty)
            }
        }
    }
    
    private func entryRow(_ entry: BetEntry) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill((entry.type == "Wygrana" ? Color.green : Color.red).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.type == "Wygrana" ? "checkmark" : "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(entry.type == "Wygrana" ? .green : .red)
            }
            
            VStack(alignment: .leading) {
                Text(entry.note.isEmpty ? (entry.type == "Wygrana" ? t("win") : t("loss")) : entry.note)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(t("odds")): \(String(format: "%.2f", entry.odds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            let value = entry.type == "Wygrana" ? (entry.winAmount - entry.stake) : entry.stake
            Text(formatValue(entry.type == "Wygrana" ? value : -value, showPlus: true))
                .font(.system(.body, design: .rounded).bold())
                .foregroundColor(entry.type == "Wygrana" ? .green : .red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return t("today") }
        if Calendar.current.isDateInYesterday(date) { return t("yesterday") }
        return date.formatted(date: .long, time: .omitted)
    }
    
    private func deleteEntries(offsets: IndexSet, from dayEntries: [BetEntry]) {
        for index in offsets {
            modelContext.delete(dayEntries[index])
        }
    }
}

struct SettingsView: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("selectedCurrency") var selectedCurrency: String = "PLN"
    @AppStorage("appLanguage") var appLanguage: String = "PL"
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom))
                        
                        VStack(alignment: .leading) {
                            Text(username)
                                .font(.headline)
                            Text(appLanguage == "PL" ? "Użytkownik Premium" : "Premium User")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(appLanguage == "PL" ? "Konto" : "Account") {
                    HStack {
                        Label(appLanguage == "PL" ? "Twoje imię" : "Your Name", systemImage: "pencil")
                        Spacer()
                        TextField("", text: $username)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(appLanguage == "PL" ? "Preferencje" : "Preferences") {
                    Picker(selection: $appLanguage) {
                        Text("Polski 🇵🇱").tag("PL")
                        Text("English 🇺🇸").tag("EN")
                    } label: {
                        Label(appLanguage == "PL" ? "Język" : "Language", systemImage: "globe")
                    }
                    
                    Picker(selection: $selectedCurrency) {
                        Text("PLN (Złoty)").tag("PLN")
                        Text("EUR (€)").tag("EUR")
                        Text("USD ($)").tag("USD")
                    } label: {
                        Label(appLanguage == "PL" ? "Waluta" : "Currency", systemImage: "dollarsign.circle")
                    }
                }
                
                Section(appLanguage == "PL" ? "O aplikacji" : "About") {
                    HStack {
                        Label(appLanguage == "PL" ? "Wersja" : "Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.2.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(appLanguage == "PL" ? "Ustawienia" : "Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Gotowe") { dismiss() }
            }
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
    @AppStorage("appLanguage") var appLanguage: String = "PL"

    // Wyciągamy kolory tutaj, aby odciążyć kompilator
    private var accentColor: Color {
        type == "Wygrana" ? .green : .red
    }
    
    private var buttonGradient: LinearGradient {
        stakeText.isEmpty ? 
            LinearGradient(colors: [.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing) :
            LinearGradient(colors: [.blue, .teal], startPoint: .leading, endPoint: .trailing)
    }

    private func t(_ key: String) -> String {
        let translations: [String: [String: String]] = [
            "PL": [
                "new_bet": "Nowy Kupon",
                "type": "Typ",
                "win": "Wygrana",
                "loss": "Przegrana",
                "stake": "Stawka",
                "odds": "Kurs",
                "details": "Szczegóły",
                "potential": "Potencjalna",
                "additional": "Dodatkowe",
                "date": "Data",
                "note": "Notatka",
                "cancel": "Anuluj",
                "add": "Dodaj"
            ],
            "EN": [
                "new_bet": "New Bet",
                "type": "Type",
                "win": "Win",
                "loss": "Loss",
                "stake": "Stake",
                "odds": "Odds",
                "details": "Details",
                "potential": "Potential",
                "additional": "Additional",
                "date": "Date",
                "note": "Note",
                "cancel": "Cancel",
                "add": "Add"
            ]
        ]
        return translations[appLanguage]?[key] ?? key
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Uproszczone tło
                Color(uiColor: .systemBackground).ignoresSafeArea()
                accentColor.opacity(0.08).ignoresSafeArea()
                
                // Warstwa do zamykania klawiatury
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { hideKeyboard() }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Customowy selektor typu (Win/Loss)
                        HStack(spacing: 0) {
                            ForEach(["Wygrana", "Przegrana"], id: \.self) { option in
                                Button {
                                    withAnimation(.spring()) { type = option }
                                } label: {
                                    Text(option == "Wygrana" ? t("win") : t("loss"))
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(type == option ? accentColor : Color.clear)
                                        .foregroundColor(type == option ? .white : .primary)
                                        .cornerRadius(12)
                                }
                                .padding(4)
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        .padding(.horizontal)

                        // Karta Kwot
                        VStack(spacing: 20) {
                            InputField(icon: "banknote.fill", label: t("stake"), text: $stakeText)
                            InputField(icon: "chart.line.uptrend.xyaxis", label: t("odds"), text: $oddsText)
                            InputField(icon: type == "Wygrana" ? "trophy.fill" : "target", 
                                       label: type == "Wygrana" ? t("win") : t("potential"), 
                                       text: $winAmountText)
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal)

                        // Karta Dodatków
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.blue)
                                DatePicker(t("date"), selection: $date, displayedComponents: .date)
                                    .font(.subheadline)
                            }
                            
                            Divider()
                            
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(.blue)
                                TextField(t("note"), text: $note)
                                    .font(.body)
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Przycisk Akcji
                        Button {
                            save()
                            dismiss()
                        } label: {
                            Text(t("add"))
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(buttonGradient)
                                .cornerRadius(20)
                                .shadow(color: (stakeText.isEmpty ? Color.clear : Color.blue.opacity(0.3)), radius: 10, y: 5)
                        }
                        .disabled(stakeText.isEmpty)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    }
                    .padding(.vertical)
                }
                .onTapGesture { hideKeyboard() }
            }
            .navigationTitle(t("new_bet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(t("cancel")) { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
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

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Pomocniczy komponent do pól tekstowych 2026
struct InputField: View {
    let icon: String
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.caption).foregroundStyle(.blue)
                Text(label).font(.caption.bold()).foregroundStyle(.secondary).textCase(.uppercase)
            }
            TextField("0.00", text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 22, weight: .bold, design: .rounded))
        }
    }
}

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: BetEntry
    
    @State private var isShowingEditSheet = false
    @AppStorage("selectedCurrency") var selectedCurrency: String = "PLN"
    @AppStorage("appLanguage") var appLanguage: String = "PL"

    private func t(_ key: String) -> String {
        let translations: [String: [String: String]] = [
            "PL": [
                "win": "Wygrana",
                "loss": "Przegrana",
                "stake": "Stawka",
                "odds": "Kurs",
                "edit": "Edytuj",
                "delete": "Usuń kupon",
                "financial_data": "Dane finansowe",
                "gross_win": "Wygrana brutto",
                "net_profit": "Zysk netto",
                "potential": "Potencjalna wygrana",
                "loss_label": "Strata",
                "day": "Dzień",
                "details_title": "Szczegóły"
            ],
            "EN": [
                "win": "Win",
                "loss": "Loss",
                "stake": "Stake",
                "odds": "Odds",
                "edit": "Edit",
                "delete": "Delete Bet",
                "financial_data": "Financial Data",
                "gross_win": "Gross Win",
                "net_profit": "Net Profit",
                "potential": "Potential Win",
                "loss_label": "Loss",
                "day": "Day",
                "details_title": "Details"
            ]
        ]
        return translations[appLanguage]?[key] ?? key
    }

    private func formatValue(_ value: Double, showPlus: Bool = false) -> String {
        let converted: Double
        let symbol: String
        switch selectedCurrency {
        case "EUR":
            converted = value / 4.30
            symbol = "€"
        case "USD":
            converted = value / 4.00
            symbol = "$"
        default:
            converted = value
            symbol = "PLN"
        }
        let plusSign = (showPlus && value > 0) ? "+" : ""
        return selectedCurrency == "PLN" ? 
            String(format: "%@%.2f PLN", plusSign, converted) : 
            String(format: "%@%@%.2f", plusSign, symbol, converted)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Hero Card - Status Kuponu
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill((entry.type == "Wygrana" ? Color.green : Color.red).opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: entry.type == "Wygrana" ? "trophy.fill" : "xmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(entry.type == "Wygrana" ? .yellow : .red)
                    }
                    
                    VStack(spacing: 5) {
                        Text(entry.type == "Wygrana" ? t("win") : t("loss"))
                            .font(.system(size: 32, weight: .black, design: .rounded))
                        
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(RoundedRectangle(cornerRadius: 35).fill(.ultraThinMaterial))
                
                // Sekcja Finansowa
                VStack(spacing: 20) {
                    HStack {
                        Text(t("financial_data")).font(.headline).foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    VStack(spacing: 15) {
                        DetailRow(label: t("stake"), value: formatValue(entry.stake))
                        DetailRow(label: t("odds"), value: String(format: "%.2f", entry.odds))
                        Divider()
                        if entry.type == "Wygrana" {
                            DetailRow(label: t("gross_win"), value: formatValue(entry.winAmount))
                            DetailRow(label: t("net_profit"), value: formatValue(entry.winAmount - entry.stake, showPlus: true), color: .green)
                        } else {
                            DetailRow(label: t("potential"), value: formatValue(entry.potentialWin))
                            DetailRow(label: t("loss_label"), value: formatValue(entry.stake), color: .red)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial))
                }
                
                // Sekcja Daty
                VStack(spacing: 15) {
                    DetailRow(label: t("day"), value: entry.date.formatted(date: .long, time: .omitted))
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                
                // Przycisk Usuwania
                Button(role: .destructive) {
                    modelContext.delete(entry)
                    dismiss()
                } label: {
                    Text(t("delete"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.red.opacity(0.1)))
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle(t("details_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(t("edit")) { isShowingEditSheet = true }
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
    @AppStorage("appLanguage") var appLanguage: String = "PL"

    private func t(_ key: String) -> String {
        let translations: [String: [String: String]] = [
            "PL": [
                "edit_title": "Edytuj Kupon",
                "type": "Typ",
                "win": "Wygrana",
                "loss": "Przegrana",
                "stake": "Stawka",
                "odds": "Kurs",
                "potential": "Potencjalna",
                "date": "Data",
                "note": "Notatka",
                "cancel": "Anuluj",
                "save": "Zapisz"
            ],
            "EN": [
                "edit_title": "Edit Bet",
                "type": "Type",
                "win": "Win",
                "loss": "Loss",
                "stake": "Stake",
                "odds": "Odds",
                "potential": "Potential",
                "date": "Date",
                "note": "Note",
                "cancel": "Cancel",
                "save": "Save"
            ]
        ]
        return translations[appLanguage]?[key] ?? key
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker(t("type"), selection: $entry.type) {
                        Text(t("win")).tag("Wygrana")
                        Text(t("loss")).tag("Przegrana")
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))

                    VStack(spacing: 15) {
                        HStack {
                            Text(t("stake"))
                            Spacer()
                            TextField("0.00", text: $stakeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                        Divider()
                        HStack {
                            Text(t("odds"))
                            Spacer()
                            TextField("1.00", text: $oddsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                        Divider()
                        HStack {
                            Text(entry.type == "Wygrana" ? t("win") : t("potential"))
                            Spacer()
                            TextField("0.00", text: $winAmountText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                }
                .padding()
            }
            .navigationTitle(t("edit_title"))
            .onAppear {
                stakeText = String(format: "%.2f", entry.stake)
                oddsText = String(format: "%.2f", entry.odds)
                winAmountText = String(format: "%.2f", entry.type == "Wygrana" ? entry.winAmount : entry.potentialWin)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("save")) {
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
