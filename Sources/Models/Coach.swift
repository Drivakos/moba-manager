import Foundation

// MARK: - Coach Style
enum CoachStyle: String, CaseIterable, Codable {
    case aggressive  = "Aggressive"
    case methodical  = "Methodical"
    case adaptable   = "Adaptable"
    case motivator   = "Motivator"
    case tactician   = "Tactician"

    var subtitle: String {
        switch self {
        case .aggressive:  return "High risk, early blitz"
        case .methodical:  return "Patient scaling specialist"
        case .adaptable:   return "Reads and exploits any opponent"
        case .motivator:   return "Carries the team mentally"
        case .tactician:   return "Pure strategic genius"
        }
    }

    func phaseBonus(for phase: MatchPhase) -> Int {
        switch self {
        case .aggressive:
            switch phase { case .early: return 8; case .mid: return 3; case .late: return 0 }
        case .methodical:
            switch phase { case .early: return 0; case .mid: return 4; case .late: return 8 }
        case .adaptable:
            return 4
        case .motivator:
            switch phase { case .early: return 1; case .mid: return 4; case .late: return 7 }
        case .tactician:
            return 6
        }
    }
}

// MARK: - Coach Stats
struct CoachStats: Codable {
    var strategy: Int        // Flat bonus to all phases
    var motivation: Int      // Late-game mental resilience
    var communication: Int   // Amplifies synergy bonus
    var scouting: Int        // Reduces opponent reads

    var overall: Int {
        (strategy + motivation + communication + scouting) / 4
    }

    var display: [(String, Int)] {
        [("STRAT", strategy), ("MOTIV", motivation), ("COMM", communication), ("SCOUT", scouting)]
    }
}

// MARK: - Coach
struct Coach: Identifiable, Codable {
    let id: UUID
    var name: String
    var tag: String
    var age: Int
    var style: CoachStyle
    var stats: CoachStats
    var potential: Int
    var catchphrase: String
    var level: Int
    var xp: Int

    var xpToNextLevel: Int { level * 100 }

    var starDisplay: String {
        String(repeating: "★", count: potential) + String(repeating: "☆", count: 5 - potential)
    }

    /// Total bonus this coach contributes for a given match phase
    func matchBonus(for phase: MatchPhase) -> Int {
        let stratBase  = stats.strategy / 10
        let styleBonus = style.phaseBonus(for: phase)
        let motivLate  = (phase == .late) ? stats.motivation / 14 : 0
        return stratBase + styleBonus + motivLate
    }

    // MARK: - Generator
    static func generate(chapter: Int = 1) -> Coach {
        let base = 30 + chapter * 5
        let v = 15
        func stat() -> Int { min(98, max(10, base + Int.random(in: -v...v))) }

        let firstNames = ["Victor","Marcus","Elena","Yuki","Ramon","Diana","Cole","Petra",
                          "Ivan","Sophie","Amir","Nadia","Rex","Cleo","Johan","Lena","Kai"]
        let lastNames  = ["Cross","Stone","Vance","Park","Silva","Kane","Wolfe","Holt",
                          "Drake","Mercer","Osei","Tanaka","Ford","Reiss","Nair","Ash"]
        let tags       = ["VIPER","STONEWALL","ICEPICK","ORACLE","PHANTOM","REAPER",
                          "KODEX","IRON","MATRIX","SARGE","ACE","APEX","NOVA","DUSK","WIRE"]
        let catchphrases = [
            "I've turned amateurs into legends before.",
            "Trust the system. I built it.",
            "Every loss is a lesson you haven't paid for yet.",
            "I don't coach players — I build winners.",
            "Fear your opponent, respect them, then destroy them.",
            "My record speaks for itself.",
            "This team has potential. I'll make it a dynasty.",
            "Discipline beats talent. Every time."
        ]

        let style = CoachStyle.allCases.randomElement()!
        return Coach(
            id: UUID(),
            name: "\(firstNames.randomElement()!) \(lastNames.randomElement()!)",
            tag: tags.randomElement()!,
            age: Int.random(in: 28...52),
            style: style,
            stats: CoachStats(
                strategy:      stat(),
                motivation:    stat(),
                communication: stat(),
                scouting:      stat()
            ),
            potential: Int.random(in: 1...5),
            catchphrase: catchphrases.randomElement()!,
            level: 1,
            xp: 0
        )
    }
}
