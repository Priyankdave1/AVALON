import SpriteKit

class RoleRevealScene: SKScene {
    private var game: Game
    private var roleLabel: SKLabelNode?
    private var infoLabel: SKLabelNode?
    private var showButton: SKSpriteNode?
    private var continueButton: SKSpriteNode?
    private var roleHidden = true
    private var isShowingRole = false
    
    init(game: Game, size: CGSize) {
        self.game = game
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupPreparationScreen()
    }
    
    private func setupPreparationScreen() {
        removeAllChildren()
        isShowingRole = false
        roleHidden = true
        
        guard let currentPlayer = game.currentPlayerViewingRole else { return }
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Get Ready!"
        titleLabel.fontSize = 36
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.8)
        addChild(titleLabel)
        
        // Player name
        let nameLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        nameLabel.text = "\(currentPlayer.name)'s Turn"
        nameLabel.fontSize = 28
        nameLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.6)
        addChild(nameLabel)
        
        // Instructions
        let instructionLabel = SKLabelNode(fontNamed: "Avenir")
        instructionLabel.text = "Make sure only"
        instructionLabel.fontSize = 22
        instructionLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.45)
        addChild(instructionLabel)
        
        let nameInstruction = SKLabelNode(fontNamed: "Avenir-Heavy")
        nameInstruction.text = currentPlayer.name
        nameInstruction.fontSize = 22
        nameInstruction.position = CGPoint(x: frame.midX, y: frame.height * 0.4)
        addChild(nameInstruction)
        
        let canSeeLabel = SKLabelNode(fontNamed: "Avenir")
        canSeeLabel.text = "can see the screen"
        canSeeLabel.fontSize = 22
        canSeeLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.35)
        addChild(canSeeLabel)
        
        // Show Role Button
        showButton = createButton(text: "Show My Role", position: CGPoint(x: frame.midX, y: frame.height * 0.2))
        if let showButton = showButton {
            showButton.name = "showRole"
            addChild(showButton)
        }
    }
    
    private func setupRoleScreen() {
        removeAllChildren()
        isShowingRole = true
        
        guard let currentPlayer = game.currentPlayerViewingRole else { return }
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "\(currentPlayer.name)'s Role"
        titleLabel.fontSize = 28
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        addChild(titleLabel)
        
        // Role Label
        roleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        roleLabel?.text = currentPlayer.role.description
        roleLabel?.fontSize = 32
        roleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.75)
        if let roleLabel = roleLabel {
            addChild(roleLabel)
        }
        
        // Information about who you can see
        infoLabel = SKLabelNode(fontNamed: "Avenir")
        infoLabel?.fontSize = 20
        infoLabel?.numberOfLines = 0
        infoLabel?.preferredMaxLayoutWidth = frame.width * 0.8
        infoLabel?.verticalAlignmentMode = .center
        infoLabel?.horizontalAlignmentMode = .center
        infoLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.5)
        updateInfoLabel()
        if let infoLabel = infoLabel {
            addChild(infoLabel)
        }
        
        // Hide/Show Button
        let hideButton = createButton(text: "Hide Role", position: CGPoint(x: frame.midX, y: frame.height * 0.25))
        hideButton.name = "hideRole"
        addChild(hideButton)
        
        // Continue Button
        continueButton = createButton(text: "Continue", position: CGPoint(x: frame.midX, y: frame.height * 0.15))
        if let continueButton = continueButton {
            continueButton.name = "continue"
            addChild(continueButton)
        }
    }
    
    private func createButton(text: String, position: CGPoint) -> SKSpriteNode {
        let button = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 50))
        button.position = position
        
        let label = SKLabelNode(fontNamed: "Avenir")
        label.text = text
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
    
    private func updateInfoLabel() {
        guard let currentPlayer = game.currentPlayerViewingRole else { return }
        
        let visiblePlayers = game.players.filter { player in
            return currentPlayer.canSee(player) && player.id != currentPlayer.id
        }
        
        var infoText = ""
        
        switch currentPlayer.role {
        case .merlin:
            infoText = "You can see evil players\n(except Mordred):"
        case .percival:
            infoText = "You can see Merlin and Morgana\n(but cannot tell them apart):"
        case .assassin, .morgana, .mordredServant, .mordred:
            infoText = "You can see other evil players:"
        case .oberon:
            infoText = "You are evil but cannot\nsee other evil players"
        case .loyalServant:
            infoText = "You are a loyal servant\nof Arthur"
        }
        
        if !visiblePlayers.isEmpty {
            infoText += "\n\n" + visiblePlayers.map { $0.name }.joined(separator: "\n")
        }
        
        infoLabel?.text = infoText
        infoLabel?.fontSize = 20  // Ensure font size is set
        infoLabel?.horizontalAlignmentMode = .center  // Center align the text
    }
    
    private func showTransitionScreen(completion: @escaping () -> Void) {
        removeAllChildren()
        
        let transitionLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        transitionLabel.text = "Pass the device"
        transitionLabel.fontSize = 40
        transitionLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.5)
        addChild(transitionLabel)
        
        // Wait for 1.5 seconds then execute the completion
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run {
                completion()
            }
        ]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "showRole" && !isShowingRole {
                setupRoleScreen()
            } else if node.name == "hideRole" && isShowingRole {
                roleLabel?.isHidden = !roleLabel!.isHidden
                infoLabel?.isHidden = !infoLabel!.isHidden
                (node.children.first as? SKLabelNode)?.text = roleLabel?.isHidden ?? false ? "Show Role" : "Hide Role"
            } else if node.name == "continue" && isShowingRole {
                showTransitionScreen {
                    if self.game.nextPlayerRoleReveal() {
                        // Show preparation screen for next player
                        self.setupPreparationScreen()
                    } else {
                        // Move to the game scene
                        let gameScene = GameScene(size: self.size)
                        gameScene.game = self.game
                        self.view?.presentScene(gameScene, transition: .crossFade(withDuration: 0.5))
                    }
                }
            }
        }
    }
} 