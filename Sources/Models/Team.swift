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

    // MARK: - Generate opponent team
    static func generateOpponent(name: String, chapter: Int) -> Team {
        // Scale opponent size with chapter: ch1=3 players, ch2=4, ch3=5
        let rosterSize = min(3 + (chapter - 1), 5)
        let roles = Role.allCases.shuffled().prefix(rosterSize)
        let roster = roles.map { Player.generate(bias: $0, chapter: max(1, chapter)) }
        // Opponents only get a coach from chapter 2 onward
        let coach = chapter >= 2 ? Coach.generate(chapter: max(1, chapter)) : nil
        return Team(
            id: UUID(),
            name: name,
            roster: roster,
            coach: coach,
            wins: Int.random(in: 1...5),
            losses: Int.random(in: 1...4)
        )
    }

    static var empty: Team {
        Team(id: UUID(), name: "Rookie Squad", roster: [], coach: nil, wins: 0, losses: 0)
    }
}
