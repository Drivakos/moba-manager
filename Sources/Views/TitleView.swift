import SwiftUI

struct TitleView: View {
    @Environment(GameState.self) var gameState
    @State private var showPressStart = true
    @State private var blink = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            // Outer border
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.gbDark, lineWidth: 2)
                .padding(12)

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 4) {
                    Text("MOBA")
                        .font(.custom(GB.font, size: 56))
                        .foregroundColor(.gbLightest)
                        .shadow(color: .gbDark, radius: 0, x: 3, y: 3)

                    Text("MANAGER")
                        .font(.custom(GB.font, size: 28))
                        .foregroundColor(.gbLight)
                        .shadow(color: .gbDarkest, radius: 0, x: 2, y: 2)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: appeared)

                Spacer().frame(height: 40)

                // Mini team illustration
                MiniTeamView()
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)

                Spacer().frame(height: 40)

                // Subtitle
                Text("\"Build your legend.\"")
                    .font(.custom(GB.fontMono, size: 13))
                    .foregroundColor(.gbDark)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

                Spacer().frame(height: 32)

                // Buttons
                VStack(spacing: 10) {
                    TitleButton(label: "NEW GAME") {
                        gameState.screen = .teamSetup
                    }

                    if SaveManager.hasAnySave() {
                        TitleButton(label: "LOAD GAME") {
                            gameState.screen = .loadGame
                        }
                    }

                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)

                Spacer()

                Text("v1.0  ©2026")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbDark)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            appeared = true
            blink = true
        }
    }
}

// MARK: - Title Button
struct TitleButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbDarkest)
                .frame(width: 180)
                .padding(.vertical, 10)
                .background(Color.gbLightest)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Team Illustration
struct MiniTeamView: View {
    let colors: [Color] = [.gbLight, .gbDark, .gbLightest, .gbLight, .gbDark]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { i in
                MiniPlayerChip(color: colors[i])
            }
        }
    }
}

struct MiniPlayerChip: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 22, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gbDarkest, lineWidth: 1.5)
                )
            // Eyes
            HStack(spacing: 5) {
                Circle().fill(Color.gbDarkest).frame(width: 4, height: 4)
                Circle().fill(Color.gbDarkest).frame(width: 4, height: 4)
            }
            .offset(y: 2)
        }
    }
}
