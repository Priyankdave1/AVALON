//
//  GameScene.swift
//  Avalon
//
//  Created by Priyank Dave on 2025-06-07.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var game: Game!
    
    // UI Elements
    private var questBoard: SKNode?
    private var playerNodes: [SKNode] = []
    private var voteButtons: [SKSpriteNode] = []
    private var statusLabel: SKLabelNode?
    private var questRequirementLabel: SKLabelNode?
    private var teamVoteView: SKNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        setupGame()
    }
    
    private func setupGame() {
        setupQuestBoard()
        setupPlayers()
        setupVoteButtons()
        setupStatusLabels()
        setupTeamVoteView()
        updateUI()
    }
    
    private func setupQuestBoard() {
        questBoard = SKNode()
        guard let questBoard = questBoard else { return }
        questBoard.position = CGPoint(x: frame.midX, y: frame.height * 0.8)
        addChild(questBoard)
        
        // Add quest markers
        for i in 0..<5 {
            let questMarker = SKSpriteNode(color: .gray, size: CGSize(width: 50, height: 50))
            questMarker.position = CGPoint(x: CGFloat(i - 2) * 60, y: 0)
            questBoard.addChild(questMarker)
        }
    }
    
    private func setupPlayers() {
        let radius = frame.width * 0.35
        let center = CGPoint(x: frame.midX, y: frame.height * 0.4)
        
        for (index, player) in game.players.enumerated() {
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(game.players.count)
            let position = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            
            let playerNode = createPlayerNode(player: player, position: position)
            addChild(playerNode)
            playerNodes.append(playerNode)
        }
    }
    
    private func createPlayerNode(player: Player, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        let circle = SKShapeNode(circleOfRadius: 30)
        circle.fillColor = .blue
        circle.strokeColor = player.isLeader ? .yellow : .clear
        circle.lineWidth = 3
        container.addChild(circle)
        
        let nameLabel = SKLabelNode(fontNamed: "Avenir")
        nameLabel.text = player.name
        nameLabel.fontSize = 16
        nameLabel.position = CGPoint(x: 0, y: -40)
        container.addChild(nameLabel)
        
        container.name = player.id.uuidString
        return container
    }
    
    private func setupVoteButtons() {
        let approveButton = SKSpriteNode(color: .green, size: CGSize(width: 100, height: 50))
        approveButton.position = CGPoint(x: frame.midX - 60, y: frame.height * 0.15)
        approveButton.name = "approve"
        addChild(approveButton)
        
        let rejectButton = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 50))
        rejectButton.position = CGPoint(x: frame.midX + 60, y: frame.height * 0.15)
        rejectButton.name = "reject"
        addChild(rejectButton)
        
        voteButtons = [approveButton, rejectButton]
        toggleVoteButtons(visible: false)
    }
    
    private func setupStatusLabels() {
        statusLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        statusLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.9)
        statusLabel?.fontSize = 24
        if let statusLabel = statusLabel {
            addChild(statusLabel)
        }
        
        questRequirementLabel = SKLabelNode(fontNamed: "Avenir")
        questRequirementLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        questRequirementLabel?.fontSize = 18
        if let questRequirementLabel = questRequirementLabel {
            addChild(questRequirementLabel)
        }
    }
    
    private func setupTeamVoteView() {
        teamVoteView = SKNode()
        guard let teamVoteView = teamVoteView else { return }
        teamVoteView.position = CGPoint(x: frame.midX, y: frame.midY)
        teamVoteView.isHidden = true
        addChild(teamVoteView)
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 200))
        background.fillColor = .black
        background.strokeColor = .white
        teamVoteView.addChild(background)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Team Vote"
        titleLabel.fontSize = 24
        titleLabel.position = CGPoint(x: 0, y: 60)
        teamVoteView.addChild(titleLabel)
        
        // Approve Button
        let approveButton = SKSpriteNode(color: .green, size: CGSize(width: 120, height: 50))
        approveButton.position = CGPoint(x: -70, y: -20)
        approveButton.name = "teamApprove"
        
        let approveLabel = SKLabelNode(fontNamed: "Avenir")
        approveLabel.text = "Approve"
        approveLabel.fontSize = 20
        approveLabel.verticalAlignmentMode = .center
        approveButton.addChild(approveLabel)
        teamVoteView.addChild(approveButton)
        
        // Reject Button
        let rejectButton = SKSpriteNode(color: .red, size: CGSize(width: 120, height: 50))
        rejectButton.position = CGPoint(x: 70, y: -20)
        rejectButton.name = "teamReject"
        
        let rejectLabel = SKLabelNode(fontNamed: "Avenir")
        rejectLabel.text = "Reject"
        rejectLabel.fontSize = 20
        rejectLabel.verticalAlignmentMode = .center
        rejectButton.addChild(rejectLabel)
        teamVoteView.addChild(rejectButton)
    }
    
    private func updateUI() {
        // Update quest board
        for (index, node) in questBoard?.children.enumerated() ?? [].enumerated() {
            if let result = game.getQuestResult(at: index) {
                (node as? SKSpriteNode)?.color = result ? .green : .red
            }
        }
        
        // Update player nodes
        for node in playerNodes {
            if let playerId = UUID(uuidString: node.name ?? ""),
               let circle = node.children.first as? SKShapeNode {
                circle.strokeColor = game.getCurrentLeader().id == playerId ? .yellow : .clear
                circle.fillColor = game.selectedTeamMembers.contains(playerId) ? .purple : .blue
            }
        }
        
        // Update status and UI elements
        switch game.currentPhase {
        case .questSelection:
            statusLabel?.text = "\(game.getCurrentLeader().name) is selecting team members"
            if let requirement = game.getCurrentQuestRequirement() {
                questRequirementLabel?.text = "Select \(requirement) players for the quest"
            }
            toggleVoteButtons(visible: false)
            teamVoteView?.isHidden = true
            
        case .teamVoting:
            statusLabel?.text = "Vote as a group to approve or reject the team"
            questRequirementLabel?.text = "Selected team: " + game.players
                .filter { game.selectedTeamMembers.contains($0.id) }
                .map { $0.name }
                .joined(separator: ", ")
            toggleVoteButtons(visible: false)
            teamVoteView?.isHidden = false
            
        case .questVoting:
            statusLabel?.text = "Quest team members: Vote for success or failure"
            questRequirementLabel?.text = "Only selected team members should vote"
            toggleVoteButtons(visible: true)
            teamVoteView?.isHidden = true
            
        case .assassination:
            statusLabel?.text = "Assassin: Choose your target"
            questRequirementLabel?.text = "Click on a player to assassinate them"
            toggleVoteButtons(visible: false)
            teamVoteView?.isHidden = true
            
        case .gameOver:
            statusLabel?.text = "Game Over!"
            questRequirementLabel?.text = ""
            toggleVoteButtons(visible: false)
            teamVoteView?.isHidden = true
            
        default:
            break
        }
    }
    
    private func toggleVoteButtons(visible: Bool) {
        voteButtons.forEach { $0.isHidden = !visible }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            handleNodeTouched(node)
        }
    }
    
    private func handleNodeTouched(_ node: SKNode) {
        switch game.currentPhase {
        case .questSelection:
            if let playerId = UUID(uuidString: node.name ?? "") {
                if game.togglePlayerSelection(playerId) {
                    updateUI()
                }
            }
            
        case .teamVoting:
            if node.name == "teamApprove" {
                game.submitTeamVoteResult(approved: true)
                updateUI()
            } else if node.name == "teamReject" {
                game.submitTeamVoteResult(approved: false)
                updateUI()
            }
            
        case .questVoting:
            if let playerId = UUID(uuidString: node.name ?? ""),
               game.selectedTeamMembers.contains(playerId) {
                if node.name == "approve" {
                    game.submitQuestVote(playerId: playerId, succeeded: true)
                    updateUI()
                } else if node.name == "reject" {
                    game.submitQuestVote(playerId: playerId, succeeded: false)
                    updateUI()
                }
            }
            
        case .assassination:
            if let playerId = UUID(uuidString: node.name ?? "") {
                if game.assassinate(targetId: playerId) {
                    statusLabel?.text = "Evil wins! Merlin was found!"
                } else {
                    statusLabel?.text = "Good wins! Merlin remains hidden!"
                }
                updateUI()
            }
            
        default:
            break
        }
    }
}
