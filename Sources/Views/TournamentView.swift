import SwiftUI

// MARK: - League View
struct LeagueView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                GBScreenHeader(
                    title: "Amateur League",
                    subtitle: "Season \(gameState.league.season)  —  Matchday \(gameState.league.matchday)/\(gameState.league.teams.count)"
                )

                ScrollView {
                    VStack(spacing: 14) {
                        standingsSection
                        nextMatchSection
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }

                GBBackButton { gameState.screen = .overworld }
            }
        }
    }

    // MARK: - Standings
    var standingsSection: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Standings")

            // Column headers
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 28, alignment: .center)
                Text("TEAM")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("W").frame(width: 30, alignment: .center)
                Text("L").frame(width: 30, alignment: .center)
                Text("PTS").frame(width: 38, alignment: .center)
            }
            .font(.custom(GB.font, size: 9))
            .foregroundColor(.gbDarkest)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.gbDark)

            let entries = gameState.league.standings(
                playerWins: gameState.playerTeam.wins,
                playerLosses: gameState.playerTeam.losses,
                playerTeamName: gameState.playerTeam.name
            )
            ForEach(Array(entries.enumerated()), id: \.element.id) { rank, entry in
                standingRow(rank: rank + 1, entry: entry)
            }
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    func standingRow(rank: Int, entry: StandingEntry) -> some View {
        HStack(spacing: 0) {
            // Rank badge
            ZStack {
                Rectangle().fill(rank == 1 ? Color.gbLightest : (entry.isPlayer ? Color.gbDark : Color.gbDarkest))
                Text("\(rank)")
                    .font(.custom(GB.font, size: 10))
                    .foregroundColor(rank == 1 ? .gbDarkest : (entry.isPlayer ? .gbLightest : .gbDark))
            }
            .frame(width: 28)

            HStack(spacing: 0) {
                // Player indicator strip
                if entry.isPlayer {
                    Rectangle().fill(Color.gbLightest).frame(width: 3)
                } else {
                    Rectangle().fill(Color.clear).frame(width: 3)
                }

                Text(entry.name)
                    .font(.custom(entry.isPlayer ? GB.font : GB.fontMono, size: 11))
                    .foregroundColor(entry.isPlayer ? .gbLightest : .gbLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)

                Text("\(entry.wins)").frame(width: 30, alignment: .center)
                Text("\(entry.losses)").frame(width: 30, alignment: .center)
                Text("\(entry.points)")
                    .frame(width: 38, alignment: .center)
                    .foregroundColor(entry.isPlayer ? .gbLightest : .gbLight)
            }
            .font(.custom(GB.fontMono, size: 11))
            .foregroundColor(.gbLight)
            .padding(.vertical, 8)
        }
        .background(entry.isPlayer ? Color.gbDark : Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDarkest.opacity(0.5), lineWidth: 0.5))
    }

    // MARK: - Next Match
    var nextMatchSection: some View {
        Group {
            if let opp = gameState.league.nextOpponent {
                VStack(spacing: 0) {
                    GBSectionLabel(text: "Next Match")

                    // Prize info bar
                    HStack {
                        Spacer()
                        Text("WIN  +$5,000")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbLight)
                        Text("·")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                        Text("LOSS  +$1,500")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .background(Color.gbDark.opacity(0.5))

                    // VS card
                    HStack(alignment: .center, spacing: 0) {
                        // Player side
                        VStack(alignment: .leading, spacing: 4) {
                            Text(gameState.playerTeam.name.uppercased())
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbLightest)
                            HStack(spacing: 8) {
                                Text("W \(gameState.playerTeam.wins)")
                                    .font(.custom(GB.fontMono, size: 9))
                                    .foregroundColor(.gbLight)
                                Text("L \(gameState.playerTeam.losses)")
                                    .font(.custom(GB.fontMono, size: 9))
                                    .foregroundColor(.gbDark)
                            }
                            Text("OVR \(gameState.playerTeam.averageOverall)")
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(.gbLightest)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // VS divider
                        VStack(spacing: 4) {
                            Rectangle().fill(Color.gbDark).frame(width: 1, height: 20)
                            Text("VS")
                                .font(.custom(GB.font, size: 18))
                                .foregroundColor(.gbDark)
                            Rectangle().fill(Color.gbDark).frame(width: 1, height: 20)
                        }
                        .frame(width: 40)

                        // Opponent side
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(opp.name.uppercased())
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbLight)
                            Text("CPU")
                                .font(.custom(GB.fontMono, size: 9))
                                .foregroundColor(.gbDark)
                            Text("OVR ~\(opp.averageOverall)")
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(.gbLight)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.gbDarkest)

                    // PLAY button
                    let canPlay = !gameState.playerTeam.roster.isEmpty
                    GBPrimaryButton(
                        label: canPlay ? "PLAY MATCH  ▶" : "SIGN PLAYERS TO COMPETE",
                        enabled: canPlay
                    ) {
                        gameState.startLeagueMatch()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))

            } else {
                VStack(spacing: 10) {
                    Text("SEASON COMPLETE")
                        .font(.custom(GB.font, size: 18))
                        .foregroundColor(.gbLightest)
                    Text("New season begins shortly.")
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(.gbLight)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.gbDark)
                .overlay(
                    ZStack {
                        Rectangle().stroke(Color.gbLight, lineWidth: 1)
                        GBCornerBorder(color: .gbLightest, lineWidth: 1, cornerSize: 10)
                    }
                )
            }
        }
    }
}
