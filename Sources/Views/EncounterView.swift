import SwiftUI

struct EncounterView: View {
    @Environment(GameState.self) var gameState
    @State private var revealed = false
    @State private var dialogueIndex = 0

    var recruit: Player? { gameState.pendingRecruit }

    private var dialogues: [String] {
        guard let p = recruit else { return [] }
        return [
            "\"\(p.catchphrase)\"",
            "Age \(p.age) • \(p.role.rawValue) [\(p.role.abbreviation)]",
            "Personality: \(p.personality.rawValue) — \(p.personality.description)",
            "Overall: \(p.stats.overall)/100"
        ]
    }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerBar

                Spacer()

                // Recruit portrait + stats card
                if let p = recruit {
                    recruitCard(p)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Dialogue box
                if dialogueIndex < dialogues.count {
                    GBDialogueBar(text: dialogues[dialogueIndex])
                        .padding(.horizontal, 16)
                }

                Spacer().frame(height: 20)

                // Action buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .onAppear { revealed = false }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            Text("! ENCOUNTER !")
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbLightest)
        }
        .frame(height: 44)
    }

    // MARK: - Recruit Card
    func recruitCard(_ p: Player) -> some View {
        HStack(spacing: 16) {
            // Portrait
            PixelPortrait(index: p.portraitIndex, role: p.role)
                .frame(width: 80, height: 100)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(p.name.uppercased())
                    .font(.custom(GB.font, size: 13))
                    .foregroundColor(.gbLightest)

                Text("「\(p.tag)」· Age \(p.age)")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbLight)

                Divider().background(Color.gbDark)

                ForEach(p.stats.display, id: \.0.rawValue) { key, val in
                    StatRowView(label: key.rawValue, value: val)
                }
            }
        }
        .padding(12)
        .background(Color.gbDark)
        .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 2))
    }

    // MARK: - Action Buttons
    var actionButtons: some View {
        HStack(spacing: 20) {
            // PASS
            Button {
                dismiss(recruited: false)
            } label: {
                Text("PASS")
                    .font(.custom(GB.font, size: 15))
                    .foregroundColor(.gbDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gbLightest)
                    .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 2))
            }
            .buttonStyle(.plain)

            // RECRUIT
            Button {
                if dialogueIndex < dialogues.count - 1 {
                    withAnimation { dialogueIndex += 1 }
                } else {
                    dismiss(recruited: true)
                }
            } label: {
                Text(dialogueIndex < dialogues.count - 1 ? "NEXT ▶" : "RECRUIT!")
                    .font(.custom(GB.font, size: 15))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Dismiss
    private func dismiss(recruited: Bool) {
        if recruited, let p = recruit {
            gameState.recruit(p)
        }
        gameState.pendingRecruit = nil
        gameState.isEncountering = false
    }
}

// MARK: - Pixel Portrait
struct PixelPortrait: View {
    let index: Int
    let role: Role

    private var baseColor: Color {
        switch role {
        case .carry:    return .gbLight
        case .support:  return .gbDark
        case .jungler:  return Color(red: 0.25, green: 0.50, blue: 0.10)
        case .mid:      return Color(red: 0.40, green: 0.60, blue: 0.05)
        case .offlaner: return .gbDarkest
        }
    }

    var body: some View {
        ZStack {
            baseColor

            // Simple pixel-art face
            VStack(spacing: 0) {
                Spacer()
                // Head
                ZStack {
                    Rectangle()
                        .fill(Color.gbLightest)
                        .frame(width: 50, height: 56)
                        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))

                    VStack(spacing: 8) {
                        // Eyes
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.gbDarkest).frame(width: 8, height: 8)
                            Rectangle().fill(Color.gbDarkest).frame(width: 8, height: 8)
                        }
                        // Mouth
                        Rectangle().fill(Color.gbDark).frame(width: 20, height: 4)
                    }
                }
                // Body
                Rectangle()
                    .fill(baseColor)
                    .frame(width: 60, height: 24)
                    .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1.5))
            }
        }
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
        .clipped()
    }
}

// MARK: - Stat Row
struct StatRowView: View {
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLight)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gbDarkest).frame(height: 7)
                    Rectangle()
                        .fill(barColor(value))
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 7)
                }
            }
            .frame(height: 7)

            Text("\(value)")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLightest)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func barColor(_ v: Int) -> Color {
        if v >= 75 { return .gbLightest }
        if v >= 50 { return .gbLight }
        return .gbDark
    }
}

// MARK: - GB Dialogue Bar
struct GBDialogueBar: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom(GB.fontMono, size: 12))
            .foregroundColor(.gbDarkest)
            .multilineTextAlignment(.leading)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gbLightest)
            .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
    }
}
