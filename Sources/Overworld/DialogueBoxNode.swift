import SpriteKit

class DialogueBoxNode: SKNode {
    private let background: SKShapeNode
    private let nameLabel: SKLabelNode
    private let textLabel: SKLabelNode
    private let arrow: SKShapeNode

    private var fullText: String = ""
    private var typedText: String = ""
    private var pendingCompletion: (() -> Void)? = nil

    var isTyping: Bool { typedText.count < fullText.count }
    var isVisible: Bool { !isHidden }
    var isWaitingForTap: Bool { !isTyping && !isHidden && pendingCompletion != nil }

    init(width: CGFloat, height: CGFloat = 100) {
        let rect = CGRect(x: -width / 2, y: 0, width: width, height: height)
        background = SKShapeNode(rect: rect, cornerRadius: 0)
        background.fillColor = .gbLightest
        background.strokeColor = .gbDarkest
        background.lineWidth = 3

        nameLabel = SKLabelNode(text: "")
        nameLabel.fontName = "Courier-Bold"
        nameLabel.fontSize = 11
        nameLabel.fontColor = .gbDarkest
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .top
        nameLabel.position = CGPoint(x: -width / 2 + 8, y: height - 8)

        textLabel = SKLabelNode(text: "")
        textLabel.fontName = "Courier"
        textLabel.fontSize = 11
        textLabel.fontColor = .gbDarkest
        textLabel.horizontalAlignmentMode = .left
        textLabel.verticalAlignmentMode = .top
        textLabel.numberOfLines = 4
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.preferredMaxLayoutWidth = width - 20
        textLabel.position = CGPoint(x: -width / 2 + 8, y: height - 26)

        // Down-arrow indicator
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 8, y: 0))
        path.addLine(to: CGPoint(x: 4, y: -7))
        path.closeSubpath()
        arrow = SKShapeNode(path: path)
        arrow.fillColor = .gbDarkest
        arrow.strokeColor = .clear
        arrow.position = CGPoint(x: width / 2 - 18, y: 12)
        arrow.isHidden = true

        super.init()
        addChild(background)
        addChild(nameLabel)
        addChild(textLabel)
        addChild(arrow)

        // Blink arrow
        arrow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.fadeIn(withDuration: 0.35)
        ])))
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show
    func show(text: String, speaker: String = "", completion: (() -> Void)? = nil) {
        self.isHidden = false
        self.fullText = text
        self.typedText = ""
        self.pendingCompletion = completion  // stored immediately so skipTyping() preserves it

        nameLabel.text = speaker.isEmpty ? "" : "[\(speaker.uppercased())]"
        textLabel.text = ""
        arrow.isHidden = true
        removeAction(forKey: "type")

        var actions: [SKAction] = []
        for char in text {
            let c = String(char)
            actions.append(SKAction.wait(forDuration: 0.035))
            actions.append(SKAction.run { [weak self] in
                self?.typedText += c
                self?.textLabel.text = self?.typedText
            })
        }
        actions.append(SKAction.run { [weak self] in
            self?.arrow.isHidden = false
            // pendingCompletion already set above — ready for tap/A press
        })
        run(SKAction.sequence(actions), withKey: "type")
    }

    /// Call when user taps while typing — skips to end
    func skipTyping() {
        removeAction(forKey: "type")
        typedText = fullText
        textLabel.text = fullText
        arrow.isHidden = false
        // pendingCompletion already set — just waiting for tap
    }

    /// Call when user taps/presses A after typing is done — advances dialogue
    func advance() {
        guard pendingCompletion != nil else { return }
        // If still typing, skip to end first
        if isTyping { skipTyping(); return }
        let c = pendingCompletion
        pendingCompletion = nil
        c?()
    }

    func hide() {
        removeAction(forKey: "type")
        isHidden = true
    }
}
