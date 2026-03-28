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
        let roles = Role.allCases.shuffled()
        let roster = roles.map { Player.generate(bias: $0, chapter: max(1, chapter)) }
        return Team(
            id: UUID(),
            name: name,
            roster: roster,
            coach: Coach.generate(chapter: max(1, chapter)),
            wins: Int.random(in: 2...8),
            losses: Int.random(in: 1...5)
        )
    }

    static var empty: Team {
        Team(id: UUID(), name: "Rookie Squad", roster: [], coach: nil, wins: 0, losses: 0)
    }
}
