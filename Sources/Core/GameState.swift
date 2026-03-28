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

    // Persistent player database (set list, tracked status)
    var playerDatabase: PlayerDatabase = PlayerDatabase.generate()

    // Pre-match tactic
    var selectedTactic: MatchTactic = .adapt

    // Story dialogue queue
    var pendingStoryLines: [StoryLine] = []

    // Coach hire flow
    var pendingCoachPool: [Coach] = []
    var isHiringCoach: Bool = false

    // Match flow
    var pendingMatch: MatchResult? = nil
    var activeOpponent: Team? = nil

    // Convenience
    var canSign: Bool { playerTeam.roster.count < 5 }

    var weeklyWages: Int {
        let playerWages = playerTeam.roster.reduce(0) { $0 + $1.salary }
        let coachWage  = playerTeam.coach != nil ? 600 : 0
        return playerWages + coachWage + facilityCostPerMatch
    }

    // MARK: - League

    func initLeague() {
        league = AmateurLeague.generate(chapter: chapter)
        playerDatabase.distributeToAITeams(league.teams)
    }

    func leagueOpponentTeam() -> Team? {
        guard let opp = league.nextOpponent else { return nil }
        return Team.generateOpponent(name: opp.name, chapter: chapter)
    }

    func startLeagueMatch() {
        guard let opp = leagueOpponentTeam() else { return }
        activeOpponent = opp
        screen = .tactics
    }

    // MARK: - Transfer Market

    func signPlayer(_ player: Player) {
        var p = player
        p.isRecruited = true
        playerTeam.roster.append(p)
        playerDatabase.sign(id: player.id, byPlayer: true)
        SaveManager.autosave(self)
    }

    func releasePlayer(id: UUID) {
        playerTeam.roster.removeAll { $0.id == id }
        playerDatabase.release(id: id)
        SaveManager.autosave(self)
    }

    // MARK: - Coach

    func openCoachHire() {
        pendingCoachPool = (0..<3).map { _ in Coach.generate(chapter: chapter) }
        isHiringCoach = true
    }

    func hireCoach(_ coach: Coach) {
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

    func recordMatchResult(won: Bool, hasMVP: Bool = false) {
        if won { playerTeam.wins += 1 } else { playerTeam.losses += 1 }
        awardXP(amount: won ? 50 : 20)

        // League prize
        let prize = won ? 5_000 : 1_500
        funds += prize

        // Deduct wages for this matchday
        funds -= weeklyWages

        // Advance the league
        league.advanceMatchday(playerWon: won)

        // New season when all matches done — redistribute AI rosters
        if league.isSeasonOver {
            league = AmateurLeague.generate(chapter: chapter)
            playerDatabase.distributeToAITeams(league.teams)
        }

        SaveManager.autosave(self)
    }

    // MARK: - Training

    func trainStat(playerID: UUID, key: StatKey) {
        guard let idx = playerTeam.roster.firstIndex(where: { $0.id == playerID }) else { return }
        let p = playerTeam.roster[idx]
        let isPrimary = p.role.statBias == key
        let cost = (isPrimary ? 600 : 450) + (p.level - 1) * 75
        guard funds >= cost else { return }
        funds -= cost
        switch key {
        case .mechanics: playerTeam.roster[idx].stats.mechanics = min(99, p.stats.mechanics + 3)
        case .gameSense: playerTeam.roster[idx].stats.gameSense = min(99, p.stats.gameSense + 3)
        case .teamwork:  playerTeam.roster[idx].stats.teamwork  = min(99, p.stats.teamwork  + 3)
        case .mental:    playerTeam.roster[idx].stats.mental    = min(99, p.stats.mental    + 3)
        case .stamina:   playerTeam.roster[idx].stats.stamina   = min(99, p.stats.stamina   + 3)
        }
        playerDatabase.updatePlayerData(playerTeam.roster[idx])
    }

    func trainingCost(player: Player, key: StatKey) -> Int {
        let isPrimary = player.role.statBias == key
        return (isPrimary ? 600 : 450) + (player.level - 1) * 75
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

    private func boostStats(index: Int) {
        let p = playerTeam.roster[index]
        let boost = 2 + p.potential
        let key = p.role.statBias
        switch key {
        case .mechanics: playerTeam.roster[index].stats.mechanics = min(99, p.stats.mechanics + boost)
        case .gameSense: playerTeam.roster[index].stats.gameSense = min(99, p.stats.gameSense + boost)
        case .teamwork:  playerTeam.roster[index].stats.teamwork  = min(99, p.stats.teamwork  + boost)
        case .mental:    playerTeam.roster[index].stats.mental    = min(99, p.stats.mental    + boost)
        case .stamina:   playerTeam.roster[index].stats.stamina   = min(99, p.stats.stamina   + boost)
        }
    }

    // MARK: - Story Flags

    func setFlag(_ flag: String) { storyFlags.insert(flag) }
    func hasFlag(_ flag: String) -> Bool { storyFlags.contains(flag) }
}
