import SwiftUI

struct TrainingView: View {
    @Environment(GameState.self) var gameState
    @State private var selectedPlayer: Player? = nil
    @State private var feedbackText: String? = nil

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                if gameState.playerTeam.roster.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(gameState.playerTeam.roster) { player in
                                PlayerTrainingRow(
                                    player: player,
                                    isExpanded: selectedPlayer?.id == player.id,
                                    gameState: gameState,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.18)) {
                                            selectedPlayer = selectedPlayer?.id == player.id ? nil : player
                                        }
                                    },
                                    onTrain: { key in
                                        train(player: player, key: key)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    }
                }

                // Feedback toast
                if let feedback = feedbackText {
                    GBDialogueBar(text: feedback)
                        .padding(.horizontal, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                GBBackButton(label: "◀  BACK TO CITY") { gameState.screen = .overworld }
            }
        }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark

            HStack(spacing: 0) {
                Rectangle().fill(Color.gbDarkest).frame(width: 5)
                Spacer()
                Text("HQ TRAINING CENTER")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("BUDGET")
                        .font(.custom(GB.fontMono, size: 8))
                        .foregroundColor(.gbDark)
                    Text("$\(gameState.funds)")
                        .font(.custom(GB.font, size: 13))
                        .foregroundColor(.gbLightest)
                }
                .padding(.trailing, 14)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Empty
    var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("NO PLAYERS TO TRAIN")
                .font(.custom(GB.font, size: 13))
                .foregroundColor(.gbDark)
            Text("Recruit players first.")
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbDark)
            Spacer()
        }
    }

    // MARK: - Train Action
    private func train(player: Player, key: StatKey) {
        let cost = gameState.trainingCost(player: player, key: key)
        guard gameState.funds >= cost else {
            showFeedback("NOT ENOUGH FUNDS. Need $\(cost).")
            return
        }
        gameState.trainStat(playerID: player.id, key: key)
        // Refresh selected player from roster
        selectedPlayer = gameState.playerTeam.roster.first { $0.id == player.id }
        showFeedback("「\(player.tag)」\(key.rawValue) +3  •  -$\(cost)")
    }

    private func showFeedback(_ text: String) {
        withAnimation { feedbackText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { feedbackText = nil }
        }
    }
}

// MARK: - Player Training Row
struct PlayerTrainingRow: View {
    let player: Player
    let isExpanded: Bool
    let gameState: GameState
    let onTap: () -> Void
    let onTrain: (StatKey) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row
            Button(action: onTap) {
                HStack {
                    Text(player.role.abbreviation)
                        .font(.custom(GB.font, size: 10))
                        .foregroundColor(.gbDarkest)
                        .frame(width: 36, height: 22)
                        .background(Color.gbLight)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name.uppercased())
                            .font(.custom(GB.font, size: 12))
                            .foregroundColor(.gbLightest)
                        Text("Lv.\(player.level)  OVR \(player.stats.overall)")
                            .font(.custom(GB.fontMono, size: 10))
                            .foregroundColor(.gbLight)
                    }

                    Spacer()

                    // XP bar
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("XP")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.gbDarkest).frame(height: 5)
                                Rectangle()
                                    .fill(Color.gbLightest)
                                    .frame(width: geo.size.width * CGFloat(player.xp) / CGFloat(max(1, player.xpToNextLevel)), height: 5)
                            }
                        }
                        .frame(width: 60, height: 5)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gbDark)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gbDark)
            }
            .buttonStyle(.plain)

            // Expanded stat training
            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(StatKey.allCases, id: \.self) { key in
                        StatTrainRow(
                            label: key.rawValue,
                            value: player.stats[key],
                            cost: gameState.trainingCost(player: player, key: key),
                            canAfford: gameState.funds >= gameState.trainingCost(player: player, key: key),
                            isPrimary: player.role.statBias == key
                        ) {
                            onTrain(key)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gbDarkest.opacity(0.8))
            }
        }
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1))
    }
}

// MARK: - Stat Train Row
struct StatTrainRow: View {
    let label: String
    let value: Int
    let cost: Int
    let canAfford: Bool
    let isPrimary: Bool
    let onTrain: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Label + primary marker
            HStack(spacing: 3) {
                if isPrimary {
                    Text("★")
                        .font(.custom(GB.fontMono, size: 9))
                        .foregroundColor(.gbLightest)
                }
                Text(label)
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbLight)
            }
            .frame(width: 62, alignment: .leading)

            // Stat bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gbDarkest).frame(height: 7)
                    Rectangle()
                        .fill(barColor(value))
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 7)
                }
            }
            .frame(height: 7)

            Text("\(value)")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLightest)
                .frame(width: 24, alignment: .trailing)

            // Train button
            Button(action: onTrain) {
                Text("+3 $\(cost)")
                    .font(.custom(GB.font, size: 9))
                    .foregroundColor(canAfford ? .gbDarkest : .gbDark)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(canAfford ? Color.gbLightest : Color.gbDarkest)
                    .overlay(Rectangle().stroke(canAfford ? Color.gbLight : Color.gbDarkest, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
    }

    private func barColor(_ v: Int) -> Color {
        if v >= 75 { return .gbLightest }
        if v >= 50 { return .gbLight }
        return .gbDark
    }
}
