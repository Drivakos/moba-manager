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
                GBScreenHeader(
                    title: "Tactics",
                    subtitle: "vs \(opponent.name)  ·  Chapter \(gameState.chapter)"
                )

                // Advisor
                GBDialogueBar(text: "REEVES: \"Pick your strategy, \(gameState.managerName). Their OVR is \(opponent.averageOverall).\"")
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(MatchTactic.allCases, id: \.self) { tactic in
                            TacticCard(tactic: tactic, isSelected: selected == tactic) {
                                selected = tactic
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                }

                Spacer(minLength: 0)
                confirmBar
            }
        }
        .onAppear { selected = gameState.selectedTactic }
    }

    // MARK: - Bottom Bar
    var confirmBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.gbDark).frame(height: 1)

            HStack(spacing: 10) {
                // BACK — secondary weight
                Button {
                    gameState.screen = .tournamentBracket
                } label: {
                    Text("◀  BACK")
                        .font(.custom(GB.font, size: 13))
                        .foregroundColor(.gbLight)
                        .frame(width: 100)
                        .padding(.vertical, 14)
                        .background(Color.gbDarkest)
                        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // FIGHT — dominant call to action
                Button {
                    gameState.selectedTactic = selected
                    gameState.screen = .matchSim
                } label: {
                    HStack(spacing: 8) {
                        Text("FIGHT!")
                            .font(.custom(GB.font, size: 18))
                        Text("▶")
                            .font(.custom(GB.font, size: 14))
                    }
                    .foregroundColor(.gbDarkest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gbLightest)
                    .overlay(
                        ZStack {
                            Rectangle().stroke(Color.gbLight, lineWidth: 2)
                            GBCornerBorder(color: .gbDark, lineWidth: 1.5, cornerSize: 8)
                        }
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .padding(.bottom, 16)
        }
        .background(Color.gbDarkest)
    }
}

// MARK: - Tactic Card
struct TacticCard: View {
    let tactic: MatchTactic
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Left accent + name badge
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(isSelected ? Color.gbLightest : Color.gbDark)
                        .frame(width: 5)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Text(tactic.rawValue.uppercased())
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(isSelected ? .gbLightest : .gbLight)
                            .frame(minWidth: 80, alignment: .leading)

                        Spacer()

                        if isSelected {
                            Text("✓  SELECTED")
                                .font(.custom(GB.font, size: 10))
                                .foregroundColor(.gbLightest)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.gbDarkest)
                                .overlay(Rectangle().stroke(Color.gbLightest, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    Rectangle()
                        .fill(isSelected ? Color.gbDark.opacity(0.5) : Color.gbDarkest.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 12)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tactic.subtitle.uppercased())
                                .font(.custom(GB.font, size: 10))
                                .foregroundColor(isSelected ? .gbLight : .gbDark)
                            Text(tactic.boostedPhase)
                                .font(.custom(GB.fontMono, size: 9))
                                .foregroundColor(isSelected ? .gbLight : .gbDark)
                        }
                        Spacer()
                        Text(tactic.flavor)
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                            .italic()
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
                }
            }
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
