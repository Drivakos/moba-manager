import SpriteKit

class CharacterNode: SKNode {
    private let body: SKShapeNode
    private let eyeL: SKShapeNode
    private let eyeR: SKShapeNode
    private(set) var facing: Direction = .down

    init(color: SKColor, size: CGFloat = 26) {
        body = SKShapeNode(rectOf: CGSize(width: size * 0.72, height: size), cornerRadius: 3)
        body.fillColor = color
        body.strokeColor = .gbDarkest
        body.lineWidth = 2

        eyeL = SKShapeNode(circleOfRadius: 2.5)
        eyeL.fillColor = .gbDarkest
        eyeL.strokeColor = .clear

        eyeR = SKShapeNode(circleOfRadius: 2.5)
        eyeR.fillColor = .gbDarkest
        eyeR.strokeColor = .clear

        super.init()
        addChild(body)
        body.addChild(eyeL)
        body.addChild(eyeR)

        updateEyes()
    }

    required init?(coder: NSCoder) { fatalError() }

    func face(_ direction: Direction) {
        facing = direction
        updateEyes()
    }

    private func updateEyes() {
        switch facing {
        case .up:
            eyeL.position = CGPoint(x: -5, y: 7)
            eyeR.position = CGPoint(x: 5, y: 7)
        case .down:
            eyeL.position = CGPoint(x: -5, y: 3)
            eyeR.position = CGPoint(x: 5, y: 3)
        case .left:
            eyeL.position = CGPoint(x: -6, y: 3)
            eyeR.position = CGPoint(x: -1, y: 3)
        case .right:
            eyeL.position = CGPoint(x: 1, y: 3)
            eyeR.position = CGPoint(x: 6, y: 3)
        }
    }

    func playWalkBounce() {
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.07),
            SKAction.moveBy(x: 0, y: -4, duration: 0.07)
        ])
        body.run(bounce)
    }
}
