import SpriteKit
import UIKit

class SetupScene: SKScene, UITextFieldDelegate {
    private var game = Game()
    private var playerNameField: UITextField?
    private var startButton: SKSpriteNode?
    private var playerCountLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupUI()
        
        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        playerNameField?.resignFirstResponder()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Avalon"
        titleLabel.fontSize = 48
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        addChild(titleLabel)
        
        // Subtitle
        let subtitleLabel = SKLabelNode(fontNamed: "Avenir")
        subtitleLabel.text = "The Resistance"
        subtitleLabel.fontSize = 32
        subtitleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.78)
        addChild(subtitleLabel)
        
        // Player count label
        playerCountLabel = SKLabelNode(fontNamed: "Avenir")
        playerCountLabel?.text = "Players: 0/10"
        playerCountLabel?.fontSize = 24
        playerCountLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.7)
        if let playerCountLabel = playerCountLabel {
            addChild(playerCountLabel)
        }
        
        // Add player name text field
        setupTextField()
        
        // Add player button
        let addButton = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 50))
        addButton.position = CGPoint(x: frame.midX, y: frame.height * 0.4)
        addButton.name = "addPlayer"
        
        let addButtonLabel = SKLabelNode(fontNamed: "Avenir")
        addButtonLabel.text = "Add Player"
        addButtonLabel.fontSize = 20
        addButtonLabel.verticalAlignmentMode = .center
        addButton.addChild(addButtonLabel)
        
        addChild(addButton)
        
        // Start game button (initially hidden)
        startButton = SKSpriteNode(color: .green, size: CGSize(width: 200, height: 50))
        startButton?.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        startButton?.name = "startGame"
        startButton?.isHidden = true
        
        let startButtonLabel = SKLabelNode(fontNamed: "Avenir")
        startButtonLabel.text = "Start Game"
        startButtonLabel.fontSize = 20
        startButtonLabel.verticalAlignmentMode = .center
        startButton?.addChild(startButtonLabel)
        
        if let startButton = startButton {
            addChild(startButton)
        }
    }
    
    private func setupTextField() {
        playerNameField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        playerNameField?.backgroundColor = .white
        playerNameField?.textColor = .black
        playerNameField?.textAlignment = .center
        playerNameField?.placeholder = "Enter player name"
        playerNameField?.borderStyle = .roundedRect
        playerNameField?.autocorrectionType = .no
        playerNameField?.returnKeyType = .done
        playerNameField?.delegate = self
        
        if let playerNameField = playerNameField {
            playerNameField.center = CGPoint(x: frame.midX, y: frame.height * 0.5)
            view?.addSubview(playerNameField)
        }
    }
    
    override func willMove(from view: SKView) {
        view.gestureRecognizers?.removeAll()
        playerNameField?.removeFromSuperview()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "addPlayer" {
                addPlayer()
            } else if node.name == "startGame" {
                startGame()
            }
        }
    }
    
    private func addPlayer() {
        guard let name = playerNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return
        }
        
        if game.addPlayer(name: name) {
            playerNameField?.text = ""
            playerCountLabel?.text = "Players: \(game.players.count)/10"
            
            // Show start button if we have enough players
            startButton?.isHidden = game.players.count < 5
        }
    }
    
    private func startGame() {
        guard game.players.count >= 5 else { return }
        
        let roleSelectionScene = RoleSelectionScene(game: game, size: size)
        view?.presentScene(roleSelectionScene, transition: .crossFade(withDuration: 0.5))
    }
} 