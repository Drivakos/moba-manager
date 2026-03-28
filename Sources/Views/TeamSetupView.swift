import SwiftUI

// MARK: - Team Setup (shown once, after title)
struct TeamSetupView: View {
    @Environment(GameState.self) var gameState

    @State private var introIndex = 0
    @State private var phase: SetupPhase = .intro
    @State private var teamName = ""
    @State private var managerName = ""
    @State private var activeField: ActiveField? = nil
    @FocusState private var focused: ActiveField?

    enum SetupPhase { case intro, naming, done }
    enum ActiveField: Hashable { case team, manager }

    private var introLines: [StoryLine] { Story.intro }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            switch phase {
            case .intro:
                introScreen
            case .naming:
                namingScreen
            case .done:
                Color.gbDarkest.ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: phase)
    }

    // MARK: - Intro Dialogue
    var introScreen: some View {
        VStack(spacing: 0) {
            // Portrait area
            ZStack {
                Color.gbDark
                HStack {
                    NPCPortraitView(type: "mentor")
                        .frame(width: 100, height: 120)
                        .padding(.leading, 24)
                    Spacer()
                }
            }
            .frame(height: 160)

            Spacer()

            // Dialogue box
            VStack(alignment: .leading, spacing: 0) {
                // Speaker name
                Text("[\(introLines[introIndex].speaker)]")
                    .font(.custom(GB.font, size: 12))
                    .foregroundColor(.gbDark)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                // Text
                TypewriterText(
                    text: introLines[introIndex].text,
                    key: introIndex
                )
                .font(.custom(GB.fontMono, size: 13))
                .foregroundColor(.gbDarkest)
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tap hint
                HStack {
                    Spacer()
                    Text("▼ TAP")
                        .font(.custom(GB.font, size: 10))
                        .foregroundColor(.gbDark)
                        .padding(.trailing, 14)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.gbLightest)
            .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 3))
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if introIndex < introLines.count - 1 {
                introIndex += 1
            } else {
                withAnimation { phase = .naming }
            }
        }
    }

    // MARK: - Naming Screen
    var namingScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("SET UP YOUR SQUAD")
                .font(.custom(GB.font, size: 18))
                .foregroundColor(.gbLightest)

            Divider().background(Color.gbDark)

            // Manager name
            GBTextField(
                label: "YOUR NAME",
                placeholder: "e.g. COACH",
                text: $managerName,
                focused: $focused,
                field: .manager
            )

            // Team name
            GBTextField(
                label: "TEAM NAME",
                placeholder: "e.g. ROOKIE SQUAD",
                text: $teamName,
                focused: $focused,
                field: .team
            )

            Spacer()

            // Start button
            Button {
                startGame()
            } label: {
                Text("START JOURNEY ▶")
                    .font(.custom(GB.font, size: 16))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canStart ? Color.gbDark : Color.gbDarkest)
                    .overlay(
                        Rectangle().stroke(
                            canStart ? Color.gbLight : Color.gbDark,
                            lineWidth: 2
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canStart)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    var canStart: Bool {
        !teamName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !managerName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func startGame() {
        gameState.managerName = managerName.uppercased().trimmingCharacters(in: .whitespaces)
        gameState.playerTeam.name = teamName.uppercased().trimmingCharacters(in: .whitespaces)
        gameState.setFlag("intro_seen")
        gameState.screen = .overworld
    }
}

// MARK: - GB-styled text field
struct GBTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<TeamSetupView.ActiveField?>.Binding
    let field: TeamSetupView.ActiveField

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom(GB.font, size: 11))
                .foregroundColor(.gbLight)

            TextField(placeholder, text: $text)
                .font(.custom(GB.font, size: 15))
                .foregroundColor(.gbLightest)
                .accentColor(.gbLightest)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .focused(focused, equals: field)
                .padding(10)
                .background(Color.gbDarkest)
                .overlay(
                    Rectangle().stroke(
                        focused.wrappedValue == field ? Color.gbLightest : Color.gbDark,
                        lineWidth: 2
                    )
                )
        }
    }
}

// MARK: - NPC Portrait
struct NPCPortraitView: View {
    let type: String

    var color: Color {
        type == "mentor" ? .gbDark : Color(red: 0.25, green: 0.10, blue: 0.10)
    }

    var body: some View {
        ZStack {
            color
            VStack(spacing: 0) {
                Spacer()
                // Head
                ZStack {
                    Rectangle()
                        .fill(Color.gbLightest)
                        .frame(width: 56, height: 64)
                        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
                    VStack(spacing: 10) {
                        HStack(spacing: 14) {
                            Rectangle().fill(Color.gbDarkest).frame(width: 9, height: 9)
                            Rectangle().fill(Color.gbDarkest).frame(width: 9, height: 9)
                        }
                        Rectangle().fill(Color.gbDark).frame(width: 22, height: 4)
                    }
                    // Hat / hair detail for mentor
                    if type == "mentor" {
                        Rectangle()
                            .fill(Color.gbDark)
                            .frame(width: 60, height: 14)
                            .offset(y: -25)
                    }
                }
                // Body
                Rectangle()
                    .fill(color)
                    .frame(width: 70, height: 30)
                    .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1.5))
            }
        }
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
        .clipped()
    }
}

// MARK: - Typewriter text (SwiftUI version for setup screen)
struct TypewriterText: View {
    let text: String
    let key: Int
    @State private var displayed = ""

    var body: some View {
        Text(displayed)
            .onAppear { startTyping() }
            .onChange(of: key) { _, _ in
                displayed = ""
                startTyping()
            }
    }

    private func startTyping() {
        displayed = ""
        var delay = 0.0
        for char in text {
            let c = String(char)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayed += c
            }
            delay += 0.03
        }
    }
}
