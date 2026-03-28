import SwiftUI

// MARK: - D-Pad + Action Buttons overlay
struct GameControlsView: View {
    let onDirection: (Direction) -> Void
    let onAButton: () -> Void
    let onBButton: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            DPadView(onDirection: onDirection)
            Spacer()
            ActionButtonsView(onA: onAButton, onB: onBButton)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}

// MARK: - D-Pad
struct DPadView: View {
    let onDirection: (Direction) -> Void

    var body: some View {
        ZStack {
            // Center cross background
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gbDarkest)
                .frame(width: 42, height: 114)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gbDarkest)
                .frame(width: 114, height: 42)

            // Center circle
            Circle()
                .fill(Color.gbDark)
                .frame(width: 28, height: 28)

            // Buttons
            VStack(spacing: 0) {
                DPadButton(symbol: "arrowtriangle.up.fill")   { onDirection(.up) }
                    .frame(width: 38, height: 38)
                Spacer().frame(height: 2)
                HStack(spacing: 0) {
                    DPadButton(symbol: "arrowtriangle.left.fill")  { onDirection(.left) }
                        .frame(width: 38, height: 38)
                    Spacer().frame(width: 40)
                    DPadButton(symbol: "arrowtriangle.right.fill") { onDirection(.right) }
                        .frame(width: 38, height: 38)
                }
                Spacer().frame(height: 2)
                DPadButton(symbol: "arrowtriangle.down.fill")  { onDirection(.down) }
                    .frame(width: 38, height: 38)
            }
        }
        .frame(width: 118, height: 118)
    }
}

struct DPadButton: View {
    let symbol: String
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {}) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(pressed ? Color.gbLightest : Color.gbLight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        pressed = true
                        action()
                    }
                }
                .onEnded { _ in pressed = false }
        )
    }
}

// MARK: - Action Buttons (A / B)
struct ActionButtonsView: View {
    let onA: () -> Void
    let onB: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            GBActionButton(label: "A", color: .gbDark, action: onA)
            GBActionButton(label: "B", color: .gbDarkest, action: onB)
        }
    }
}

struct GBActionButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 16))
                .foregroundColor(.gbLightest)
                .frame(width: 48, height: 48)
                .background(Circle().fill(pressed ? color.opacity(0.6) : color))
                .overlay(Circle().stroke(Color.gbLightest, lineWidth: 2))
                .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
