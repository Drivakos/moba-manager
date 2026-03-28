import Foundation

// MARK: - Map Data (16x16)
// 0=floor, 1=wall, 2=HQ, 3=cafe, 4=training, 5=arena, 6=tree
enum MapData {
    // Player spawns at col=1, row=1.
    // Training (~~ tiles) are at row 1-2 cols 5-7 — 4 steps right from spawn.
    // Cafe tiles are at row 4-5 cols 12-13.
    static let grid: [[Int]] = [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 1],  // training 4 steps right
        [1, 0, 2, 2, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 1],  // HQ col 2-3
        [1, 0, 2, 2, 0, 0, 0, 0, 6, 6, 6, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 6, 0, 6, 0, 3, 3, 0, 1],  // cafe col 12-13
        [1, 0, 0, 0, 0, 0, 0, 0, 6, 6, 6, 0, 3, 3, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],  // second training patch
        [1, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 1],  // arena col 12-13
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 1],
        [1, 0, 6, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 0, 6, 6, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 1],  // third cafe
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ]

    static func tile(col: Int, row: Int) -> TileType {
        guard row >= 0 && row < grid.count,
              col >= 0 && col < grid[row].count
        else { return .wall }
        return TileType(rawValue: grid[row][col]) ?? .wall
    }

    // Special tile action labels
    static func label(for tile: TileType) -> String? {
        switch tile {
        case .hq:       return "HQ"
        case .cafe:     return "CAFE"
        case .training: return "~~~"
        case .arena:    return "ARENA"
        default:        return nil
        }
    }

    // Story dialogue for special tiles
    static func entryDialogue(tile: TileType, gameState: GameState) -> String? {
        switch tile {
        case .hq:
            if gameState.playerTeam.isComplete {
                return "Team HQ. Your squad is full — head to the Arena!"
            }
            return "Team HQ. Keep scouting — you need \(5 - gameState.playerTeam.roster.count) more player(s)."
        case .arena:
            if gameState.playerTeam.roster.isEmpty {
                return "The Arena! You need a team first. Go scout some talent."
            }
            return "The Arena! Your team is ready to compete. (Tap A)"
        default:
            return nil
        }
    }
}
