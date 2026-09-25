import Foundation
import Observation

// MARK: - App Screen
enum AppScreen {
    case title
    case teamSetup
    case overworld
    case teamRoster
    case training
    case tactics
    case matchSim
    case tournamentBracket   // league view
    case transferMarket
    case finances
    case pauseMenu
    case loadGame
    case saveGame
    case journey
    case gameOver
}

// MARK: - Direction
enum Direction {
    case up, down, left, right
}

// MARK: - Tile Position
struct TilePosition: Codable, Equatable {
    var col: Int
    var row: Int
}

// MARK: - GameState
@Observable
final class GameState {

    // Navigation
    var screen: AppScreen = .title

    // Overworld
    var playerPosition: TilePosition = TilePosition(col: 1, row: 1)
    var movementInput: Direction? = nil
    var overworldPaused: Bool = false

    // Identity
    var managerName: String = "COACH"

    // Team
    var playerTeam: Team = .empty
    var chapter: Int = 1
    var storyFlags: Set<String> = []

    // Economy
    var funds: Int = 25_000
    let facilityCostPerMatch: Int = 500

    // League
    var league: AmateurLeague = AmateurLeague.generate(chapter: 1)

    /// Highest chapter that can be won — the Grand Final.
    static let finalChapter = 3

    // Persistent player database (set list, tracked status)
    var playerDatabase: PlayerDatabase = PlayerDatabase.generate()

    // Club ledger — most recent first, capped in `earn`/`spend`.
    var ledger: [Transaction] = []
    private let ledgerLimit = 60

    // Pre-match tactic
    var selectedTactic: MatchTactic = .adapt

    // Story dialogue queue
    var pendingStoryLines: [StoryLine] = []

    // End-of-chapter result waiting to be acknowledged on the overworld
    var pendingChapterResult: ChapterReview? = nil

    // Coach hire flow
    var pendingCoachPool: [Coach] = []
    var isHiringCoach: Bool = false

    // Match flow
    var pendingMatch: MatchResult? = nil
    var activeOpponent: Team? = nil
    var activeOpponentIsBoss: Bool = false

    // Current-season league record. `playerTeam.wins/losses` is the lifetime
    // franchise record; qualification and standings use these instead so a new
    // season does not start with the previous season's points.
    var seasonWins: Int = 0
    var seasonLosses: Int = 0

    // Convenience
    var canSign: Bool { playerTeam.roster.count < 5 }
    var isCareerWon: Bool { chapter > GameState.finalChapter }

    var weeklyWages: Int {
        let playerWages = playerTeam.roster.reduce(0) { $0 + $1.salary }
        let coachWage  = playerTeam.coach != nil ? 600 : 0
        return playerWages + coachWage + facilityCostPerMatch
    }

    // MARK: - Money

    func spend(_ amount: Int, label: String, kind: Transaction.Kind) {
        guard amount > 0 else { return }
        funds -= amount
        record(-amount, label: label, kind: kind)
    }

    func earn(_ amount: Int, label: String, kind: Transaction.Kind) {
        guard amount != 0 else { return }
        funds += amount
        record(amount, label: label, kind: kind)
    }

    private func record(_ amount: Int, label: String, kind: Transaction.Kind) {
        ledger.insert(Transaction(day: playerTeam.wins + playerTeam.losses, label: label, amount: amount, kind: kind), at: 0)
        if ledger.count > ledgerLimit { ledger.removeLast(ledger.count - ledgerLimit) }
    }

    // MARK: - League

    func initLeague() {
        league = AmateurLeague.generate(chapter: chapter, referenceOverall: playerTeam.averageOverall)
        playerDatabase.assignSquads(to: league.teams)
    }

    func leagueOpponentTeam() -> Team? {
        guard let opp = league.nextOpponent else { return nil }
        let squad = playerDatabase.squad(forTeamName: opp.name)
        return Team.leagueOpponent(
            name: opp.name,
            averageOverall: opp.averageOverall,
            chapter: chapter,
            squad: squad
        )
    }

    func startLeagueMatch() {
        guard let opp = leagueOpponentTeam() else { return }
        activeOpponent = opp
        activeOpponentIsBoss = false
        screen = .tactics
    }

