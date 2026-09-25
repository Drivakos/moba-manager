import Foundation

// MARK: - League Team (AI opponent entry in the standings)
struct LeagueTeam: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var wins: Int = 0
    var losses: Int = 0
    var averageOverall: Int   // used to build the Team when player fights them

    var points: Int { wins * 3 }
    var played: Int { wins + losses }
}

// MARK: - Amateur League
struct AmateurLeague: Codable {
    var teams: [LeagueTeam]   // 5 AI opponents, ordered by schedule
    var matchday: Int = 0     // how many matches the player has completed (0–5)
    var season: Int = 1

    var isSeasonOver: Bool { matchday >= teams.count }

    var nextOpponent: LeagueTeam? {
        guard !isSeasonOver else { return nil }
        return teams[matchday]
    }

    /// Finishing in the top two advances the player to the next chapter.
    func playerQualified(playerWins: Int, playerLosses: Int) -> Bool {
        playerRank(playerWins: playerWins, playerLosses: playerLosses) <= 2
    }

    func playerRank(playerWins: Int, playerLosses: Int, playerTeamName: String = "") -> Int {
        let rows = standings(
            playerWins: playerWins,
            playerLosses: playerLosses,
            playerTeamName: playerTeamName
        )
        // The player's row is the only one flagged isPlayer.
        return (rows.firstIndex(where: { $0.isPlayer }) ?? rows.count - 1) + 1
    }

    // Call after each player match to simulate the rest of the matchday
    mutating func advanceMatchday(playerWon: Bool) {
        if playerWon {
            teams[matchday].losses += 1
        } else {
            teams[matchday].wins += 1
        }
        matchday += 1

        // Simulate one result for every other AI team pair this matchday
        let others = teams.indices.filter { $0 != matchday - 1 }
        for idx in others {
            if Bool.random() {
                teams[idx].wins += 1
            } else {
                teams[idx].losses += 1
            }
        }
    }

    // Full standings sorted by points then wins
    func standings(playerWins: Int, playerLosses: Int, playerTeamName: String) -> [StandingEntry] {
        var rows: [StandingEntry] = teams.map {
            StandingEntry(name: $0.name, wins: $0.wins, losses: $0.losses, isPlayer: false)
        }
        rows.append(StandingEntry(name: playerTeamName, wins: playerWins, losses: playerLosses, isPlayer: true))
        return rows.sorted { a, b in
            a.points != b.points ? a.points > b.points : a.wins > b.wins
        }
    }

    // Factory – used on first game start and new season
    //
    // Team strength grows with the chapter. Once the player has a squad, the
    // league is also calibrated against `referenceOverall` (the player's average
    // overall) so each season stays competitive without becoming a walkover:
    // the weakest AI sits a few points below the player and the strongest a few
    // above, so building a stronger roster still pays off.
    static func generate(chapter: Int, referenceOverall: Int = 0) -> AmateurLeague {
        let names = ["Shadow Force", "Pixel Raiders", "Ghost Protocol", "Iron Surge", "Neon Wolves"]
        let chapterBase = 44 + chapter * 10
        let playerBase = referenceOverall > 0 ? referenceOverall - 4 : 0
        let baseOvr = max(chapterBase, playerBase)
        let teams = names.enumerated().map { i, name in
            LeagueTeam(name: name, wins: 0, losses: 0, averageOverall: baseOvr + i * 3)
        }
        return AmateurLeague(teams: teams)
    }
}

// MARK: - Standing Entry (display model)
struct StandingEntry: Identifiable {
    let id = UUID()
    var name: String
    var wins: Int
    var losses: Int
    var isPlayer: Bool

    var points: Int { wins * 3 }
    var played: Int { wins + losses }
    var rank: String { "\(wins)W \(losses)L" }
}
