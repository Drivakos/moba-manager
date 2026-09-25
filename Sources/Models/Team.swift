import Foundation

struct Team: Codable, Identifiable {
    let id: UUID
    var name: String
    var roster: [Player]
    var coach: Coach?
    var wins: Int
    var losses: Int

    var isComplete: Bool { roster.count == 5 }
    var isFull: Bool { roster.count >= 5 }

    var averageOverall: Int {
        guard !roster.isEmpty else { return 0 }
        return roster.map { $0.stats.overall }.reduce(0, +) / roster.count
    }

    func average(_ key: StatKey) -> Int {
        guard !roster.isEmpty else { return 0 }
        return roster.map { $0.stats[key] }.reduce(0, +) / roster.count
    }

    var coveredRoles: Set<Role> { Set(roster.map(\.role)) }

    var synergyBonus: Int {
        let distinct = coveredRoles.count
        var bonus = distinct * 2  // +2 per unique role
        let avgTeamwork = average(.teamwork)
        if avgTeamwork > 70 { bonus += 3 }
        if distinct == 5 && avgTeamwork > 75 { bonus += 5 }
        // Penalise duplicates
        let duplicates = roster.count - distinct
        bonus -= duplicates * 2
        return max(0, bonus)
    }

    // MARK: - Opponent teams

    /// Legal AI lineup: exactly one player per role, filled from `roster` where
    /// possible and topped up with role-appropriate generated players.
    func filledToFive() -> Team {
        var lineup: [Player] = []
        var used: Set<UUID> = []
        for role in Role.allCases {
            if let existing = roster.first(where: { $0.role == role && !used.contains($0.id) }) {
                lineup.append(existing)
                used.insert(existing.id)
            } else {
                lineup.append(Player.generate(bias: role, chapter: 1))
            }
        }
        var copy = self
        copy.roster = lineup
        return copy
    }

    /// Builds a plausible league opponent: prefers the AI-signed squad from the
    /// player database, otherwise a role-complete generated lineup scaled to `chapter`.
    static func leagueOpponent(
        name: String,
        averageOverall: Int,
        chapter: Int,
        squad: [Player]
    ) -> Team {
        var team = Team(
            id: UUID(),
            name: name,
            roster: squad,
            coach: chapter >= 2 ? Coach.generate(chapter: max(1, chapter)) : nil,
            wins: 0,
            losses: 0
        )
        team = team.filledToFive()

        // Keep generated fill-ins close to the team's advertised strength.
        team.roster = team.roster.map { player in
            var p = player
            while p.stats.overall < averageOverall - 8 || p.stats.overall > averageOverall + 8 {
                let drift = (p.stats.overall < averageOverall) ? 2 : -2
                p.stats.mechanics = min(99, max(15, p.stats.mechanics + drift))
                p.stats.gameSense = min(99, max(15, p.stats.gameSense + drift))
                p.stats.teamwork  = min(99, max(15, p.stats.teamwork  + drift))
                p.stats.mental    = min(99, max(15, p.stats.mental    + drift))
                p.stats.stamina   = min(99, max(15, p.stats.stamina   + drift))
                p.salary = Player.salaryFor(overall: p.stats.overall)
            }
            return p
        }
        return team
    }

    static var empty: Team {
        Team(id: UUID(), name: "Rookie Squad", roster: [], coach: nil, wins: 0, losses: 0)
    }
}