    /// Optional end-of-chapter boss: a stronger AXIOM lineup for a bonus payout.
    func startBossMatch() {
        guard chapter >= 2, !hasFlag("boss_\(chapter)_done") else { return }
        let base = 55 + chapter * 12
        var squad: [Player] = []
        for role in Role.allCases {
            var p = Player.generate(bias: role, chapter: chapter + 2)
            while p.stats.overall < base {
                p.stats.mechanics = min(99, p.stats.mechanics + 1)
                p.stats.gameSense = min(99, p.stats.gameSense + 1)
                p.stats.teamwork  = min(99, p.stats.teamwork  + 1)
                p.stats.mental    = min(99, p.stats.mental    + 1)
                p.stats.stamina   = min(99, p.stats.stamina   + 1)
            }
            p.salary = Player.salaryFor(overall: p.stats.overall)
            squad.append(p)
        }
        activeOpponent = Team(
            id: UUID(),
            name: "AXIOM ELITE",
            roster: squad,
            coach: Coach.generate(chapter: chapter + 2),
            wins: 0,
            losses: 0
        )
        activeOpponentIsBoss = true
        selectedTactic = .adapt
        screen = .tactics
    }

    // MARK: - Transfer Market

    static func signingFee(for player: Player) -> Int {
        500 + player.stats.overall * 40
    }

    func signPlayer(_ player: Player) {
        let fee = GameState.signingFee(for: player)
        guard funds >= fee else { return }
        var p = player
        p.isRecruited = true
        playerTeam.roster.append(p)
        playerDatabase.sign(id: player.id, byPlayer: true)
        spend(fee, label: "Signing bonus — \(player.tag)", kind: .signing)
        SaveManager.autosave(self)
    }

    func releasePlayer(id: UUID) {
        if let p = playerTeam.roster.first(where: { $0.id == id }) {
            earn(300, label: "Release fee received — \(p.tag)", kind: .release)
        }
        playerTeam.roster.removeAll { $0.id == id }
        playerDatabase.release(id: id)
        SaveManager.autosave(self)
    }

    // MARK: - Coach

    static func coachHireCost(for coach: Coach) -> Int {
        2_000 + coach.stats.overall * 50
    }

    func openCoachHire() {
        pendingCoachPool = (0..<3).map { _ in Coach.generate(chapter: chapter) }
        isHiringCoach = true
    }

    func hireCoach(_ coach: Coach) {
        let cost = GameState.coachHireCost(for: coach)
        guard funds >= cost else { return }
        spend(cost, label: "Coach hire — \(coach.tag)", kind: .coach)
        playerTeam.coach = coach
        isHiringCoach = false
        pendingCoachPool = []
        SaveManager.autosave(self)
    }

    func fireCoach() {
        playerTeam.coach = nil
        SaveManager.autosave(self)
    }

    // MARK: - Match Result

    /// Base prize money for a league match at the current chapter.
    func matchPrize(won: Bool) -> Int {
        won ? (4_000 + chapter * 1_500) : (1_000 + chapter * 500)
    }

    /// Applies the outcome of the match currently in `activeOpponent`.
    func resolveActiveMatch(won: Bool, hasMVP: Bool = false) {
        let isBoss = activeOpponentIsBoss
        let opponentName = activeOpponent?.name ?? "opponent"
        activeOpponent = nil
        activeOpponentIsBoss = false
        recordMatchResult(won: won, hasMVP: hasMVP, isBoss: isBoss, opponentName: opponentName)
    }

    func recordMatchResult(won: Bool, hasMVP: Bool = false, isBoss: Bool = false, opponentName: String = "opponent") {
        if won { playerTeam.wins += 1 } else { playerTeam.losses += 1 }
        // Boss matches are exhibition games — they build reputation but do not
        // count toward the league table or season qualification.
        if !isBoss {
            if won { seasonWins += 1 } else { seasonLosses += 1 }
        }
        awardXP(amount: won ? 50 : 20)

        // Prize money scales with the chapter; the boss pays a bonus.
        var prize = matchPrize(won: won)
        if isBoss && won { prize += 15_000 }
        earn(prize, label: won ? "Match win — \(opponentName)" : "Match loss — \(opponentName)", kind: .prize)

        // Deduct wages for this matchday.
        let wages = weeklyWages
        spend(wages, label: "Wages & facilities", kind: .wages)

        // Extra reward for an MVP performance.
        if hasMVP && won { earn(750, label: "MVP bonus", kind: .board) }

        if isBoss && won {
            setFlag("boss_\(chapter)_done")
            playerTeam.wins += 1   // boss wins count double toward reputation
        }

        // Advance the league (non-boss matches only).
        if !isBoss {
            league.advanceMatchday(playerWon: won)
        }

        if league.isSeasonOver {
            completeChapter()
        }

        SaveManager.autosave(self)
    }

    // MARK: - Chapter Progression

