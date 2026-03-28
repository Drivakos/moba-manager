import Foundation

// MARK: - Full save payload
struct SaveData: Codable {
    let playerTeam: Team
    let chapter: Int
    let storyFlags: Set<String>
    let playerPosition: TilePosition
    let managerName: String
    let funds: Int
    let league: AmateurLeague
    let playerDatabase: PlayerDatabase
}

// MARK: - Slot metadata (shown in the save/load screen)
struct SaveSlot: Codable, Identifiable {
    let id: Int           // 1, 2, or 3
    let teamName: String
    let managerName: String
    let chapter: Int
    let wins: Int
    let losses: Int
    let rosterCount: Int
    let savedAt: Date
    let payload: SaveData

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: savedAt)
    }

    var chapterLabel: String { "CH.\(chapter)" }
    var recordLabel: String  { "W:\(wins) L:\(losses)" }
}

// MARK: - SaveManager
enum SaveManager {
    static let slotCount = 3
    private static let keyPrefix = "mobaManager.slot."
    private static let lastSlotKey = "mobaManager.lastSlot"

    // MARK: - Read all slots
    static func allSlots() -> [SaveSlot?] {
        (1...slotCount).map { readSlot($0) }
    }

    static func hasAnySave() -> Bool {
        (1...slotCount).contains { readSlot($0) != nil }
    }

    static var lastUsedSlot: Int {
        get { UserDefaults.standard.integer(forKey: lastSlotKey).clamped(to: 1...slotCount) }
        set { UserDefaults.standard.set(newValue, forKey: lastSlotKey) }
    }

    // MARK: - Save
    static func save(gameState: GameState, slot: Int) {
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
        let meta = SaveSlot(
            id: slot,
            teamName: gameState.playerTeam.name,
            managerName: gameState.managerName,
            chapter: gameState.chapter,
            wins: gameState.playerTeam.wins,
            losses: gameState.playerTeam.losses,
            rosterCount: gameState.playerTeam.roster.count,
            savedAt: Date(),
            payload: payload
        )
        if let data = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(data, forKey: key(slot))
            lastUsedSlot = slot
        }
    }

    // MARK: - Auto-save to last used slot (or slot 1)
    static func autosave(_ gameState: GameState) {
        let slot = lastUsedSlot > 0 ? lastUsedSlot : 1
        save(gameState: gameState, slot: slot)
    }

    // MARK: - Load
    @discardableResult
    static func load(slot: Int, into gameState: GameState) -> Bool {
        guard let meta = readSlot(slot) else { return false }
        let d = meta.payload
        gameState.playerTeam         = d.playerTeam
        gameState.chapter            = d.chapter
        gameState.storyFlags         = d.storyFlags
        gameState.playerPosition     = d.playerPosition
        gameState.managerName        = d.managerName
        gameState.funds              = d.funds
        gameState.league             = d.league
        gameState.playerDatabase     = d.playerDatabase
        gameState.screen             = .overworld
        lastUsedSlot = slot
        return true
    }

    // MARK: - Delete
    static func delete(slot: Int) {
        UserDefaults.standard.removeObject(forKey: key(slot))
        if lastUsedSlot == slot { lastUsedSlot = 0 }
    }

    // MARK: - Helpers
    private static func readSlot(_ slot: Int) -> SaveSlot? {
        guard let data = UserDefaults.standard.data(forKey: key(slot)) else { return nil }
        return try? JSONDecoder().decode(SaveSlot.self, from: data)
    }

    private static func key(_ slot: Int) -> String { "\(keyPrefix)\(slot)" }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
