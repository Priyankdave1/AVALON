import SpriteKit

class RoleSelectionScene: SKScene {
    private var game: Game
    private var roleToggles: [Role: Bool] = [
        .merlin: true,      // Merlin is mandatory
        .assassin: true,    // Assassin is mandatory
        .percival: false,
        .morgana: false,
        .mordred: false,
        .oberon: false
    ]
    private var roleButtons: [Role: SKSpriteNode] = [:]
    
    init(game: Game, size: CGSize) {
        self.game = game
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Select Special Roles"
        titleLabel.fontSize = 36
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        addChild(titleLabel)
        
        // Instructions
        let instructionsLabel = SKLabelNode(fontNamed: "Avenir")
        instructionsLabel.text = "Choose which special roles to include"
        instructionsLabel.fontSize = 24
        instructionsLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.75)
        addChild(instructionsLabel)
        
        // Required roles info
        let requiredLabel = SKLabelNode(fontNamed: "Avenir")
        requiredLabel.text = "(Merlin and Assassin are required)"
        requiredLabel.fontSize = 18
        requiredLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.7)
        addChild(requiredLabel)
        
        // Role toggle buttons
        setupRoleButtons()
        
        // Start button
        let startButton = SKSpriteNode(color: .green, size: CGSize(width: 200, height: 50))
        startButton.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        startButton.name = "startGame"
        
        let startLabel = SKLabelNode(fontNamed: "Avenir")
        startLabel.text = "Start Game"
        startLabel.fontSize = 20
        startLabel.verticalAlignmentMode = .center
        startButton.addChild(startLabel)
        
        addChild(startButton)
    }
    
    private func setupRoleButtons() {
        let buttonSize = CGSize(width: 180, height: 40)
        let spacing: CGFloat = 50
        let startY = frame.height * 0.6
        
        // Filter out mandatory roles
        let optionalRoles: [Role] = [.percival, .morgana, .mordred, .oberon]
        
        for (index, role) in optionalRoles.enumerated() {
            let button = SKSpriteNode(color: roleToggles[role] ?? false ? .blue : .gray, size: buttonSize)
            button.position = CGPoint(x: frame.midX, y: startY - CGFloat(index) * spacing)
            button.name = "toggle_\(role)"
            
            let label = SKLabelNode(fontNamed: "Avenir")
            label.text = role.description
            label.fontSize = 18
            label.verticalAlignmentMode = .center
            button.addChild(label)
            
            roleButtons[role] = button
            addChild(button)
        }
    }
    
    private func updateButtonColor(for role: Role) {
        if let button = roleButtons[role] {
            button.color = roleToggles[role] ?? false ? .blue : .gray
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if let name = node.name {
                if name == "startGame" {
                    startGame()
                } else if name.starts(with: "toggle_") {
                    let roleString = String(name.dropFirst("toggle_".count))
                    if let role = Role.from(string: roleString) {
                        roleToggles[role] = !(roleToggles[role] ?? false)
                        updateButtonColor(for: role)
                    }
                }
            }
        }
    }
    
    private func startGame() {
        game.setSelectedRoles(roleToggles)
        game.assignRoles()
        game.startRoleReveal()
        
        let roleRevealScene = RoleRevealScene(game: game, size: size)
        view?.presentScene(roleRevealScene, transition: .crossFade(withDuration: 0.5))
    }
} 