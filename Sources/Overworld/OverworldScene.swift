import SpriteKit

class OverworldScene: SKScene {

    // MARK: - Callbacks (set by OverworldContainerView)
    var onEnterArena: (() -> Void)?
    var onEnterHQ: (() -> Void)?

    // MARK: - Properties
    private weak var gameState: GameState?
    private let tileSize = GB.tileSize

    private let worldNode = SKNode()
    private var playerNode: CharacterNode!
    private var dialogueBox: DialogueBoxNode!
    private var hudNode: SKNode!

    private var isMoving = false
    private var isBlocked = false  // during dialogue / encounter

    // Multi-line story dialogue queue
    private var storyQueue: [StoryLine] = []
    private var storyCompletion: (() -> Void)? = nil

    // MARK: - Init
    init(size: CGSize, gameState: GameState) {
        self.gameState = gameState
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .gbDark
        addChild(worldNode)

        let cam = SKCameraNode()
        camera = cam
        addChild(cam)

        buildMap()
        buildPlayer()
        buildNPCs()
        buildDialogue()
        buildHUD()
        centerCamera(animated: false)

        // Show pending story lines from GameState (e.g. post-match chapter dialogue)
        if let gs = gameState, !gs.pendingStoryLines.isEmpty {
            let lines = gs.pendingStoryLines
            gs.pendingStoryLines = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.showStoryDialogue(lines: lines)
            }
        }
    }

    // MARK: - Map
    private func buildMap() {
        let rows = MapData.grid.count
        let cols = MapData.grid[0].count

        for row in 0..<rows {
            for col in 0..<cols {
                let type = MapData.tile(col: col, row: row)
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 1, height: tileSize - 1))
                tile.fillColor = type.skColor
                tile.strokeColor = type == .wall || type == .tree ? .gbDarkest : .gbDark
                tile.lineWidth = 0.5
                tile.position = worldPos(col: col, row: row)
                worldNode.addChild(tile)

                // Label for special tiles
                if let text = MapData.label(for: type) {
                    let lbl = SKLabelNode(text: text)
                    lbl.fontName = GB.font
                    lbl.fontSize = 7
                    lbl.fontColor = .gbLightest
                    lbl.verticalAlignmentMode = .center
                    lbl.position = worldPos(col: col, row: row)
                    lbl.zPosition = 1
                    worldNode.addChild(lbl)
                }
            }
        }
    }

    // MARK: - Player
    private func buildPlayer() {
        playerNode = CharacterNode(color: .gbDark)
        playerNode.zPosition = 10
        let pos = gameState?.playerPosition ?? TilePosition(col: 1, row: 1)
        playerNode.position = worldPos(col: pos.col, row: pos.row)
        worldNode.addChild(playerNode)
    }

    // MARK: - NPCs
    private func buildNPCs() {
        for npc in Story.npcs {
            let node = NPCNode(data: npc)
            node.position = worldPos(col: npc.col, row: npc.row)
            node.zPosition = 9
            worldNode.addChild(node)
        }
    }

    // MARK: - Story Dialogue (multi-line queue)
    func showStoryDialogue(lines: [StoryLine], completion: (() -> Void)? = nil) {
        guard !lines.isEmpty else {
            completion?()
            return
        }
        storyQueue = lines
        storyCompletion = completion
        showNextStoryLine()
    }

    private func showNextStoryLine() {
        guard !storyQueue.isEmpty else {
            isBlocked = false
            dialogueBox.hide()
            storyCompletion?()
            storyCompletion = nil
            return
        }
        let line = storyQueue.removeFirst()
        showDialogue(text: line.text, speaker: line.speaker) { [weak self] in
            self?.showNextStoryLine()
        }
    }

    // MARK: - Dialogue
    private func buildDialogue() {
        guard let cam = camera else { return }
        let w = size.width * 0.88
        dialogueBox = DialogueBoxNode(width: w, height: 100)
        dialogueBox.position = CGPoint(x: 0, y: -size.height / 2 + 116)
        dialogueBox.zPosition = 50
        dialogueBox.hide()
        cam.addChild(dialogueBox)
    }

    // MARK: - HUD
    private func buildHUD() {
        guard let cam = camera else { return }
        hudNode = SKNode()
        hudNode.zPosition = 40
        cam.addChild(hudNode)
        refreshHUD()
    }

    func refreshHUD() {
        hudNode.removeAllChildren()
        guard let gs = gameState else { return }

        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: 34))
        bar.fillColor = .gbDarkest
        bar.strokeColor = .clear
        bar.position = CGPoint(x: 0, y: size.height / 2 - 17)
        hudNode.addChild(bar)

        let teamName = gs.playerTeam.name.uppercased()
        let teamLbl = SKLabelNode(text: teamName)
        teamLbl.fontName = GB.font
        teamLbl.fontSize = 12
        teamLbl.fontColor = .gbLightest
        teamLbl.horizontalAlignmentMode = .left
        teamLbl.position = CGPoint(x: -size.width / 2 + 10, y: size.height / 2 - 23)
        hudNode.addChild(teamLbl)

        let fundsK = gs.funds / 1000
        let fundsR = (gs.funds % 1000) / 100
        let fundsStr = fundsR > 0 ? "$\(fundsK).\(fundsR)K" : "$\(fundsK)K"
        let rosterLbl = SKLabelNode(text: "\(gs.playerTeam.roster.count)/5  \(fundsStr)")
        rosterLbl.fontName = GB.font
        rosterLbl.fontSize = 11
        rosterLbl.fontColor = .gbLight
        rosterLbl.horizontalAlignmentMode = .right
        rosterLbl.position = CGPoint(x: size.width / 2 - 10, y: size.height / 2 - 23)
        hudNode.addChild(rosterLbl)
    }

    // MARK: - Move Player
    func movePlayer(direction: Direction) {
        guard !isMoving && !isBlocked else { return }

        playerNode.face(direction)

        let cur = gameState?.playerPosition ?? TilePosition(col: 1, row: 1)
        var next = cur
        switch direction {
        case .up:    next.row -= 1
        case .down:  next.row += 1
        case .left:  next.col -= 1
        case .right: next.col += 1
        }

        let tile = MapData.tile(col: next.col, row: next.row)

        // Walls / trees
        guard tile != .wall && tile != .tree else { return }

        // Special tiles — block movement, show dialogue
        if tile == .hq || tile == .arena {
            if let msg = MapData.entryDialogue(tile: tile, gameState: gameState!) {
                showDialogue(text: msg, speaker: tile == .hq ? "HQ" : "ARENA") { [weak self] in
                    self?.isBlocked = false
                    self?.dialogueBox.hide()
                    if tile == .arena {
                        self?.onEnterArena?()
                    } else {
                        // HQ → open training
                        self?.onEnterHQ?()
                    }
                }
            }
            return
        }

        // NPC collision — player bumps into NPC tile
        if let npc = Story.npcs.first(where: { $0.col == next.col && $0.row == next.row }) {
            let lines: [StoryLine]
            if npc.id == "rival" && !(gameState?.hasFlag("rival_met") ?? false) {
                gameState?.setFlag("rival_met")
                lines = Story.rivalIntro
            } else {
                lines = npc.defaultDialogue
            }
            showStoryDialogue(lines: lines)
            return
        }

        // Commit move
        gameState?.playerPosition = next
        isMoving = true
        playerNode.face(direction)
        playerNode.playWalkBounce()

        let dest = worldPos(col: next.col, row: next.row)
        let move = SKAction.move(to: dest, duration: 0.13)
        move.timingMode = .easeInEaseOut

        playerNode.run(move) { [weak self] in
            self?.isMoving = false
        }

        centerCamera(animated: true)
    }

    // MARK: - Button Handlers
    func handleAButton() {
        // A = yes / confirm — skip typing or advance to next line
        guard isBlocked, dialogueBox.isVisible else { return }
        dialogueBox.advance()
    }

    func handleBButton() {
        // B = no / cancel — also advances (dismiss)
        guard isBlocked, dialogueBox.isVisible else { return }
        dialogueBox.advance()
    }

    // MARK: - Public unblock (called when encounter/modal is dismissed)
    func unblock() {
        isBlocked = false
        dialogueBox.hide()
    }

    // MARK: - Dialogue Helper
    private func showDialogue(text: String, speaker: String, completion: @escaping () -> Void) {
        isBlocked = true
        dialogueBox.show(text: text, speaker: speaker, completion: completion)
    }

    // MARK: - Touch — tap screen also advances dialogue (same as A button)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isBlocked, dialogueBox.isVisible else { return }
        dialogueBox.advance()
    }

    // MARK: - Camera
    private func centerCamera(animated: Bool) {
        guard let cam = camera, let pos = gameState?.playerPosition else { return }
        let dest = worldPos(col: pos.col, row: pos.row)
        if animated {
            cam.run(SKAction.move(to: dest, duration: 0.13))
        } else {
            cam.position = dest
        }
    }

    // MARK: - Coordinate Helper
    private func worldPos(col: Int, row: Int) -> CGPoint {
        CGPoint(
            x: CGFloat(col) * tileSize + tileSize / 2,
            y: -CGFloat(row) * tileSize - tileSize / 2
        )
    }
}
