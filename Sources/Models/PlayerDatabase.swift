import Foundation

// MARK: - Player Status
enum PlayerStatus: Codable, Equatable {
    case freeAgent
    case signedByPlayer
    case signedByAI(teamName: String)

    var label: String {
        switch self {
        case .freeAgent:             return "FREE AGENT"
        case .signedByPlayer:        return "ON ROSTER"
        case .signedByAI(let name):  return name.uppercased()
        }
    }

    var isFree: Bool {
        if case .freeAgent = self { return true }
        return false
    }
}

// MARK: - Player Record
struct PlayerRecord: Codable, Identifiable {
    let id: UUID            // mirrors player.id
    var player: Player
    var status: PlayerStatus
}

// MARK: - Player Database
struct PlayerDatabase: Codable {

    var records: [PlayerRecord]

    // MARK: - Queries

    var freeAgents: [PlayerRecord] {
        records.filter { $0.status.isFree }
    }

    func freeAgents(role: Role?) -> [PlayerRecord] {
        let pool = freeAgents
        guard let role else { return pool }
        return pool.filter { $0.player.role == role }
    }

    // MARK: - Mutations

    mutating func sign(id: UUID, byPlayer: Bool, teamName: String = "") {
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        records[idx].status = byPlayer ? .signedByPlayer : .signedByAI(teamName: teamName)
    }

    mutating func release(id: UUID) {
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        records[idx].status = .freeAgent
    }

    // Sync database status when a roster player's data changes (XP/stats)
    mutating func updatePlayerData(_ player: Player) {
        guard let idx = records.firstIndex(where: { $0.id == player.id }) else { return }
        records[idx].player = player
    }

    // MARK: - AI Team Signing (called on league init)
    mutating func distributeToAITeams(_ teams: [LeagueTeam]) {
        // Release all AI-signed players first (fresh season)
        for i in records.indices where !records[i].status.isFree {
            if case .signedByAI = records[i].status {
                records[i].status = .freeAgent
            }
        }

        // Sort free agents by OVR desc so better AI teams get better players
        let sorted = records
            .filter { $0.status.isFree }
            .sorted { $0.player.stats.overall > $1.player.stats.overall }

        // Each AI team gets 3 players, picking from OVR band matching their difficulty
        var pool = sorted
        for team in teams {
            var picked = 0
            var remaining: [PlayerRecord] = []
            for record in pool {
                if picked < 3 {
                    if let idx = records.firstIndex(where: { $0.id == record.id }) {
                        records[idx].status = .signedByAI(teamName: team.name)
                    }
                    picked += 1
                } else {
                    remaining.append(record)
                }
            }
            pool = remaining
        }
    }

    // MARK: - Factory

    static func generate() -> PlayerDatabase {
        let specs = PlayerDatabase.allSpecs
        let records = specs.map { spec -> PlayerRecord in
            let stats = makeStats(role: spec.role, overall: spec.overall, seed: spec.seed)
            let salary = Player.salaryFor(overall: stats.overall)
            let player = Player(
                id: UUID(),
                name: spec.name,
                tag: spec.tag,
                age: spec.age,
                role: spec.role,
                stats: stats,
                personality: spec.personality,
                potential: spec.potential,
                catchphrase: spec.catchphrase,
                isRecruited: false,
                portraitIndex: spec.seed % 5,
                level: 1,
                xp: 0,
                salary: salary
            )
            return PlayerRecord(id: player.id, player: player, status: .freeAgent)
        }
        return PlayerDatabase(records: records)
    }

    // MARK: - Stat Builder
    private static func makeStats(role: Role, overall ovr: Int, seed: Int) -> PlayerStats {
        // Variance seeds ensure variety without randomness at runtime
        let v: [Int] = [seed % 9 - 4, (seed / 3) % 9 - 4, (seed / 5) % 7 - 3, (seed / 7) % 9 - 4, seed % 7 - 3]

        func s(_ i: Int, primary: Bool) -> Int {
            min(99, max(15, ovr + (primary ? 16 : -3) + v[i]))
        }

        switch role {
        case .carry:
            return PlayerStats(mechanics: s(0, primary: true),  gameSense: s(1, primary: false),
                               teamwork: s(2, primary: false),  mental:    s(3, primary: false), stamina: s(4, primary: false))
        case .support:
            return PlayerStats(mechanics: s(0, primary: false), gameSense: s(1, primary: false),
                               teamwork: s(2, primary: true),   mental:    s(3, primary: false), stamina: s(4, primary: false))
        case .jungler:
            return PlayerStats(mechanics: s(0, primary: false), gameSense: s(1, primary: true),
                               teamwork: s(2, primary: false),  mental:    s(3, primary: false), stamina: s(4, primary: false))
        case .mid:
            return PlayerStats(mechanics: s(0, primary: false), gameSense: s(1, primary: true),
                               teamwork: s(2, primary: false),  mental:    s(3, primary: false), stamina: s(4, primary: false))
        case .offlaner:
            return PlayerStats(mechanics: s(0, primary: false), gameSense: s(1, primary: false),
                               teamwork: s(2, primary: false),  mental:    s(3, primary: true),  stamina: s(4, primary: false))
        }
    }
}

