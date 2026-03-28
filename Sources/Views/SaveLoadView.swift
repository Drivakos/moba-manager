import SwiftUI

enum SaveLoadMode {
    case load   // from title screen
    case save   // from in-game pause
}

struct SaveLoadView: View {
    @Environment(GameState.self) var gameState
    let mode: SaveLoadMode

    @State private var slots: [SaveSlot?] = Array(repeating: nil, count: SaveManager.slotCount)
    @State private var confirmDelete: Int? = nil
    @State private var savedFeedback: Int? = nil

    var title: String { mode == .load ? "LOAD GAME" : "SAVE GAME" }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(1...SaveManager.slotCount, id: \.self) { slot in
                            slotCard(slot: slot, data: slots[slot - 1])
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }

                backButton
            }

            // Delete confirmation overlay
            if let slot = confirmDelete {
                deleteConfirmOverlay(slot: slot)
            }
        }
        .onAppear { slots = SaveManager.allSlots() }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            Text(title)
                .font(.custom(GB.font, size: 16))
                .foregroundColor(.gbLightest)
        }
        .frame(height: 48)
    }

    // MARK: - Slot Card
    func slotCard(slot: Int, data: SaveSlot?) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Slot number
                Text("0\(slot)")
                    .font(.custom(GB.font, size: 18))
                    .foregroundColor(.gbLightest)
                    .frame(width: 32)

                if let d = data {
                    // Filled slot
                    VStack(alignment: .leading, spacing: 4) {
                        Text(d.teamName)
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(.gbLightest)
                        HStack(spacing: 10) {
                            Text(d.chapterLabel)
                            Text(d.recordLabel)
                            Text("\(d.rosterCount)/5 players")
                        }
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                        Text(d.formattedDate)
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                    }
                } else {
                    // Empty slot
                    Text("─── EMPTY ───")
                        .font(.custom(GB.fontMono, size: 12))
                        .foregroundColor(.gbDark)
                }

                Spacer()

                // Action button
                if savedFeedback == slot {
                    Text("SAVED ✓")
                        .font(.custom(GB.font, size: 11))
                        .foregroundColor(.gbLightest)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.gbDark)
                } else {
                    Button(action: { handleSlotTap(slot: slot, data: data) }) {
                        Text(actionLabel(slot: slot, data: data))
                            .font(.custom(GB.font, size: 11))
                            .foregroundColor(canAct(slot: slot, data: data) ? .gbDarkest : .gbDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(canAct(slot: slot, data: data) ? Color.gbLightest : Color.gbDarkest)
                            .overlay(Rectangle().stroke(
                                canAct(slot: slot, data: data) ? Color.gbLight : Color.gbDarkest,
                                lineWidth: 1
                            ))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAct(slot: slot, data: data))
                }

                // Delete (only for filled slots)
                if data != nil {
                    Button {
                        confirmDelete = slot
                    } label: {
                        Text("✕")
                            .font(.custom(GB.font, size: 12))
                            .foregroundColor(.gbDark)
                            .frame(width: 28, height: 28)
                            .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(data != nil ? Color.gbDark : Color.gbDarkest)
            .overlay(Rectangle().stroke(
                slot == SaveManager.lastUsedSlot ? Color.gbLightest : Color.gbDark,
                lineWidth: slot == SaveManager.lastUsedSlot ? 2 : 1
            ))
        }
    }

    // MARK: - Slot Action
    private func actionLabel(slot: Int, data: SaveSlot?) -> String {
        switch mode {
        case .load: return data != nil ? "LOAD ▶" : "──"
        case .save: return "SAVE"
        }
    }

    private func canAct(slot: Int, data: SaveSlot?) -> Bool {
        switch mode {
        case .load: return data != nil
        case .save: return true
        }
    }

    private func handleSlotTap(slot: Int, data: SaveSlot?) {
        switch mode {
        case .load:
            guard data != nil else { return }
            SaveManager.load(slot: slot, into: gameState)
        case .save:
            SaveManager.save(gameState: gameState, slot: slot)
            slots = SaveManager.allSlots()
            savedFeedback = slot
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                savedFeedback = nil
            }
        }
    }

    // MARK: - Delete Confirmation
    func deleteConfirmOverlay(slot: Int) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("DELETE SLOT 0\(slot)?")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.gbDark)

                Text("This cannot be undone.")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbLight)
                    .padding(10)
                    .background(Color.gbDarkest)

                HStack(spacing: 0) {
                    Button {
                        confirmDelete = nil
                    } label: {
                        Text("CANCEL")
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(.gbLight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gbDarkest)
                    }
                    .buttonStyle(.plain)

                    Divider().background(Color.gbDark).frame(width: 1)

                    Button {
                        SaveManager.delete(slot: slot)
                        slots = SaveManager.allSlots()
                        confirmDelete = nil
                    } label: {
                        Text("DELETE")
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(.gbLightest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gbDark)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 280)
            .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 2))
        }
    }

    // MARK: - Back
    var backButton: some View {
        Button {
            gameState.screen = mode == .load ? .title : .overworld
        } label: {
            Text("◀ BACK")
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbLightest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gbDark)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
