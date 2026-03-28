import SwiftUI

struct TacticsView: View {
    @Environment(GameState.self) var gameState
    @State private var selected: MatchTactic = .adapt

    private var opponent: Team { gameState.activeOpponent ?? .empty }

    var body: some View {
        @Bindable var gs = gameState
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                advisorDialogue
                tacticList
                Spacer()
                confirmBar
            }
        }
        .onAppear { selected = gameState.selectedTactic }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            VStack(spacing: 2) {
                Text("TACTICS")
                    .font(.custom(GB.font, size: 15))
                    .foregroundColor(.gbLightest)
                Text("vs \(opponent.name.uppercased())  •  CHAPTER \(gameState.chapter)")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbLight)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Reeves advice
    var advisorDialogue: some View {
        GBDialogueBar(text: "REEVES: \"Pick your strategy, \(gameState.managerName). Their OVR is \(opponent.averageOverall).\"")
            .padding(.horizontal, 14)
            .padding(.top, 10)
    }

    // MARK: - Tactic Cards
    var tacticList: some View {
        VStack(spacing: 6) {
            ForEach(MatchTactic.allCases, id: \.self) { tactic in
                TacticCard(
                    tactic: tactic,
                    isSelected: selected == tactic
                ) {
                    selected = tactic
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    // MARK: - Confirm
    var confirmBar: some View {
        HStack(spacing: 12) {
            Button {
                gameState.screen = .tournamentBracket
            } label: {
                Text("◀ BACK")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                gameState.selectedTactic = selected
                gameState.screen = .matchSim
            } label: {
                Text("FIGHT! ▶")
                    .font(.custom(GB.font, size: 15))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gbDark)
                    .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 32)
    }
}

// MARK: - Tactic Card
struct TacticCard: View {
    let tactic: MatchTactic
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Tactic name badge
                Text(tactic.rawValue)
                    .font(.custom(GB.font, size: 13))
                    .foregroundColor(isSelected ? .gbDarkest : .gbLightest)
                    .frame(width: 60)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.gbLightest : Color.gbDark)

                VStack(alignment: .leading, spacing: 3) {
                    Text(tactic.subtitle.uppercased())
                        .font(.custom(GB.font, size: 11))
                        .foregroundColor(isSelected ? .gbLightest : .gbLight)
                    Text(tactic.boostedPhase)
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(isSelected ? .gbLight : .gbDark)
                    Text(tactic.flavor)
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(isSelected ? .gbLight : .gbDark)
                        .italic()
                }

                Spacer()

                if isSelected {
                    Text("✓")
                        .font(.custom(GB.font, size: 16))
                        .foregroundColor(.gbLightest)
                        .padding(.trailing, 6)
                }
            }
            .padding(10)
            .background(isSelected ? Color.gbDark : Color.gbDarkest)
            .overlay(
                Rectangle().stroke(
                    isSelected ? Color.gbLightest : Color.gbDark,
                    lineWidth: isSelected ? 2 : 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}
