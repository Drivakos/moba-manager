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
        GBScreenHeader(
            title: "Transfer Market",
            subtitle: "\(gameState.playerDatabase.freeAgents.count) Free Agents Available"
        )
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

        return HStack(spacing: 0) {
            // Role color accent strip
            Rectangle()
                .fill(isFree ? Color.gbLight : Color.gbDarkest)
                .frame(width: 4)

            HStack(spacing: 10) {
                // OVR block
                VStack(spacing: 1) {
                    Text(player.role.abbreviation)
                        .font(.custom(GB.font, size: 9))
                        .foregroundColor(.gbDarkest)
                        .frame(width: 38)
                        .padding(.vertical, 2)
                        .background(isFree ? Color.gbLight : Color.gbDark)
                    Text("\(player.stats.overall)")
                        .font(.custom(GB.font, size: 18))
                        .foregroundColor(isFree ? .gbLightest : .gbDark)
                    Text("OVR")
                        .font(.custom(GB.fontMono, size: 7))
                        .foregroundColor(.gbDark)
                    Text(player.starDisplay)
                        .font(.system(size: 7))
                        .foregroundColor(isFree ? .gbLight : .gbDarkest)
                }
                .frame(width: 42)

                // Info column
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(player.name.uppercased())
                            .font(.custom(GB.font, size: 11))
                            .foregroundColor(isFree ? .gbLightest : .gbDark)
                        Text("「\(player.tag)」")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                    }
                    HStack(spacing: 8) {
                        Text("AGE \(player.age)")
                            .font(.custom(GB.fontMono, size: 8))
                            .foregroundColor(.gbDark)
                        Text(player.personality.rawValue.uppercased())
                            .font(.custom(GB.fontMono, size: 8))
                            .foregroundColor(.gbDark)
                    }
                    // Segmented mini stats
                    VStack(alignment: .leading, spacing: 2) {
                        miniStatRow("MCH", player.stats.mechanics, isFree: isFree)
                        miniStatRow("SNS", player.stats.gameSense, isFree: isFree)
                        miniStatRow("TM",  player.stats.teamwork,  isFree: isFree)
                        miniStatRow("MNT", player.stats.mental,    isFree: isFree)
                    }
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

                // Wage + action
                VStack(spacing: 5) {
                    VStack(spacing: 1) {
                        Text("$\(player.salary)")
                            .font(.custom(GB.font, size: 12))
                            .foregroundColor(isFree ? .gbLightest : .gbDark)
                        Text("/match")
                            .font(.custom(GB.fontMono, size: 7))
                            .foregroundColor(.gbDark)
                    }
                    if isFree {
                        Button {
                            if canSign { confirmPlayer = player }
                        } label: {
                            Text(gameState.canSign ? "SIGN" : "FULL")
                                .font(.custom(GB.font, size: 10))
                                .foregroundColor(canSign ? .gbDarkest : .gbDark)
                                .frame(width: 44)
                                .padding(.vertical, 5)
                                .background(canSign ? Color.gbLightest : Color.gbDarkest)
                                .overlay(
                                    ZStack {
                                        Rectangle().stroke(canSign ? Color.gbLight : Color.gbDarkest, lineWidth: 1)
                                        if canSign {
                                            GBCornerBorder(color: .gbDark, lineWidth: 1, cornerSize: 5)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSign)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(isFree ? Color.gbDarkest : Color(red: 0.04, green: 0.08, blue: 0.04))
        .overlay(Rectangle().stroke(isFree ? Color.gbDark : Color.gbDarkest, lineWidth: 1))
    }

    func miniStatRow(_ label: String, _ value: Int, isFree: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.custom(GB.fontMono, size: 7))
                .foregroundColor(.gbDark)
                .frame(width: 22, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gbDarkest).frame(height: 4)
                    Rectangle()
                        .fill(isFree ? Color.gbLight : Color.gbDark)
                        .frame(width: geo.size.width * CGFloat(value) / 99, height: 4)
                }
            }
            .frame(height: 4)
        }
    }


    // MARK: - Back
    var backButton: some View {
        GBBackButton { gameState.screen = .overworld }
    }
}

// Convenience computed on PlayerRecord
private extension PlayerRecord {
    var salary: Int { player.salary }
}
