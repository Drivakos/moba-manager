import SwiftUI

// MARK: - League View
struct LeagueView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 12) {
                        standingsSection
                        nextMatchSection
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }

                backButton
            }
        }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            VStack(spacing: 2) {
                Text("AMATEUR LEAGUE")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
                Text("SEASON \(gameState.league.season)  —  MATCHDAY \(gameState.league.matchday)/\(gameState.league.teams.count)")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbLight)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Standings
    var standingsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("STANDINGS")
                    .font(.custom(GB.font, size: 11))
                    .foregroundColor(.gbLight)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gbDark)

            // Column headers
            HStack {
                Text("TEAM").frame(maxWidth: .infinity, alignment: .leading)
                Text("W").frame(width: 28, alignment: .center)
                Text("L").frame(width: 28, alignment: .center)
                Text("PTS").frame(width: 36, alignment: .center)
            }
            .font(.custom(GB.fontMono, size: 9))
            .foregroundColor(.gbDark)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.gbLight)

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
        HStack {
            Text("\(rank). \(entry.name)")
                .font(.custom(entry.isPlayer ? GB.font : GB.fontMono, size: 11))
                .foregroundColor(entry.isPlayer ? .gbLightest : .gbLight)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(entry.wins)").frame(width: 28, alignment: .center)
            Text("\(entry.losses)").frame(width: 28, alignment: .center)
            Text("\(entry.points)").frame(width: 36, alignment: .center)
        }
        .font(.custom(GB.fontMono, size: 11))
        .foregroundColor(entry.isPlayer ? .gbLightest : .gbLight)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(entry.isPlayer ? Color.gbDark : Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 0.5))
    }

    // MARK: - Next Match
    var nextMatchSection: some View {
        Group {
            if let opp = gameState.league.nextOpponent {
                VStack(spacing: 0) {
                    HStack {
                        Text("NEXT MATCH")
                            .font(.custom(GB.font, size: 11))
                            .foregroundColor(.gbLight)
                        Spacer()
                        Text("WIN: +$5,000  LOSS: +$1,500")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.gbDark)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(gameState.playerTeam.name)
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbLightest)
                            Text("W:\(gameState.playerTeam.wins) L:\(gameState.playerTeam.losses)")
                                .font(.custom(GB.fontMono, size: 10))
                                .foregroundColor(.gbLight)
                        }

                        Spacer()
                        Text("VS")
                            .font(.custom(GB.font, size: 16))
                            .foregroundColor(.gbDark)
                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(opp.name)
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbLight)
                            Text("OVR ~\(opp.averageOverall)")
                                .font(.custom(GB.fontMono, size: 10))
                                .foregroundColor(.gbDark)
                        }
                    }
                    .padding(12)
                    .background(Color.gbDarkest)

                    Button {
                        gameState.startLeagueMatch()
                    } label: {
                        Text("PLAY MATCH ▶")
                            .font(.custom(GB.font, size: 14))
                            .foregroundColor(gameState.playerTeam.roster.isEmpty ? .gbDark : .gbLightest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(gameState.playerTeam.roster.isEmpty ? Color.gbDarkest : Color.gbDark)
                            .overlay(Rectangle().stroke(
                                gameState.playerTeam.roster.isEmpty ? Color.gbDark : Color.gbLight,
                                lineWidth: 1
                            ))
                    }
                    .buttonStyle(.plain)
                    .disabled(gameState.playerTeam.roster.isEmpty)

                    if gameState.playerTeam.roster.isEmpty {
                        Text("Sign players in the MARKET to compete")
                            .font(.custom(GB.fontMono, size: 10))
                            .foregroundColor(.gbDark)
                            .padding(.vertical, 6)
                    }
                }
                .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))

            } else {
                VStack(spacing: 8) {
                    Text("SEASON COMPLETE")
                        .font(.custom(GB.font, size: 16))
                        .foregroundColor(.gbLightest)
                    Text("New season begins shortly.")
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(.gbLight)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.gbDark)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
            }
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
