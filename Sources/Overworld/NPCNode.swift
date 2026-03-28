import SpriteKit

class NPCNode: SKNode {
    let npcId: String
    private let body: SKShapeNode
    private let shadow: SKShapeNode

    init(data: NPCData) {
        self.npcId = data.id

        let isMentor = data.color == "mentor"

        shadow = SKShapeNode(ellipseOf: CGSize(width: 26, height: 8))
        shadow.fillColor = SKColor(white: 0, alpha: 0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -16)

        body = SKShapeNode(rectOf: CGSize(width: 22, height: 30), cornerRadius: 3)
        body.fillColor = isMentor ? .gbDark : SKColor(red: 0.35, green: 0.10, blue: 0.10, alpha: 1)
        body.strokeColor = .gbDarkest
        body.lineWidth = 2

        super.init()

        addChild(shadow)
        addChild(body)

        // Eyes
        for ex in [-4.5, 4.5] as [CGFloat] {
            let eye = SKShapeNode(circleOfRadius: 2.5)
            eye.fillColor = .gbLightest
            eye.strokeColor = .clear
            eye.position = CGPoint(x: ex, y: 3)
            body.addChild(eye)
        }

        // Name tag
        let tag = SKLabelNode(text: isMentor ? "REEVES" : "AXIOM")
        tag.fontName = GB.font
        tag.fontSize = 7
        tag.fontColor = .gbLightest
        tag.verticalAlignmentMode = .bottom
        tag.position = CGPoint(x: 0, y: 18)
        addChild(tag)

        // Idle bob animation
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.6),
            SKAction.moveBy(x: 0, y: -3, duration: 0.6)
        ])
        body.run(SKAction.repeatForever(bob))
    }

    required init?(coder: NSCoder) { fatalError() }
}
