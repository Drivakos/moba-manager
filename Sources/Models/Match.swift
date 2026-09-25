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
    /// A standout player single-handedly decided the phase.
    let isStarPlay: Bool

    init(phase: MatchPhase, text: String, isPositive: Bool, isStarPlay: Bool = false) {
        self.id = UUID()
        self.phase = phase
        self.text = text
        self.isPositive = isPositive
        self.isStarPlay = isStarPlay
    }
}

// MARK: - Phase Outcome
/// A match is a best-of-three series: each phase clash awards at most one game.
/// A phase can be drawn, which awards nothing and pushes the series on.
enum PhaseOutcome: String, Codable {
    case win
    case loss
    case draw

    var label: String {
        switch self {
        case .win:  return "WON"
        case .loss: return "LOST"
        case .draw: return "DRAWN"
        }
    }
}

// MARK: - Match Result
struct MatchResult: Codable {
    let won: Bool
    let events: [MatchEvent]
    let gamesWon: Int
    let gamesLost: Int
    let mvpName: String?
    let phaseOutcomes: [PhaseOutcome]  // [early, mid, late]

    /// Games needed to take the series (best of three).
    static let gamesToWin = 2
}

// MARK: - Match Engine
struct MatchEngine {

    static func simulate(player: Team, opponent: Team, tactic: MatchTactic = .adapt) -> MatchResult {
        var events: [MatchEvent] = []
        var gamesWon = 0
        var gamesLost = 0
        var mvpContributions: [String: Int] = [:]
        var phaseOutcomes: [PhaseOutcome] = []
        var cumulativeSwing = 0

        for phase in MatchPhase.allCases {
            let playerPower  = phasePower(team: player, phase: phase)
            let opponentPower = phasePower(team: opponent, phase: phase)
            let playerRoll   = Int.random(in: -12...12)
            let opponentRoll = Int.random(in: -12...12)
            let tacticBonus  = tactic.bonus(for: phase)
            // Coach: communication amplifies synergy, scouting shaves opponent
            let commBonus  = (player.coach?.stats.communication ?? 0) / 25
            let scoutShave = (player.coach?.stats.scouting ?? 0) / 20
            let playerFinal   = playerPower + player.synergyBonus + commBonus + tacticBonus + playerRoll
            let opponentFinal = max(0, opponentPower + opponent.synergyBonus - scoutShave + opponentRoll)

            // Dead even phases are a draw — no game awarded to either side.
            let swing = playerFinal - opponentFinal
            cumulativeSwing += swing
            let outcome: PhaseOutcome = abs(swing) <= 3 ? .draw : (swing > 0 ? .win : .loss)
            phaseOutcomes.append(outcome)
            if outcome == .win { gamesWon += 1 }
            if outcome == .loss { gamesLost += 1 }

            // The team's best player for this phase's key stat carries it.
            let playerStar = standout(team: player, phase: phase)
            let opponentStar = standout(team: opponent, phase: phase)
            if outcome == .win, let star = playerStar {
                mvpContributions[star.tag, default: 0] += 1
            }

            // A standout far above the opposing counterpart takes the phase over.
            let starEdge = (playerStar?.stats[phase.keyStatKey] ?? 0)
                        - (opponentStar?.stats[phase.keyStatKey] ?? 0)
            let isStarPlay = outcome == .win && (starEdge >= 12 || Int.random(in: 0..<100) < 18)

            // Generate narrative events (3 per phase)
            events += generateEvents(
                phase: phase,
                playerTeam: player,
                opponentTeam: opponent,
                outcome: outcome,
                playerStar: playerStar,
                opponentStar: opponentStar,
                isStarPlay: isStarPlay
            )
        }

        let mvp = mvpContributions.max(by: { $0.value < $1.value })?.key

        // Best of three across the three phases. All three phases are played, so
        // cap each side at the winning total first (otherwise a sweep reports as
        // 3—0). If drawn phases leave neither side on two, the tiebreak goes to
        // whoever won the larger share of the phase swings and is scored as the
        // second game, so the scoreboard never reads a level "1 — 1".
        gamesWon = min(gamesWon, MatchResult.gamesToWin)
        gamesLost = min(gamesLost, MatchResult.gamesToWin)
        if gamesWon < MatchResult.gamesToWin && gamesLost < MatchResult.gamesToWin {
            if cumulativeSwing >= 0 { gamesWon = MatchResult.gamesToWin }
            else { gamesLost = MatchResult.gamesToWin }
        }
        let won = gamesWon >= MatchResult.gamesToWin

        return MatchResult(
            won: won,
            events: events,
            gamesWon: gamesWon,
            gamesLost: gamesLost,
            mvpName: mvp,
            phaseOutcomes: phaseOutcomes
        )
    }

    /// Highest-rated player for the stat that decides `phase`.
    private static func standout(team: Team, phase: MatchPhase) -> Player? {
        team.roster.max { $0.stats[phase.keyStatKey] < $1.stats[phase.keyStatKey] }
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
    private static func generateEvents(
        phase: MatchPhase,
        playerTeam: Team,
        opponentTeam: Team,
        outcome: PhaseOutcome,
        playerStar: Player?,
        opponentStar: Player?,
        isStarPlay: Bool
    ) -> [MatchEvent] {
        let pTag = playerStar?.tag ?? playerTeam.roster.randomElement()?.tag ?? "Your team"
        let oTag = opponentStar?.tag ?? opponentTeam.roster.randomElement()?.tag ?? "The enemy"

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

        let neutralPool: [String] = [
            "Both teams trade blows with nothing separating them.",
            "\(pTag) and \(oTag) cancel each other out.",
            "A tense standoff — neither side commits.",
            "Even fight. \(playerTeam.name) and \(opponentTeam.name) reset.",
            "No decisive play. The series rolls on."
        ]

        switch outcome {
        case .win:
            return [
                MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true, isStarPlay: isStarPlay),
                MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true),
                MatchEvent(phase: phase, text: negativePool.randomElement()!, isPositive: false)
            ]
        case .loss:
            return [
                MatchEvent(phase: phase, text: negativePool.randomElement()!, isPositive: false),
                MatchEvent(phase: phase, text: negativePool.randomElement()!, isPositive: false),
                MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true)
            ]
        case .draw:
            return [
                MatchEvent(phase: phase, text: neutralPool.randomElement()!, isPositive: true),
                MatchEvent(phase: phase, text: neutralPool.randomElement()!, isPositive: false),
                MatchEvent(phase: phase, text: positivePool.randomElement()!, isPositive: true)
            ]
        }
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
