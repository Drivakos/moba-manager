import SwiftUI

struct TitleView: View {
    @Environment(GameState.self) var gameState
    @State private var appeared = false
    @State private var starPhase: Double = 0

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            // Pixel star-field background
            StarFieldView(phase: starPhase)
                .opacity(appeared ? 0.6 : 0)
                .animation(.easeIn(duration: 1.2), value: appeared)

            // Outer screen frame
            GBCornerBorder(color: .gbLight, lineWidth: 2, cornerSize: 16)
                .padding(10)

            // Inner dim border
            Rectangle()
                .stroke(Color.gbDark.opacity(0.5), lineWidth: 1)
                .padding(20)

            VStack(spacing: 0) {
                Spacer()

                // ── TITLE BLOCK ──
                VStack(spacing: 0) {
                    // Decorative top rule
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.gbDark).frame(height: 1)
                        Text("◆")
                            .font(.custom(GB.fontMono, size: 8))
                            .foregroundColor(.gbDark)
                        Rectangle().fill(Color.gbDark).frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                    Text("MOBA")
                        .font(.custom(GB.font, size: 62))
                        .foregroundColor(.gbLightest)
                        .shadow(color: .gbDark, radius: 0, x: 4, y: 4)
                        .shadow(color: .gbDark.opacity(0.4), radius: 0, x: 8, y: 8)

                    Text("MANAGER")
                        .font(.custom(GB.font, size: 26))
                        .foregroundColor(.gbLight)
                        .tracking(6)
                        .shadow(color: .gbDarkest, radius: 0, x: 2, y: 2)

                    // Decorative bottom rule
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.gbDark).frame(height: 1)
                        Text("◆")
                            .font(.custom(GB.fontMono, size: 8))
                            .foregroundColor(.gbDark)
                        Rectangle().fill(Color.gbDark).frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.55), value: appeared)

                Spacer().frame(height: 36)

                // ── TEAM ILLUSTRATION ──
                MiniTeamView()
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)

                Spacer().frame(height: 10)

                Text("\"Build your legend.\"")
                    .font(.custom(GB.fontMono, size: 12))
                    .foregroundColor(.gbDark)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

                Spacer().frame(height: 36)

                // ── BUTTONS ──
                VStack(spacing: 10) {
                    TitleButton(label: "▶  NEW GAME") {
                        gameState.screen = .teamSetup
                    }
                    if SaveManager.hasAnySave() {
                        TitleButton(label: "◈  LOAD GAME", filled: false) {
                            gameState.screen = .loadGame
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)

                Spacer().frame(height: 20)

                // Blinking hint
                Text("PRESS START")
                    .font(.custom(GB.font, size: 11))
                    .foregroundColor(.gbDark)
                    .gbBlink(interval: 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.9), value: appeared)

                Spacer()

                Text("v1.0  ©2026")
                    .font(.custom(GB.fontMono, size: 9))
                    .foregroundColor(.gbDark.opacity(0.6))
                    .padding(.bottom, 18)
            }

            // Scanline overlay on top of everything
            GBScanlineView(opacity: 0.07)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            appeared = true
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                starPhase = 1
            }
        }
    }
}

// MARK: - Title Button
struct TitleButton: View {
    let label: String
    var filled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 14))
                .foregroundColor(filled ? .gbDarkest : .gbLightest)
                .frame(width: 200)
                .padding(.vertical, 11)
                .background(filled ? Color.gbLightest : Color.gbDarkest)
                .overlay(
                    ZStack {
                        Rectangle().stroke(Color.gbLight, lineWidth: 2)
                        // Corner accents
                        GBCornerBorder(color: .gbDark, lineWidth: 1, cornerSize: 6)
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Team Illustration
struct MiniTeamView: View {
    let configs: [(Color, String)] = [
        (.gbLight, "ADC"), (.gbDark, "SUP"), (.gbLightest, "JGL"),
        (.gbLight, "MID"), (.gbDark, "OFF")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                MiniPlayerChip(color: configs[i].0, label: configs[i].1, index: i)
            }
        }
    }
}

struct MiniPlayerChip: View {
    let color: Color
    let label: String
    let index: Int
    @State private var bounced = false

    var body: some View {
        ZStack {
            // Body
            Rectangle()
                .fill(color)
                .frame(width: 26, height: 36)
                .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1.5))

            VStack(spacing: 3) {
                // Hat pixel
                Rectangle()
                    .fill(Color.gbDarkest)
                    .frame(width: 18, height: 5)

                // Eyes
                HStack(spacing: 5) {
                    Circle().fill(Color.gbDarkest).frame(width: 4, height: 4)
                    Circle().fill(Color.gbDarkest).frame(width: 4, height: 4)
                }

                // Role label
                Text(label)
                    .font(.custom(GB.fontMono, size: 5))
                    .foregroundColor(.gbDarkest)
            }
            .offset(y: 2)
        }
        .offset(y: bounced ? -4 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12 + 0.7) {
                withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                    bounced = true
                }
            }
        }
    }
}

// MARK: - Star Field
struct StarFieldView: View {
    let phase: Double

    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let speed: CGFloat
    }

    private let stars: [Star] = (0..<40).map { i in
        Star(
            id: i,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 1...3),
            speed: CGFloat.random(in: 0.3...1.0)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                let yPos = (star.y + phase * star.speed * 0.04).truncatingRemainder(dividingBy: 1)
                Rectangle()
                    .fill(Color.gbDark)
                    .frame(width: star.size, height: star.size)
                    .position(
                        x: star.x * geo.size.width,
                        y: yPos * geo.size.height
                    )
            }
        }
    }
}
