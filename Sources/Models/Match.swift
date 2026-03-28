import Foundation

// MARK: - Match Phase
enum MatchPhase: String, CaseIterable, Codable {
    case early = "EARLY GAME"
    case mid   = "MID GAME"
    case late  = "LATE GAME"
}

// MARK: - Match Tactic
enum MatchTactic: String, CaseIterable, Codable {
    case dive  = "DIVE"
    case poke  = "POKE"
    case scale = "SCALE"
    case adapt = "ADAPT"

    var subtitle: String {
        switch self {
        case .dive:  return "All-in early aggression"
        case .poke:  return "Map control & chip damage"
        case .scale: return "Outscale for late game"
        case .adapt: return "Read & react to anything"
        }
    }

    var boostedPhase: String {
        switch self {
        case .dive:  return "EARLY GAME +12"
        case .poke:  return "MID GAME +12"
        case .scale: return "LATE GAME +12"
        case .adapt: return "ALL PHASES +5"
        }
    }

    var flavor: String {
        switch self {
        case .dive:  return "\"First blood or bust.\""
        case .poke:  return "\"Whittle them down.\""
        case .scale: return "\"Let them come to us.\""
        case .adapt: return "\"Stay flexible, stay dangerous.\""
        }
    }

    func bonus(for phase: MatchPhase) -> Int {
        switch self {
        case .dive:  return phase == .early ? 12 : 0
        case .poke:  return phase == .mid   ? 12 : 0
        case .scale: return phase == .late  ? 12 : 0
        case .adapt: return 5
        }
    }
}

// MARK: - Match Event
struct MatchEvent: Identifiable, Codable {
    let id: UUID
    let phase: MatchPhase
    let text: String
    let isPositive: Bool  // from player team's perspective

    init(phase: MatchPhase, text: String, isPositive: Bool) {
        self.id = UUID()
        self.phase = phase
        self.text = text
        self.isPositive = isPositive
    }
}

// MARK: - Match Result
struct MatchResult: Codable {
    let won: Bool
    let events: [MatchEvent]
    let playerScore: Int    // phases won by player
    let opponentScore: Int
    let mvpName: String?
    let phaseResults: [Bool]  // [early, mid, late] — true = player won that phase
}

// MARK: - Match Engine
struct MatchEngine {

    static func simulate(player: Team, opponent: Team, tactic: MatchTactic = .adapt) -> MatchResult {
        var events: [MatchEvent] = []
        var playerPhaseWins = 0
        var opponentPhaseWins = 0
        var mvpContributions: [String: Int] = [:]
        var phaseResults: [Bool] = []

        for phase in MatchPhase.allCases {
            let playerPower  = phasePower(team: player, phase: phase)
            let opponentPower = phasePower(team: opponent, phase: phase)
            let roll = Int.random(in: -15...15)
            let tacticBonus = tactic.bonus(for: phase)
            // Coach: communication amplifies synergy, scouting shaves opponent
            let commBonus  = (player.coach?.stats.communication ?? 0) / 25
            let scoutShave = (player.coach?.stats.scouting ?? 0) / 20
            let playerFinal   = playerPower + player.synergyBonus + commBonus + tacticBonus + roll
            let opponentFinal = max(0, opponentPower + opponent.synergyBonus - scoutShave)

            let playerWins = playerFinal > opponentFinal
            phaseResults.append(playerWins)
            if playerWins {
                playerPhaseWins += 1
            } else {
                opponentPhaseWins += 1
            }

            // Pick MVP contributor this phase
            let mvpPlayer = player.roster.max {
                $0.stats[phase.keyStatKey] < $1.stats[phase.keyStatKey]
            }
            if let mvp = mvpPlayer {
                mvpContributions[mvp.tag, default: 0] += 1
            }

            // Generate narrative events (3 per phase)
            events += generateEvents(
                phase: phase,
                playerTeam: player,
                opponentTeam: opponent,
                playerWon: playerWins
            )
        }

        let mvp = mvpContributions.max(by: { $0.value < $1.value })?.key
        return MatchResult(
            won: playerPhaseWins > opponentPhaseWins,
            events: events,
            playerScore: playerPhaseWins,
            opponentScore: opponentPhaseWins,
            mvpName: mvp,
            phaseResults: phaseResults
        )
    }

    // MARK: - Power Calculation
    private static func phasePower(team: Team, phase: MatchPhase) -> Int {
        guard !team.roster.isEmpty else { return 0 }

        let mech   = team.average(.mechanics)
        let sense  = team.average(.gameSense)
        let twrk   = team.average(.teamwork)
        let mental = team.average(.mental)
        let stam   = team.average(.stamina)

        var base: Int
        switch phase {
        case .early:
            base = Int(Double(mech) * 0.4 + Double(sense) * 0.3 + Double(twrk) * 0.2 + Double(mental) * 0.1)
        case .mid:
            base = Int(Double(mech) * 0.3 + Double(sense) * 0.35 + Double(twrk) * 0.25 + Double(mental) * 0.1)
        case .late:
            base = Int(Double(mech) * 0.2 + Double(sense) * 0.3 + Double(twrk) * 0.3 + Double(mental) * 0.1 + Double(stam) * 0.1)
            if stam < 50 { base = Int(Double(base) * 0.85) }
        }

        // Coach contribution
        if let coach = team.coach {
            base += coach.matchBonus(for: phase)
        }

        return base
    }

    // MARK: - Narrative Events
    private static func generateEvents(phase: MatchPhase, playerTeam: Team, opponentTeam: Team, playerWon: Bool) -> [MatchEvent] {
        let player = playerTeam.roster.randomElement()
        let opponent = opponentTeam.roster.randomElement()
        let pTag = player?.tag ?? "Your player"
        let oTag = opponent?.tag ?? "Enemy"

        let positivePool: [String] = [
            "\(pTag) takes over the \(phase == .early ? "lane" : "map")!",
            "Perfect rotation by \(pTag) seals the fight.",
            "Your team secures the objective — \(opponentTeam.name) can't respond.",
            "\(pTag) reads the play flawlessly. Three kills.",
            "Flawless teamfight — \(playerTeam.name) wins the skirmish.",
            "\(pTag) outmechanics \(oTag) in a 1v1 duel.",
            "Your team's coordination is on another level this phase."
        ]
        let negativePool: [String] = [
            "\(oTag) catches \(pTag) out of position.",
            "\(opponentTeam.name) wins the teamfight cleanly.",
            "\(oTag) dominates — your team loses the trade.",
            "A critical misstep hands \(opponentTeam.name) the objective.",
            "\(pTag) overextends and gives away the kill.",
            "Communication breaks down. \(opponentTeam.name) punishes instantly.",
            "\(oTag) outpaces \(pTag) in this phase."
        ]

        var result: [MatchEvent] = []
        if playerWon {
            result.append(MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true))
            result.append(MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true))
            result.append(MatchEvent(phase: phase, text: negativePool.randomElement()!, isPositive: false))
        } else {
            result.append(MatchEvent(phase: phase, text: negativePool.randomElement()!, isPositive: false))
            result.append(MatchEvent(phase: phase, text: negativePool.randomElement()!, isPositive: false))
            result.append(MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true))
        }
        return result
    }
}

private extension MatchPhase {
    var keyStatKey: StatKey {
        switch self {
        case .early: return .mechanics
        case .mid:   return .gameSense
        case .late:  return .mental
        }
    }
}
