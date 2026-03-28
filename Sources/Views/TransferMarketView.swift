import SwiftUI

// MARK: - Sort Option
enum MarketSort: String, CaseIterable {
    case ovrDesc    = "OVR ↓"
    case ovrAsc     = "OVR ↑"
    case salaryAsc  = "WAGE ↓"
    case salaryDesc = "WAGE ↑"
    case potential  = "POT ↓"
}

struct TransferMarketView: View {
    @Environment(GameState.self) var gameState

    @State private var roleFilter: Role? = nil
    @State private var sortBy: MarketSort = .ovrDesc
    @State private var confirmPlayer: Player? = nil
    @State private var showSigned = false     // toggle to also show signed players

    private var filtered: [PlayerRecord] {
        var pool = showSigned
            ? gameState.playerDatabase.records
            : gameState.playerDatabase.freeAgents(role: roleFilter)

        if showSigned, let role = roleFilter {
            pool = pool.filter { $0.player.role == role }
        }

        switch sortBy {
        case .ovrDesc:    return pool.sorted { $0.player.stats.overall > $1.player.stats.overall }
        case .ovrAsc:     return pool.sorted { $0.player.stats.overall < $1.player.stats.overall }
        case .salaryAsc:  return pool.sorted { $0.player.salary < $1.player.salary }
        case .salaryDesc: return pool.sorted { $0.player.salary > $1.player.salary }
        case .potential:  return pool.sorted { $0.player.potential > $1.player.potential }
        }
    }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                budgetBar
                filterBar
                sortBar

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filtered) { record in
                            playerCard(record)
                        }
                        if filtered.isEmpty {
                            Text("No players match your filters.")
                                .font(.custom(GB.fontMono, size: 12))
                                .foregroundColor(.gbDark)
                                .padding(30)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                backButton
            }
        }
        .alert("SIGN PLAYER?", isPresented: Binding(
            get: { confirmPlayer != nil },
            set: { if !$0 { confirmPlayer = nil } }
        )) {
            Button("SIGN") {
                if let p = confirmPlayer { gameState.signPlayer(p) }
                confirmPlayer = nil
            }
            Button("CANCEL", role: .cancel) { confirmPlayer = nil }
        } message: {
            if let p = confirmPlayer {
                Text("\(p.name) — $\(p.salary)/match\nRoster slots: \(gameState.playerTeam.roster.count)/5")
            }
        }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            VStack(spacing: 2) {
                Text("TRANSFER MARKET")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
                Text("\(gameState.playerDatabase.freeAgents.count) FREE AGENTS AVAILABLE")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbLight)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Budget bar
    var budgetBar: some View {
        HStack {
            Text("$\(gameState.funds)")
                .font(.custom(GB.font, size: 12))
                .foregroundColor(.gbLightest)
            Text("BUDGET")
                .font(.custom(GB.fontMono, size: 9))
                .foregroundColor(.gbDark)
            Spacer()
            Text("$\(gameState.weeklyWages)/match")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLight)
            Text("WAGES")
                .font(.custom(GB.fontMono, size: 9))
                .foregroundColor(.gbDark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.gbDark)
    }

    // MARK: - Role Filter
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip("ALL", selected: roleFilter == nil) { roleFilter = nil }
                ForEach(Role.allCases) { role in
                    filterChip(role.abbreviation, selected: roleFilter == role) {
                        roleFilter = role
                    }
                }
                Divider()
                    .frame(height: 20)
                    .background(Color.gbDark)
                filterChip(showSigned ? "FREE ONLY" : "SHOW ALL", selected: showSigned) {
                    showSigned.toggle()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 0.5))
    }

    // MARK: - Sort Bar
    var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text("SORT:")
                    .font(.custom(GB.fontMono, size: 9))
                    .foregroundColor(.gbDark)
                ForEach(MarketSort.allCases, id: \.self) { option in
                    filterChip(option.rawValue, selected: sortBy == option) {
                        sortBy = option
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 0.5))
    }

    func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom(selected ? GB.font : GB.fontMono, size: 10))
                .foregroundColor(selected ? .gbDarkest : .gbDark)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selected ? Color.gbLightest : Color.gbDarkest)
                .overlay(Rectangle().stroke(selected ? Color.gbLight : Color.gbDark, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player Card
    func playerCard(_ record: PlayerRecord) -> some View {
        let player = record.player
        let isFree = record.status.isFree
        let canSign = isFree && gameState.canSign

        return HStack(spacing: 10) {
            // OVR + Role column
            VStack(spacing: 2) {
                Text(player.role.abbreviation)
                    .font(.custom(GB.font, size: 9))
                    .foregroundColor(.gbDarkest)
                    .frame(width: 38)
                    .padding(.vertical, 2)
                    .background(isFree ? Color.gbLight : Color.gbDark)
                Text("\(player.stats.overall)")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(isFree ? .gbLightest : .gbDark)
                Text("OVR")
                    .font(.custom(GB.fontMono, size: 8))
                    .foregroundColor(.gbDark)
                // Potential stars
                Text(player.starDisplay)
                    .font(.system(size: 8))
                    .foregroundColor(isFree ? .gbLight : .gbDark)
            }
            .frame(width: 42)

            // Name / info column
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(player.name.uppercased())
                        .font(.custom(GB.font, size: 11))
                        .foregroundColor(isFree ? .gbLightest : .gbDark)
                    Text("「\(player.tag)」")
                        .font(.custom(GB.fontMono, size: 9))
                        .foregroundColor(.gbDark)
                }
                Text("Age \(player.age)  \(player.personality.rawValue)")
                    .font(.custom(GB.fontMono, size: 9))
                    .foregroundColor(.gbDark)
                // Mini stat bar row
                HStack(spacing: 6) {
                    miniStat("MCH", player.stats.mechanics)
                    miniStat("SNS", player.stats.gameSense)
                    miniStat("TM",  player.stats.teamwork)
                    miniStat("MNT", player.stats.mental)
                }
                // Status badge
                if !isFree {
                    Text(record.status.label)
                        .font(.custom(GB.fontMono, size: 8))
                        .foregroundColor(.gbDarkest)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gbDark)
                }
            }

            Spacer(minLength: 4)

            // Salary + action column
            VStack(spacing: 4) {
                Text("$\(player.salary)")
                    .font(.custom(GB.font, size: 11))
                    .foregroundColor(isFree ? .gbLightest : .gbDark)
                Text("/match")
                    .font(.custom(GB.fontMono, size: 8))
                    .foregroundColor(.gbDark)

                if isFree {
                    Button {
                        if canSign { confirmPlayer = player }
                    } label: {
                        Text(gameState.canSign ? "SIGN" : "FULL")
                            .font(.custom(GB.font, size: 10))
                            .foregroundColor(canSign ? .gbDarkest : .gbDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(canSign ? Color.gbLightest : Color.gbDark)
                            .overlay(Rectangle().stroke(canSign ? Color.gbDark : Color.gbDarkest, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSign)
                }
            }
        }
        .padding(10)
        .background(isFree ? Color.gbDarkest : Color(red: 0.04, green: 0.10, blue: 0.04))
        .overlay(Rectangle().stroke(isFree ? Color.gbDark : Color.gbDarkest, lineWidth: 1))
    }

    func miniStat(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.custom(GB.fontMono, size: 7))
                .foregroundColor(.gbDark)
            Text("\(value)")
                .font(.custom(GB.fontMono, size: 8))
                .foregroundColor(.gbLight)
        }
    }

    // MARK: - Back
    var backButton: some View {
        Button {
            gameState.screen = .overworld
        } label: {
            Text("◀ BACK")
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbLightest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gbDark)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// Convenience computed on PlayerRecord
private extension PlayerRecord {
    var salary: Int { player.salary }
}
