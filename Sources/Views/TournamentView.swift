import SwiftUI

// MARK: - Tournament Bracket
struct TournamentBracketView: View {
    @Environment(GameState.self) var gameState

    private var opponents: [Team] {
        let names = ["Shadow Force", "Pixel Raiders", "Ghost Protocol", "Iron Surge", "Neon Wolves"]
        return names.map { Team.generateOpponent(name: $0, chapter: gameState.chapter) }
    }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 8) {
                        Text("SELECT OPPONENT")
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(.gbLight)
                            .padding(.top, 16)

                        ForEach(opponents.prefix(gameState.chapter + 2)) { opp in
                            OpponentRowView(opponent: opp) {
                                gameState.activeOpponent = opp
                                gameState.screen = .tactics
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }

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
    }

    var headerBar: some View {
        ZStack {
            Color.gbDark
            VStack(spacing: 2) {
                Text("ARENA — TOURNAMENT")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
                Text("CHAPTER \(gameState.chapter)")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbLight)
            }
        }
        .frame(height: 52)
    }
}

// MARK: - Opponent Row
struct OpponentRowView: View {
    let opponent: Team
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(opponent.name.uppercased())
                        .font(.custom(GB.font, size: 13))
                        .foregroundColor(.gbLightest)
                    Text("W:\(opponent.wins) L:\(opponent.losses)  AVG OVR: \(opponent.averageOverall)")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                }
                Spacer()
                Text("FIGHT ▶")
                    .font(.custom(GB.font, size: 12))
                    .foregroundColor(.gbLightest)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gbDark)
                    .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
            }
            .padding(10)
            .background(Color.gbDarkest)
            .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
