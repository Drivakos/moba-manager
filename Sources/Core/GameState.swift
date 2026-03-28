import Foundation
import Observation

// MARK: - App Screen
enum AppScreen {
    case title
    case teamSetup
    case overworld
    case encounter
    case teamRoster
    case training
    case tactics
    case matchSim
    case tournamentBracket
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
    var funds: Int = 500

    // Pre-match tactic
    var selectedTactic: MatchTactic = .adapt

    // Story dialogue queue (lines shown in overworld after events)
    var pendingStoryLines: [StoryLine] = []

    // Encounter flow
    var pendingRecruit: Player? = nil
    var isEncountering: Bool = false

    // Draft flow
    var pendingDraftPool: [Player] = []
    var isDrafting: Bool = false

    // Coach hire flow
    var pendingCoachPool: [Coach] = []
    var isHiringCoach: Bool = false

    // Match flow
    var pendingMatch: MatchResult? = nil
    var activeOpponent: Team? = nil
    var isInMatch: Bool = false

    // Convenience
    var canRecruit: Bool { playerTeam.roster.count < 5 }

    func openDraft() {
        // Prioritise missing roles (up to 2), fill rest randomly
        let missing = Array(Set(Role.allCases).subtracting(playerTeam.coveredRoles).prefix(2))
        var biases: [Role?] = missing.map { Optional($0) }
        while biases.count < 3 { biases.append(nil) }
        pendingDraftPool = biases.shuffled().map { Player.generate(bias: $0, chapter: chapter) }
        isDrafting = true
    }

    func pickDraftPlayer(_ player: Player) {
        recruit(player)
        pendingDraftPool = []
        isDrafting = false
    }

    func skipDraft() {
        pendingDraftPool = []
        isDrafting = false
    }

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

    func recruit(_ player: Player) {
        var p = player
        p.isRecruited = true
        playerTeam.roster.append(p)
        SaveManager.autosave(self)
    }

    func releasePlayer(id: UUID) {
        playerTeam.roster.removeAll { $0.id == id }
    }

    func recordMatchResult(won: Bool, hasMVP: Bool = false) {
        if won { playerTeam.wins += 1 } else { playerTeam.losses += 1 }
        awardXP(amount: won ? 50 : 20)
        funds += won ? (hasMVP ? 650 : 500) : 150
        SaveManager.autosave(self)
    }

    func trainStat(playerID: UUID, key: StatKey) {
        guard let idx = playerTeam.roster.firstIndex(where: { $0.id == playerID }) else { return }
        let p = playerTeam.roster[idx]
        let isPrimary = p.role.statBias == key
        let cost = (isPrimary ? 200 : 150) + (p.level - 1) * 25
        guard funds >= cost else { return }
        funds -= cost
        switch key {
        case .mechanics: playerTeam.roster[idx].stats.mechanics = min(99, p.stats.mechanics + 3)
        case .gameSense: playerTeam.roster[idx].stats.gameSense = min(99, p.stats.gameSense + 3)
        case .teamwork:  playerTeam.roster[idx].stats.teamwork  = min(99, p.stats.teamwork  + 3)
        case .mental:    playerTeam.roster[idx].stats.mental    = min(99, p.stats.mental    + 3)
        case .stamina:   playerTeam.roster[idx].stats.stamina   = min(99, p.stats.stamina   + 3)
        }
    }

    func trainingCost(player: Player, key: StatKey) -> Int {
        let isPrimary = player.role.statBias == key
        return (isPrimary ? 200 : 150) + (player.level - 1) * 25
    }

    func awardXP(amount: Int) {
        for i in playerTeam.roster.indices {
            playerTeam.roster[i].xp += amount + Int.random(in: 0...10)
            // Level up check
            while playerTeam.roster[i].xp >= playerTeam.roster[i].xpToNextLevel {
                playerTeam.roster[i].xp -= playerTeam.roster[i].xpToNextLevel
                playerTeam.roster[i].level += 1
                // Boost a stat on level up based on potential
                boostStats(index: i)
            }
        }
    }

    private func boostStats(index: Int) {
        let p = playerTeam.roster[index]
        let boost = 2 + p.potential  // higher potential = bigger stat gains
        let key = p.role.statBias
        switch key {
        case .mechanics: playerTeam.roster[index].stats.mechanics = min(99, p.stats.mechanics + boost)
        case .gameSense: playerTeam.roster[index].stats.gameSense = min(99, p.stats.gameSense + boost)
        case .teamwork:  playerTeam.roster[index].stats.teamwork  = min(99, p.stats.teamwork  + boost)
        case .mental:    playerTeam.roster[index].stats.mental    = min(99, p.stats.mental    + boost)
        case .stamina:   playerTeam.roster[index].stats.stamina   = min(99, p.stats.stamina   + boost)
        }
    }

    func setFlag(_ flag: String) {
        storyFlags.insert(flag)
    }

    func hasFlag(_ flag: String) -> Bool {
        storyFlags.contains(flag)
    }

}