    private func completeChapter() {
        let qualified = league.playerQualified(
            playerWins: seasonWins,
            playerLosses: seasonLosses
        )
        let isFinal = chapter >= GameState.finalChapter

        if qualified && isFinal {
            pendingChapterResult = .champion
            pendingStoryLines = Story.ending
            chapter = GameState.finalChapter + 1
            league.season += 1
        } else if qualified {
            pendingChapterResult = .advanced
            pendingStoryLines = Story.chapterAdvance(from: chapter)
            chapter += 1
            league = AmateurLeague.generate(chapter: chapter, referenceOverall: playerTeam.averageOverall)
            league.season += 1
            playerDatabase.assignSquads(to: league.teams)
            seasonWins = 0
            seasonLosses = 0
        } else {
            pendingChapterResult = .missed
            pendingStoryLines = Story.missedPlayoffs(chapter: chapter)
            // Replay the same chapter with a freshly drawn league.
            league = AmateurLeague.generate(chapter: chapter, referenceOverall: playerTeam.averageOverall)
            playerDatabase.assignSquads(to: league.teams)
            seasonWins = 0
            seasonLosses = 0
        }
    }

    // MARK: - Training

    func trainStat(playerID: UUID, key: StatKey) {
        guard let idx = playerTeam.roster.firstIndex(where: { $0.id == playerID }) else { return }
        let p = playerTeam.roster[idx]
        let cost = trainingCost(player: p, key: key)
        guard funds >= cost else { return }
        let gain = trainingGain(player: p, key: key)
        spend(cost, label: "Training — \(p.tag) \(key.rawValue) +\(gain)", kind: .training)
        addStat(key, gain: gain, toPlayerAt: idx)
        playerDatabase.updatePlayerData(playerTeam.roster[idx])
        SaveManager.autosave(self)
    }

    func trainingCost(player: Player, key: StatKey) -> Int {
        let isPrimary = player.role.statBias == key
        return (isPrimary ? 600 : 450) + (player.level - 1) * 75
    }

    /// Training a priority stat yields a bigger gain: +4 for the role's key
    /// stat, +3 for the personality's natural strength, +2 otherwise.
    func trainingGain(player: Player, key: StatKey) -> Int {
        if player.role.statBias == key { return 4 }
        if player.personality.secondaryStat == key { return 3 }
        return 2
    }

    private func addStat(_ key: StatKey, gain: Int, toPlayerAt index: Int) {
        switch key {
        case .mechanics: playerTeam.roster[index].stats.mechanics = min(99, playerTeam.roster[index].stats.mechanics + gain)
        case .gameSense: playerTeam.roster[index].stats.gameSense = min(99, playerTeam.roster[index].stats.gameSense + gain)
        case .teamwork:  playerTeam.roster[index].stats.teamwork  = min(99, playerTeam.roster[index].stats.teamwork  + gain)
        case .mental:    playerTeam.roster[index].stats.mental    = min(99, playerTeam.roster[index].stats.mental    + gain)
        case .stamina:   playerTeam.roster[index].stats.stamina   = min(99, playerTeam.roster[index].stats.stamina   + gain)
        }
    }

    // MARK: - XP / Levelling

    func awardXP(amount: Int) {
        for i in playerTeam.roster.indices {
            playerTeam.roster[i].xp += amount + Int.random(in: 0...10)
            while playerTeam.roster[i].xp >= playerTeam.roster[i].xpToNextLevel {
                playerTeam.roster[i].xp -= playerTeam.roster[i].xpToNextLevel
                playerTeam.roster[i].level += 1
                boostStats(index: i)
            }
        }
    }

    /// Level-up growth leans on what the player is naturally good at.
    private func boostStats(index: Int) {
        let p = playerTeam.roster[index]
        let boost = 2 + p.potential
        addStat(p.role.statBias, gain: boost, toPlayerAt: index)
        addStat(p.personality.secondaryStat, gain: max(1, boost - 1), toPlayerAt: index)
    }

    // MARK: - Story Flags

    func setFlag(_ flag: String) { storyFlags.insert(flag) }
    func hasFlag(_ flag: String) -> Bool { storyFlags.contains(flag) }
}

// MARK: - Chapter Review
/// Shown on the overworld after a season concludes.
enum ChapterReview: Codable {
    case advanced   // qualified for the next chapter
    case missed     // failed to make the top two; replay the chapter
    case champion   // won the Grand Final

    var title: String {
        switch self {
        case .advanced: return "QUALIFIED!"
        case .missed:   return "SEASON OVER"
        case .champion: return "CHAMPIONS!"
        }
    }
}
