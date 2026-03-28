import SwiftUI
import SpriteKit

// MARK: - GameBoy Palette (SwiftUI)
extension Color {
    static let gbDarkest  = Color(red: 0.059, green: 0.220, blue: 0.059)  // #0f380f
    static let gbDark     = Color(red: 0.188, green: 0.384, blue: 0.188)  // #306230
    static let gbLight    = Color(red: 0.545, green: 0.675, blue: 0.059)  // #8bac0f
    static let gbLightest = Color(red: 0.608, green: 0.737, blue: 0.059)  // #9bbc0f
}

// MARK: - GameBoy Palette (SpriteKit)
extension SKColor {
    static let gbDarkest  = SKColor(red: 0.059, green: 0.220, blue: 0.059, alpha: 1)
    static let gbDark     = SKColor(red: 0.188, green: 0.384, blue: 0.188, alpha: 1)
    static let gbLight    = SKColor(red: 0.545, green: 0.675, blue: 0.059, alpha: 1)
    static let gbLightest = SKColor(red: 0.608, green: 0.737, blue: 0.059, alpha: 1)
}

// MARK: - Layout Constants
enum GB {
    static let tileSize: CGFloat = 40
    static let mapCols = 16
    static let mapRows = 16
    static let font = "Courier-Bold"
    static let fontMono = "Courier"

    static func font(_ size: CGFloat) -> Font {
        .custom(font, size: size)
    }
}

// MARK: - Shared SwiftUI Components
import SwiftUI

struct GBDialogueBar: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom(GB.fontMono, size: 11))
            .foregroundColor(.gbDarkest)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.gbLightest)
            .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1.5))
    }
}

struct StatRowView: View {
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.custom(GB.font, size: 10))
                .foregroundColor(.gbLight)
                .frame(width: 56, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gbDarkest).frame(height: 8)
                    Rectangle().fill(Color.gbLightest)
                        .frame(width: geo.size.width * CGFloat(value) / 99, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(value)")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLightest)
                .frame(width: 26, alignment: .trailing)
        }
    }
}

struct PixelPortrait: View {
    let index: Int
    let role: Role

    private let palette: [Color] = [.gbDark, .gbLight, .gbLightest, .gbDarkest, .gbDark]

    var body: some View {
        ZStack {
            palette[index % palette.count]
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(Color.gbLightest)
                        .frame(width: 52, height: 60)
                        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.gbDarkest).frame(width: 8, height: 8)
                            Rectangle().fill(Color.gbDarkest).frame(width: 8, height: 8)
                        }
                        Rectangle().fill(Color.gbDark).frame(width: 20, height: 4)
                    }
                    Text(role.abbreviation)
                        .font(.custom(GB.fontMono, size: 7))
                        .foregroundColor(.gbDark)
                        .offset(y: 22)
                }
                Rectangle()
                    .fill(palette[index % palette.count])
                    .frame(width: 64, height: 26)
                    .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1.5))
            }
        }
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
        .clipped()
    }
}

// MARK: - Tile Types
enum TileType: Int {
    case floor       = 0
    case wall        = 1
    case hq          = 2  // Your team HQ
    case cafe        = 3  // Gaming cafe — encounter zone
    case training    = 4  // Training ground — encounter zone
    case arena       = 5  // Tournament arena
    case tree        = 6  // Decorative wall

    var isWalkable: Bool {
        switch self {
        case .floor, .cafe, .training: return true
        default: return false
        }
    }

    var isEncounterZone: Bool {
        self == .cafe || self == .training
    }

    var encounterChance: Double {
        switch self {
        case .training: return 0.75
        case .cafe:     return 0.65
        default:        return 0
        }
    }

    var skColor: SKColor {
        switch self {
        case .floor:    return SKColor(red: 0.60, green: 0.73, blue: 0.06, alpha: 1)
        case .wall:     return .gbDarkest
        case .hq:       return SKColor(red: 0.18, green: 0.38, blue: 0.18, alpha: 1)
        case .cafe:     return SKColor(red: 0.30, green: 0.52, blue: 0.12, alpha: 1)
        case .training: return SKColor(red: 0.20, green: 0.45, blue: 0.08, alpha: 1)
        case .arena:    return SKColor(red: 0.14, green: 0.30, blue: 0.10, alpha: 1)
        case .tree:     return SKColor(red: 0.06, green: 0.22, blue: 0.06, alpha: 1)
        }
    }
}