// MARK: - Player Spec (hardcoded roster data)
private struct PlayerSpec {
    let name: String; let tag: String; let age: Int
    let role: Role; let potential: Int; let overall: Int
    let personality: Personality; let catchphrase: String; let seed: Int
}

extension PlayerDatabase {
    // swiftlint:disable line_length
    private static let allSpecs: [PlayerSpec] = [
        // MARK: Carry (ADC)
        PlayerSpec(name: "Jin Park",      tag: "SnipeKing",  age: 17, role: .carry,    potential: 4, overall: 72, personality: .aggressive,  catchphrase: "One clip. That's all I need.",              seed: 11),
        PlayerSpec(name: "Marcus Chen",   tag: "VoidLine",   age: 19, role: .carry,    potential: 3, overall: 58, personality: .analytical,  catchphrase: "I study every ADC in the scene.",           seed: 23),
        PlayerSpec(name: "Aiden Kim",     tag: "FrostADC",   age: 16, role: .carry,    potential: 5, overall: 45, personality: .consistent,  catchphrase: "Young but I never miss.",                   seed: 37),
        PlayerSpec(name: "Tyler Ross",    tag: "NovaBolt",   age: 18, role: .carry,    potential: 3, overall: 81, personality: .charismatic, catchphrase: "The crowd goes wild when I play.",           seed: 41),
        PlayerSpec(name: "Sam Lee",       tag: "GhostShot",  age: 20, role: .carry,    potential: 2, overall: 65, personality: .introverted, catchphrase: "I don't need recognition. Just results.",    seed: 53),
        PlayerSpec(name: "Kai Torres",    tag: "BladeCarry", age: 17, role: .carry,    potential: 4, overall: 50, personality: .aggressive,  catchphrase: "I outscale every carry in this league.",     seed: 67),
        PlayerSpec(name: "Ryan Patel",    tag: "StarEdge",   age: 19, role: .carry,    potential: 3, overall: 38, personality: .consistent,  catchphrase: "I'll get there. One step at a time.",        seed: 79),
        PlayerSpec(name: "Chris Wu",      tag: "NeonAim",    age: 21, role: .carry,    potential: 2, overall: 55, personality: .analytical,  catchphrase: "Precision is my playstyle.",                 seed: 83),

        // MARK: Support
        PlayerSpec(name: "Maya Tanaka",   tag: "ShieldSage", age: 18, role: .support,  potential: 3, overall: 68, personality: .charismatic, catchphrase: "I keep my carry alive no matter what.",      seed: 12),
        PlayerSpec(name: "Alex Cruz",     tag: "VoidWarden", age: 17, role: .support,  potential: 4, overall: 55, personality: .analytical,  catchphrase: "Vision control wins games. Period.",         seed: 24),
        PlayerSpec(name: "Jordan Williams",tag:"PeakHeal",   age: 20, role: .support,  potential: 2, overall: 74, personality: .consistent,  catchphrase: "Ten seasons deep. I know the game.",         seed: 38),
        PlayerSpec(name: "Riley Okafor",  tag: "StormSup",   age: 16, role: .support,  potential: 5, overall: 42, personality: .aggressive,  catchphrase: "I make carries look like gods.",             seed: 42),
        PlayerSpec(name: "Drew Novak",    tag: "IronShield", age: 19, role: .support,  potential: 3, overall: 61, personality: .introverted, catchphrase: "My stats don't show what I do for the team.",seed: 54),
        PlayerSpec(name: "Quinn Singh",   tag: "DawnWard",   age: 18, role: .support,  potential: 4, overall: 48, personality: .consistent,  catchphrase: "I will never let my carry die.",             seed: 68),
        PlayerSpec(name: "Morgan Reyes",  tag: "AshGuard",   age: 21, role: .support,  potential: 2, overall: 70, personality: .charismatic, catchphrase: "Leadership is just good shotcalling.",        seed: 80),
        PlayerSpec(name: "Blake Yamamoto",tag: "CoreSense",  age: 17, role: .support,  potential: 3, overall: 35, personality: .analytical,  catchphrase: "I'm learning everything from scratch.",       seed: 84),

        // MARK: Jungler
        PlayerSpec(name: "Zoe Kim",       tag: "ShadowPath", age: 18, role: .jungler,  potential: 4, overall: 76, personality: .aggressive,  catchphrase: "The jungle is my territory.",                seed: 13),
        PlayerSpec(name: "Noel Ahmed",    tag: "ForestWolf", age: 17, role: .jungler,  potential: 5, overall: 62, personality: .consistent,  catchphrase: "I track every camp on both sides.",           seed: 25),
        PlayerSpec(name: "Ash Chen",      tag: "VoidPath",   age: 20, role: .jungler,  potential: 3, overall: 54, personality: .introverted, catchphrase: "Objectives over kills. Always.",              seed: 39),
        PlayerSpec(name: "Sky Rivera",    tag: "DragonMark", age: 19, role: .jungler,  potential: 3, overall: 83, personality: .charismatic, catchphrase: "Baron secured. GG.",                         seed: 43),
        PlayerSpec(name: "River Park",    tag: "JungleCore", age: 16, role: .jungler,  potential: 4, overall: 40, personality: .analytical,  catchphrase: "I'm mapping out optimal clear paths 24/7.",  seed: 55),
        PlayerSpec(name: "Mika Wilson",   tag: "ShadowStep", age: 18, role: .jungler,  potential: 3, overall: 67, personality: .aggressive,  catchphrase: "Gank first. Ask questions later.",           seed: 69),
        PlayerSpec(name: "Sage Thompson", tag: "ForestBlade",age: 20, role: .jungler,  potential: 2, overall: 71, personality: .consistent,  catchphrase: "Methodical play always beats raw mechanics.", seed: 81),
        PlayerSpec(name: "Remy Martinez", tag: "WildPulse",  age: 17, role: .jungler,  potential: 4, overall: 44, personality: .charismatic, catchphrase: "Watch my pathing. It's a work of art.",       seed: 85),

        // MARK: Mid
        PlayerSpec(name: "Leon Zhang",    tag: "MindBlade",  age: 19, role: .mid,      potential: 4, overall: 79, personality: .aggressive,  catchphrase: "Mid diff every game.",                       seed: 14),
        PlayerSpec(name: "Aria Sato",     tag: "NovaMind",   age: 17, role: .mid,      potential: 5, overall: 63, personality: .analytical,  catchphrase: "I understand the meta on a different level.",seed: 26),
        PlayerSpec(name: "Finn Jackson",  tag: "VoidSense",  age: 18, role: .mid,      potential: 3, overall: 55, personality: .introverted, catchphrase: "No flashy plays. Just clean mechanics.",     seed: 31),
        PlayerSpec(name: "Nova Brown",    tag: "ShardMid",   age: 16, role: .mid,      potential: 4, overall: 41, personality: .consistent,  catchphrase: "I'm building my fundamentals first.",        seed: 44),
        PlayerSpec(name: "Cole Garcia",   tag: "IronWave",   age: 21, role: .mid,      potential: 2, overall: 84, personality: .charismatic, catchphrase: "I've carried teams in every division.",      seed: 56),
        PlayerSpec(name: "Jax Lee",       tag: "StormMind",  age: 18, role: .mid,      potential: 3, overall: 57, personality: .aggressive,  catchphrase: "Roaming wins games. Stay aware.",            seed: 70),
        PlayerSpec(name: "Echo Nguyen",   tag: "CoreMind",   age: 17, role: .mid,      potential: 5, overall: 47, personality: .analytical,  catchphrase: "High ceiling, I just need the reps.",        seed: 82),
        PlayerSpec(name: "Zara Ali",      tag: "FrostMid",   age: 20, role: .mid,      potential: 3, overall: 69, personality: .consistent,  catchphrase: "Controlled aggression. That's my style.",   seed: 86),

        // MARK: Offlaner
        PlayerSpec(name: "Dex Morgan",    tag: "IronOff",    age: 19, role: .offlaner, potential: 3, overall: 73, personality: .consistent,  catchphrase: "Island life. I handle my lane alone.",       seed: 15),
        PlayerSpec(name: "Sable Park",    tag: "DuskLine",   age: 17, role: .offlaner, potential: 4, overall: 60, personality: .introverted, catchphrase: "Top diff is underrated. Watch me.",           seed: 27),
        PlayerSpec(name: "Cruz Petrov",   tag: "StoneOff",   age: 20, role: .offlaner, potential: 3, overall: 48, personality: .analytical,  catchphrase: "I never tilt. Not once.",                    seed: 32),
        PlayerSpec(name: "Vex Kim",       tag: "WallBreak",  age: 18, role: .offlaner, potential: 4, overall: 85, personality: .aggressive,  catchphrase: "I carry from the top lane. Period.",         seed: 45),
        PlayerSpec(name: "Lyra Cohen",    tag: "ShieldOff",  age: 16, role: .offlaner, potential: 5, overall: 38, personality: .charismatic, catchphrase: "People underestimate me. Their loss.",        seed: 57),
        PlayerSpec(name: "Rex Torres",    tag: "VoidOff",    age: 21, role: .offlaner, potential: 2, overall: 66, personality: .consistent,  catchphrase: "Experienced and reliable. Every game.",       seed: 71),
        PlayerSpec(name: "Kade Wilson",   tag: "ApexOff",    age: 17, role: .offlaner, potential: 4, overall: 52, personality: .aggressive,  catchphrase: "Split push them into the ground.",           seed: 83),
        PlayerSpec(name: "Storm Patel",   tag: "IronMind",   age: 19, role: .offlaner, potential: 3, overall: 77, personality: .analytical,  catchphrase: "Mental fortitude separates good from great.", seed: 87),
    ]
    // swiftlint:enable line_length
}
