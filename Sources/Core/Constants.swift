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

// MARK: - Scanline Overlay (LCD effect)
struct GBScanlineView: View {
    var opacity: Double = 0.10
    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.black.opacity(opacity))
                )
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Corner-mark border
struct GBCornerBorder: View {
    var color: Color = .gbLight
    var lineWidth: CGFloat = 1.5
    var cornerSize: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Rectangle().stroke(color.opacity(0.4), lineWidth: lineWidth)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: cornerSize)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: cornerSize, y: 0))
                    p.move(to: CGPoint(x: w - cornerSize, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: cornerSize))
                    p.move(to: CGPoint(x: w, y: h - cornerSize)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w - cornerSize, y: h))
                    p.move(to: CGPoint(x: cornerSize, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: 0, y: h - cornerSize))
                }
                .stroke(color, lineWidth: lineWidth + 1)
            }
        }
    }
}

// MARK: - Blink modifier
struct GBBlink: ViewModifier {
    @State private var visible = true
    let interval: Double
    func body(content: Content) -> some View {
        content.opacity(visible ? 1 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                    withAnimation(.none) { visible.toggle() }
                }
            }
    }
}
extension View {
    func gbBlink(interval: Double = 0.55) -> some View { modifier(GBBlink(interval: interval)) }
}

// MARK: - Segmented stat bar (16-block GB style)
struct GBSegmentBar: View {
    let value: Int
    var segments: Int = 16
    private var filled: Int { Int(Double(value) / 99.0 * Double(segments)) }
    private var barColor: Color {
        let pct = Double(value) / 99.0
        if pct > 0.75 { return .gbLightest }
        if pct > 0.4  { return .gbLight }
        return .gbDark
    }
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? barColor : Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbDark.opacity(0.35), lineWidth: 0.5))
            }
        }
        .frame(height: 8)
    }
}

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
            GBSegmentBar(value: value)
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

    private let shirtColors: [Color] = [.gbDark, .gbLight, .gbLightest, .gbDark, .gbDarkest]
    private var shirtColor: Color { shirtColors[index % shirtColors.count] }

    // Role-specific hat heights (creates visual variety)
    private var hatHeight: CGFloat {
        switch role {
        case .mid:      return 16
        case .carry:    return 10
        case .offlaner: return 6
        default:        return 12
        }
    }

    var body: some View {
        ZStack {
            // Background tile
            Rectangle().fill(shirtColor.opacity(0.35))

            VStack(spacing: 0) {
                // Hat / hair block
                ZStack {
                    Rectangle().fill(Color.gbDarkest).frame(width: 48, height: hatHeight)
                    // Hat brim stripe
                    Rectangle().fill(Color.gbDark).frame(width: 52, height: 3)
                        .offset(y: hatHeight / 2 - 1.5)
                }
                .frame(width: 64, height: hatHeight + 3)

                // Face
                ZStack {
                    Rectangle()
                        .fill(Color.gbLightest)
                        .frame(width: 48, height: 50)
                        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1.5))
                    VStack(spacing: 7) {
                        HStack(spacing: 10) {
                            // Eyes vary by index
                            Rectangle().fill(Color.gbDarkest).frame(width: 7, height: index % 2 == 0 ? 7 : 5)
                            Rectangle().fill(Color.gbDarkest).frame(width: 7, height: index % 2 == 0 ? 7 : 5)
                        }
                        // Mouth
                        Rectangle().fill(Color.gbDarkest).frame(width: 16, height: 3)
                    }
                    .offset(y: 5)
                }

                // Jersey / body
                ZStack {
                    Rectangle()
                        .fill(shirtColor)
                        .frame(width: 64, height: 28)
                        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1.5))
                    // Jersey number or role stripe
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.gbDarkest.opacity(0.5)).frame(width: 1, height: 16)
                        Text(role.abbreviation)
                            .font(.custom(GB.font, size: 9))
                            .foregroundColor(shirtColor == .gbDarkest ? .gbLightest : .gbDarkest)
                        Rectangle().fill(Color.gbDarkest.opacity(0.5)).frame(width: 1, height: 16)
                    }
                }
            }
        }
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
        .clipped()
    }
}

// MARK: - Shared Layout Components

/// Standardised screen header — title + optional subtitle, left/right accent strips
struct GBScreenHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        ZStack {
            Color.gbDark

            HStack(spacing: 0) {
                Rectangle().fill(Color.gbDarkest).frame(width: 5)
                Spacer()
                VStack(spacing: 3) {
                    Text(title.uppercased())
                        .font(.custom(GB.font, size: 14))
                        .foregroundColor(.gbLightest)
                    if let sub = subtitle {
                        Text(sub.uppercased())
                            .font(.custom(GB.fontMono, size: 10))
                            .foregroundColor(.gbLight)
                    }
                }
                Spacer()
                Rectangle().fill(Color.gbDarkest).frame(width: 5)
            }
        }
        .frame(height: subtitle != nil ? 58 : 48)
        .overlay(Rectangle().stroke(Color.gbDark.opacity(0.6), lineWidth: 1), alignment: .bottom)
    }
}

/// Section label row — a coloured bar with title
struct GBSectionLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.gbLight).frame(width: 3, height: 14)
            Text(text.uppercased())
                .font(.custom(GB.font, size: 10))
                .foregroundColor(.gbLight)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.gbDark)
    }
}

/// Standardised back button
struct GBBackButton: View {
    let action: () -> Void
    var label: String = "◀  BACK"
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbLightest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.gbDark)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
    }
}

/// Primary action button (call to action)
struct GBPrimaryButton: View {
    let label: String
    var enabled: Bool = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 15))
                .foregroundColor(enabled ? .gbLightest : .gbDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(enabled ? Color.gbDark : Color.gbDarkest)
                .overlay(
                    ZStack {
                        Rectangle().stroke(enabled ? Color.gbLight : Color.gbDarkest, lineWidth: enabled ? 2 : 1)
                        if enabled { GBCornerBorder(color: .gbDark, lineWidth: 1, cornerSize: 8) }
                    }
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
