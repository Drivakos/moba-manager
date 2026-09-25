import Foundation

// MARK: - Franchise Store
// Remembers the current career independently of the numbered save slots, so a
// player who backs out to the title screen can pick up where they left off.
// Every auto-save refreshes it; explicit slot saves do too.
enum FranchiseStore {

    private static let key = "mobaManager.franchise.current"

    static func autosave(_ gameState: GameState) {
        let payload = SaveData(
            playerTeam: gameState.playerTeam,
            chapter: gameState.chapter,
            storyFlags: gameState.storyFlags,
            playerPosition: gameState.playerPosition,
            managerName: gameState.managerName,
            funds: gameState.funds,
            league: gameState.league,
            playerDatabase: gameState.playerDatabase
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func hasSave() -> Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }

    @discardableResult
    static func load(into gameState: GameState) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: key),
              let d = try? JSONDecoder().decode(SaveData.self, from: data)
        else { return false }

        gameState.playerTeam     = d.playerTeam
        gameState.chapter        = d.chapter
        gameState.storyFlags     = d.storyFlags
        gameState.playerPosition = d.playerPosition
        gameState.managerName    = d.managerName
        gameState.funds          = d.funds
        gameState.league         = d.league
        gameState.playerDatabase = d.playerDatabase
        return true
    }

    static func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
