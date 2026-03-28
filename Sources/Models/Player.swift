import Foundation

// MARK: - Role
enum Role: String, CaseIterable, Codable, Identifiable {
    case carry    = "Carry"
    case support  = "Support"
    case jungler  = "Jungler"
    case mid      = "Mid"
    case offlaner = "Offlaner"

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .carry:    return "ADC"
        case .support:  return "SUP"
        case .jungler:  return "JGL"
        case .mid:      return "MID"
        case .offlaner: return "OFF"
        }
    }

    var statBias: StatKey {
        switch self {
        case .carry:    return .mechanics
        case .support:  return .teamwork
        case .jungler:  return .gameSense
        case .mid:      return .gameSense
        case .offlaner: return .mental
        }
    }
}

// MARK: - Stat Key
enum StatKey: String, CaseIterable {
    case mechanics = "MECH"
    case gameSense = "SENSE"
    case teamwork  = "TEAM"
    case mental    = "MENTAL"
    case stamina   = "STAM"
}

// MARK: - Player Stats
struct PlayerStats: Codable {
    var mechanics: Int   // Aim, execution
    var gameSense: Int   // Positioning, map awareness
    var teamwork: Int    // Synergy, communication
    var mental: Int      // Tilt resistance, clutch
    var stamina: Int     // Late-game consistency

    var overall: Int {
        (mechanics + gameSense + teamwork + mental + stamina) / 5
    }

    subscript(key: StatKey) -> Int {
        switch key {
        case .mechanics: return mechanics
        case .gameSense: return gameSense
        case .teamwork:  return teamwork
        case .mental:    return mental
        case .stamina:   return stamina
        }
    }

    var display: [(StatKey, Int)] {
        StatKey.allCases.map { ($0, self[$0]) }
    }
}

// MARK: - Personality
enum Personality: String, CaseIterable, Codable {
    case aggressive   = "Aggressive"
    case analytical   = "Analytical"
    case charismatic  = "Charismatic"
    case introverted  = "Introvert"
    case consistent   = "Consistent"

    var description: String {
        switch self {
        case .aggressive:  return "Always goes for plays. Huge highs, risky lows."
        case .analytical:  return "Reads the game deeply. Slow to adapt in chaos."
        case .charismatic: return "Natural shotcaller. Lifts team morale."
        case .introverted: return "Carries quietly. Struggles to communicate."
        case .consistent:  return "Never tilts. Steady performer every match."
        }
    }
}

// MARK: - Player
struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var tag: String        // In-game handle, e.g. "SnakeBite"
    var age: Int
    var role: Role
    var stats: PlayerStats
    var personality: Personality
    var potential: Int     // 1–5 stars
    var catchphrase: String
    var isRecruited: Bool
    var portraitIndex: Int // 0–4, maps to sprite variant
    var level: Int
    var xp: Int
    var salary: Int        // per-match wage cost

    var xpToNextLevel: Int { level * 80 }

    static func salaryFor(overall: Int) -> Int {
        // $200 base + $10 per OVR point above 20; roughly $300–$900 range
        return 200 + max(0, overall - 20) * 10
    }

    var starDisplay: String {
        String(repeating: "★", count: potential) + String(repeating: "☆", count: 5 - potential)
    }

    // MARK: - Generator
    static func generate(bias: Role? = nil, chapter: Int = 1) -> Player {
        let role = bias ?? Role.allCases.randomElement()!
        let baseRange = (30 + chapter * 4)...(50 + chapter * 6)
        let base = Int.random(in: baseRange)
        let v = 18  // variance

        func stat(boosted: Bool = false) -> Int {
            min(98, max(10, base + (boosted ? 12 : 0) + Int.random(in: -v...v)))
        }

        let stats = PlayerStats(
            mechanics: stat(boosted: role == .carry),
            gameSense: stat(boosted: role == .jungler || role == .mid),
            teamwork:  stat(boosted: role == .support),
            mental:    stat(boosted: role == .offlaner),
            stamina:   stat()
        )

        let firstNames = ["Alex","Jordan","Sam","Riley","Casey","Morgan","Taylor","Drew","Jamie","Kai",
                          "Zoe","Mika","Noel","Ash","Sky","Blake","Remy","Quinn","Sage","River"]
        let lastNames  = ["Storm","Fox","Wolf","Steel","Blaze","Nova","Void","Flash","Shade","Frost",
                          "Peak","Edge","Core","Pulse","Wave","Cruz","Veil","Shard","Drift","Apex"]
        let tags       = ["SnakeBite","GhostPing","NovaDrift","IronFox","ZeroMind","SkyWolf",
                          "BladeCore","VoidEdge","PeakPulse","FrostAsh","CruzBlaze","ShardKai"]
        let catchphrases = [
            "I've been grinding since I was 9.",
            "Just trust the process.",
            "I watch every pro replay. Every single one.",
            "My parents think this is a waste of time...",
            "I never, ever tilt. Never.",
            "One day, everyone will know my name.",
            "I live, breathe, and sleep this game.",
            "I'm way better than my rank shows.",
            "Let's go! Let's go! Let's GO!",
            "I don't need sleep. I need reps.",
            "You won't regret signing me.",
            "I've already beaten half the pros in scrims."
        ]

        let overall = stats.overall
        return Player(
            id: UUID(),
            name: "\(firstNames.randomElement()!) \(lastNames.randomElement()!)",
            tag: tags.randomElement()!,
            age: Int.random(in: 14...19),
            role: role,
            stats: stats,
            personality: Personality.allCases.randomElement()!,
            potential: Int.random(in: 1...5),
            catchphrase: catchphrases.randomElement()!,
            isRecruited: false,
            portraitIndex: Int.random(in: 0...4),
            level: 1,
            xp: 0,
            salary: salaryFor(overall: overall)
        )
    }
}
