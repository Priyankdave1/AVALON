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
    private var statusLabel: SKLabelNode?
    private var questRequirementLabel: SKLabelNode?
    private var teamVoteView: SKNode?
    private var playerCheckboxes: [(node: SKNode, isSelected: Bool)] = []
    private var selectTeamButton: SKSpriteNode?
    private var teamSizeLabel: SKLabelNode?
    private var voteButtons: [SKSpriteNode] = []
    private var teamSelectionNodes: [SKNode] = []
    private var currentVotingPlayerIndex: Int = 0
    private var currentRevealIndex: Int = 0  // Add tracking for role reveal
    private var preVoteView: SKNode?
    private var questResultView: SKNode?
    private var assassinationView: SKNode?  // New UI element for assassination phase
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupGame()
    }
    
    private func setupGame() {
        currentRevealIndex = 0  // Initialize reveal index
        setupQuestBoard()
        setupStatusLabels()
        setupTeamSelectionUI()
        setupTeamVoteView()
        setupVoteButtons()
        setupPreVoteView()
        setupQuestResultView()
        setupAssassinationView()  // Add setup for assassination view
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
    
    private func setupStatusLabels() {
        statusLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        statusLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.9)
        statusLabel?.fontSize = 24
        statusLabel?.numberOfLines = 2  // Allow multiple lines
        statusLabel?.verticalAlignmentMode = .center  // Center align for multiple lines
        if let statusLabel = statusLabel {
            addChild(statusLabel)
        }
        
        questRequirementLabel = SKLabelNode(fontNamed: "Avenir")
        questRequirementLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        questRequirementLabel?.fontSize = 18
        questRequirementLabel?.numberOfLines = 2  // Allow multiple lines
        if let questRequirementLabel = questRequirementLabel {
            addChild(questRequirementLabel)
        }
    }
    
    private func setupTeamSelectionUI() {
        // Create a container node for all team selection UI elements
        let container = SKNode()
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Select Your Team"
        titleLabel.fontSize = 32
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.8)
        container.addChild(titleLabel)
        
        // Team size info
        teamSizeLabel = SKLabelNode(fontNamed: "Avenir")
        if let requirement = game.getCurrentQuestRequirement() {
            teamSizeLabel?.text = "Select \(requirement) players"
        }
        teamSizeLabel?.fontSize = 24
        teamSizeLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.73)
        if let teamSizeLabel = teamSizeLabel {
            container.addChild(teamSizeLabel)
        }
        
        // Create two columns of players with checkboxes
        let startY = frame.height * 0.65
        let spacing: CGFloat = 45
        let leftColumnX = frame.midX - 150  // Left column
        let rightColumnX = frame.midX + 50   // Right column
        
        let usesTwoColumns = game.players.count > 5
        let playersPerColumn = usesTwoColumns ? (game.players.count + 1) / 2 : game.players.count
        
        for (index, player) in game.players.enumerated() {
            let playerContainer = SKNode()
            
            // Calculate position based on whether we're using two columns
            if usesTwoColumns {
                let column = index / playersPerColumn  // 0 for left column, 1 for right column
                let rowIndex = index % playersPerColumn
                let xPos = column == 0 ? leftColumnX : rightColumnX
                playerContainer.position = CGPoint(x: xPos, y: startY - CGFloat(rowIndex) * spacing)
            } else {
                // Single column layout for 5 or fewer players
                playerContainer.position = CGPoint(x: frame.midX - 100, y: startY - CGFloat(index) * spacing)
            }
            
            // Checkbox
            let checkbox = SKShapeNode(rectOf: CGSize(width: 30, height: 30))
            checkbox.fillColor = .clear
            checkbox.strokeColor = .white
            checkbox.lineWidth = 2
            checkbox.position = CGPoint(x: 0, y: 0)
            playerContainer.addChild(checkbox)
            
            // Player name - truncated to 3 characters
            let nameLabel = SKLabelNode(fontNamed: "Avenir")
            let truncatedName = String(player.name.prefix(3))
            nameLabel.text = truncatedName
            nameLabel.fontSize = 20
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: 50, y: -8)
            playerContainer.addChild(nameLabel)
            
            // Leader indicator if player is leader
            if game.getCurrentLeader().id == player.id {
                let crownLabel = SKLabelNode(text: "👑")
                crownLabel.fontSize = 20
                crownLabel.position = CGPoint(x: -50, y: -8)
                playerContainer.addChild(crownLabel)
            }
            
            playerContainer.name = "checkbox_\(index)"
            container.addChild(playerContainer)
            playerCheckboxes.append((playerContainer, false))
        }
        
        // Select Team Button - positioned at the bottom with more space
        selectTeamButton = createButton(text: "Select Team", position: CGPoint(x: frame.midX, y: frame.height * 0.2))
        if let selectTeamButton = selectTeamButton {
            selectTeamButton.name = "selectTeam"
            container.addChild(selectTeamButton)
        }
        
        container.name = "teamSelectionContainer"
        addChild(container)
        container.isHidden = true
    }
    
    private func setupVoteButtons() {
        let approveButton = SKSpriteNode(color: .green, size: CGSize(width: 100, height: 50))
        approveButton.position = CGPoint(x: frame.midX - 60, y: frame.height * 0.15)
        approveButton.name = "approve"
        
        let approveLabel = SKLabelNode(fontNamed: "Avenir")
        approveLabel.text = "Success"
        approveLabel.fontSize = 20
        approveLabel.verticalAlignmentMode = .center
        approveButton.addChild(approveLabel)
        addChild(approveButton)
        
        let rejectButton = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 50))
        rejectButton.position = CGPoint(x: frame.midX + 60, y: frame.height * 0.15)
        rejectButton.name = "reject"
        
        let rejectLabel = SKLabelNode(fontNamed: "Avenir")
        rejectLabel.text = "Fail"
        rejectLabel.fontSize = 20
        rejectLabel.verticalAlignmentMode = .center
        rejectButton.addChild(rejectLabel)
        addChild(rejectButton)
        
        voteButtons = [approveButton, rejectButton]
        toggleVoteButtons(visible: false)
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
    
    private func resetTeamSelection() {
        // Clear all checkboxes
        playerCheckboxes.indices.forEach { index in
            let (container, _) = playerCheckboxes[index]
            // Remove any existing checkmark
            container.enumerateChildNodes(withName: "checkmark") { node, _ in
                node.removeFromParent()
            }
            // Reset the selection state
            playerCheckboxes[index] = (container, false)
        }
        updateSelectTeamButton()
    }
    
    private func toggleCheckbox(at index: Int) {
        guard index < playerCheckboxes.count,
              game.currentPhase == .questSelection else { return }
        
        let (container, isSelected) = playerCheckboxes[index]
        
        // Check if we can select more players
        if !isSelected {
            let currentlySelected = playerCheckboxes.filter { tuple in tuple.isSelected }.count
            guard let requirement = game.getCurrentQuestRequirement(),
                  currentlySelected < requirement else { return }
        }
        
        // Remove existing checkmark if present
        container.enumerateChildNodes(withName: "checkmark") { node, _ in
            node.removeFromParent()
        }
        
        // Toggle selection
        let newIsSelected = !isSelected
        if newIsSelected {
            // Add checkmark
            let checkmark = SKLabelNode(text: "✓")
            checkmark.name = "checkmark"
            checkmark.fontSize = 24
            checkmark.position = CGPoint(x: 0, y: -8)
            container.addChild(checkmark)  // Add directly to container, not to first child
        }
        
        // Update the selection state in playerCheckboxes
        playerCheckboxes[index] = (container, newIsSelected)
        updateSelectTeamButton()
    }
    
    private func handleTeamSelection() {
        let selectedPlayers = playerCheckboxes.enumerated()
            .filter { _, tuple in tuple.isSelected }
            .map { index, _ in game.players[index] }
        
        if let requirement = game.getCurrentQuestRequirement(),
           selectedPlayers.count == requirement {
            // Clear any existing team members first
            var allClearSuccessful = true
            for memberId in game.selectedTeamMembers {
                if !game.togglePlayerSelection(memberId) {
                    allClearSuccessful = false
                    break
                }
            }
            
            if !allClearSuccessful {
                resetTeamSelection()
                return
            }
            
            // Add new team members
            var allSelectionsSuccessful = true
            for player in selectedPlayers {
                if !game.togglePlayerSelection(player.id) {
                    allSelectionsSuccessful = false
                    break
                }
            }
            
            if allSelectionsSuccessful {
                if game.submitTeam() {
                    updateUI()
                } else {
                    // If team submission failed, reset selections
                    resetTeamSelection()
                }
            } else {
                // If any selection failed, reset everything
                resetTeamSelection()
            }
        }
    }
    
    private func updateSelectTeamButton() {
        let selectedCount = playerCheckboxes.filter { tuple in tuple.isSelected }.count
        if let requirement = game.getCurrentQuestRequirement() {
            selectTeamButton?.color = selectedCount == requirement ? .blue : .gray
        }
    }
    
    private func updateTeamSelectionUI() {
        // Remove old team selection UI if it exists
        let oldContainer = childNode(withName: "teamSelectionContainer")
        oldContainer?.removeFromParent()
        playerCheckboxes.removeAll()
        
        // Create a container node for all team selection UI elements
        let container = SKNode()
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Select Your Team"
        titleLabel.fontSize = 36
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.7)
        container.addChild(titleLabel)
        
        // Team size info
        teamSizeLabel = SKLabelNode(fontNamed: "Avenir")
        if let requirement = game.getCurrentQuestRequirement() {
            teamSizeLabel?.text = "Select \(requirement) players"
        }
        teamSizeLabel?.fontSize = 24
        teamSizeLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.65)
        if let teamSizeLabel = teamSizeLabel {
            container.addChild(teamSizeLabel)
        }
        
        // Create two columns of players with checkboxes
        let startY = frame.height * 0.55
        let spacing: CGFloat = 45
        
        // Further adjusted column positions
        let leftColumnX = frame.midX - 100
        let rightColumnX = frame.midX + 40
        
        let usesTwoColumns = game.players.count > 5
        let playersPerColumn = usesTwoColumns ? (game.players.count + 1) / 2 : game.players.count
        
        for (index, player) in game.players.enumerated() {
            let playerContainer = SKNode()
            
            // Calculate position based on whether we're using two columns
            if usesTwoColumns {
                let column = index / playersPerColumn  // 0 for left column, 1 for right column
                let rowIndex = index % playersPerColumn
                let xPos = column == 0 ? leftColumnX : rightColumnX
                playerContainer.position = CGPoint(x: xPos, y: startY - CGFloat(rowIndex) * spacing)
            } else {
                // Single column layout for 5 or fewer players
                playerContainer.position = CGPoint(x: frame.midX - 100, y: startY - CGFloat(index) * spacing)
            }
            
            // Leader indicator - moved before checkbox to adjust overall positioning
            if game.getCurrentLeader().id == player.id {
                let crownLabel = SKLabelNode(text: "👑")
                crownLabel.fontSize = 18
                crownLabel.position = CGPoint(x: -30, y: -8)
                playerContainer.addChild(crownLabel)
            }
            
            // Checkbox
            let checkbox = SKShapeNode(rectOf: CGSize(width: 25, height: 25))
            checkbox.fillColor = .clear
            checkbox.strokeColor = .white
            checkbox.lineWidth = 2
            checkbox.position = CGPoint(x: 0, y: 0)
            playerContainer.addChild(checkbox)
            
            // Player name - truncated to 3 characters
            let nameLabel = SKLabelNode(fontNamed: "Avenir")
            let truncatedName = String(player.name.prefix(3))
            nameLabel.text = truncatedName
            nameLabel.fontSize = 20
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: 30, y: -8)
            playerContainer.addChild(nameLabel)
            
            playerContainer.name = "checkbox_\(index)"
            container.addChild(playerContainer)
            playerCheckboxes.append((playerContainer, false))
        }
        
        // Select Team Button
        selectTeamButton = createButton(text: "Select Team", position: CGPoint(x: frame.midX, y: frame.height * 0.15))
        if let selectTeamButton = selectTeamButton {
            selectTeamButton.name = "selectTeam"
            container.addChild(selectTeamButton)
        }
        
        container.name = "teamSelectionContainer"
        addChild(container)
        container.isHidden = true // Start hidden, will be shown in updateUI when needed
    }
    
    private func setupPreVoteView() {
        preVoteView = SKNode()
        guard let preVoteView = preVoteView else { return }
        preVoteView.position = CGPoint(x: frame.midX, y: frame.midY)
        preVoteView.isHidden = true
        addChild(preVoteView)
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 200))
        background.fillColor = .black
        background.strokeColor = .white
        preVoteView.addChild(background)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = "Next to Vote"
        titleLabel.fontSize = 24
        titleLabel.position = CGPoint(x: 0, y: 60)
        preVoteView.addChild(titleLabel)
        
        // Player Name (will be updated dynamically)
        let playerLabel = SKLabelNode(fontNamed: "Avenir")
        playerLabel.name = "playerNameLabel"
        playerLabel.fontSize = 28
        playerLabel.position = CGPoint(x: 0, y: 0)
        preVoteView.addChild(playerLabel)
        
        // Ready Button
        let readyButton = SKSpriteNode(color: .blue, size: CGSize(width: 120, height: 50))
        readyButton.position = CGPoint(x: 0, y: -50)
        readyButton.name = "readyToVote"
        
        let readyLabel = SKLabelNode(fontNamed: "Avenir")
        readyLabel.text = "Ready"
        readyLabel.fontSize = 20
        readyLabel.verticalAlignmentMode = .center
        readyButton.addChild(readyLabel)
        preVoteView.addChild(readyButton)
    }

    private func showVotingScreen(for player: Player) {
        // Hide pre-vote view and show voting buttons
        preVoteView?.isHidden = true
        
        // Update status for current voter
        statusLabel?.text = "\(player.name)'s Vote"
        questRequirementLabel?.text = "Choose your vote carefully"
        
        // Show/hide fail button based on role
        let canFail = player.role.isEvil // Evil players can fail quests
        voteButtons.forEach { button in
            button.isHidden = false
            if button.name == "reject" {
                button.isHidden = !canFail
            }
        }
    }

    private func showNextVoter() {
        // Get the current voter based on index
        let teamMembers = game.players.filter { game.selectedTeamMembers.contains($0.id) }
        guard currentVotingPlayerIndex < teamMembers.count else {
            // No more voters, the Game class will automatically handle phase transition
            // after the last vote is submitted
            updateUI()
            return
        }
        
        let currentVoter = teamMembers[currentVotingPlayerIndex]
        
        // Update pre-vote view with next player's name
        if let playerLabel = preVoteView?.childNode(withName: "playerNameLabel") as? SKLabelNode {
            playerLabel.text = currentVoter.name
        }
        
        // Show pre-vote view, hide voting buttons
        preVoteView?.isHidden = false
        toggleVoteButtons(visible: false)
        
        // Hide team selection UI if it's still visible
        childNode(withName: "teamSelectionContainer")?.isHidden = true
    }
    
    private func setupQuestResultView() {
        questResultView = SKNode()
        guard let questResultView = questResultView else { return }
        questResultView.position = CGPoint(x: frame.midX, y: frame.midY)
        questResultView.isHidden = true
        addChild(questResultView)
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 300))  // Made taller for continue button
        background.fillColor = .black
        background.strokeColor = .white
        questResultView.addChild(background)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.name = "resultTitle"
        titleLabel.fontSize = 28
        titleLabel.position = CGPoint(x: 0, y: 100)
        questResultView.addChild(titleLabel)
        
        // Success votes
        let successLabel = SKLabelNode(fontNamed: "Avenir")
        successLabel.name = "successCount"
        successLabel.fontSize = 24
        successLabel.position = CGPoint(x: 0, y: 40)
        questResultView.addChild(successLabel)
        
        // Fail votes
        let failLabel = SKLabelNode(fontNamed: "Avenir")
        failLabel.name = "failCount"
        failLabel.fontSize = 24
        failLabel.position = CGPoint(x: 0, y: 0)
        questResultView.addChild(failLabel)
        
        // Required fails
        let requiredFailsLabel = SKLabelNode(fontNamed: "Avenir")
        requiredFailsLabel.name = "requiredFails"
        requiredFailsLabel.fontSize = 20
        requiredFailsLabel.position = CGPoint(x: 0, y: -40)
        questResultView.addChild(requiredFailsLabel)
        
        // Continue Button
        let continueButton = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 50))
        continueButton.position = CGPoint(x: 0, y: -100)
        continueButton.name = "continueButton"
        
        let continueLabel = SKLabelNode(fontNamed: "Avenir")
        continueLabel.text = "Continue"
        continueLabel.fontSize = 20
        continueLabel.verticalAlignmentMode = .center
        continueButton.addChild(continueLabel)
        
        questResultView.addChild(continueButton)
    }

    private func updateQuestResultView() {
        guard let questResultView = questResultView,
              let voteCounts = game.getQuestVoteCounts() else { return }
        
        let questNumber = game.getCurrentQuestNumber()
        let needsTwoFails = game.currentQuestRequiresTwoFails()
        
        if let titleLabel = questResultView.childNode(withName: "resultTitle") as? SKLabelNode {
            let succeeded = game.questResults.last ?? false
            titleLabel.text = "Quest \(questNumber) \(succeeded ? "Succeeded!" : "Failed!")"
            titleLabel.fontColor = succeeded ? .green : .red
        }
        
        if let successLabel = questResultView.childNode(withName: "successCount") as? SKLabelNode {
            successLabel.text = "Success Votes: \(voteCounts.success)"
            successLabel.fontColor = .green
        }
        
        if let failLabel = questResultView.childNode(withName: "failCount") as? SKLabelNode {
            failLabel.text = "Fail Votes: \(voteCounts.fail)"
            failLabel.fontColor = .red
        }
        
        if let requiredFailsLabel = questResultView.childNode(withName: "requiredFails") as? SKLabelNode {
            let required = needsTwoFails ? 2 : 1
            requiredFailsLabel.text = "Required Fails: \(required)"
            requiredFailsLabel.fontColor = .white
        }
        
        questResultView.isHidden = false
    }

    private func setupAssassinationView() {
        assassinationView = SKNode()
        guard let assassinationView = assassinationView else { return }
        assassinationView.position = CGPoint(x: frame.midX, y: frame.midY)
        assassinationView.isHidden = true
        addChild(assassinationView)
        
        // Instructions only
        let instructionsLabel = SKLabelNode(fontNamed: "Avenir")
        instructionsLabel.text = "Choose who you think is Merlin"
        instructionsLabel.fontSize = 20
        instructionsLabel.position = CGPoint(x: 0, y: frame.height * 0.25)
        assassinationView.addChild(instructionsLabel)
        
        // Create player selection buttons in a grid layout
        let startY = frame.height * 0.15  // Adjusted starting position
        let verticalSpacing: CGFloat = 40  // Reduced spacing
        let horizontalSpacing: CGFloat = 90  // Reduced spacing
        let buttonSize = CGSize(width: 80, height: 30)  // Smaller buttons
        
        let maxButtonsPerRow = 3  // Maximum 3 buttons per row
        var currentRow = 0
        var currentCol = 0
        
        for player in game.players {
            // Skip if player is the Assassin
            if player.role == .assassin { continue }
            
            let buttonContainer = SKNode()
            
            // Calculate position in grid
            let xPos = CGFloat(currentCol - (min(game.players.count - 1, maxButtonsPerRow - 1)) / 2) * horizontalSpacing
            let yPos = startY - CGFloat(currentRow) * verticalSpacing
            buttonContainer.position = CGPoint(x: xPos, y: yPos)
            
            // Create button background
            let button = SKShapeNode(rectOf: buttonSize)
            button.fillColor = .blue
            button.strokeColor = .white
            button.lineWidth = 1
            button.name = "assassinate_\(player.id)"
            buttonContainer.addChild(button)
            
            // Add player name (first 3 letters)
            let nameLabel = SKLabelNode(fontNamed: "Avenir")
            let truncatedName = String(player.name.prefix(3))
            nameLabel.text = truncatedName
            nameLabel.fontSize = 16  // Smaller font
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: 0, y: 0)
            button.addChild(nameLabel)
            
            assassinationView.addChild(buttonContainer)
            
            // Update grid position
            currentCol += 1
            if currentCol >= maxButtonsPerRow {
                currentCol = 0
                currentRow += 1
            }
        }
        
        // Add Restart and New Game buttons
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 40
        let buttonSpacing: CGFloat = 20
        
        // Restart Game button (same players)
        let restartButton = SKSpriteNode(color: .blue, size: CGSize(width: buttonWidth, height: buttonHeight))
        restartButton.position = CGPoint(x: -buttonWidth/2 - buttonSpacing/2, y: -frame.height * 0.2)
        restartButton.name = "restartGame"
        
        let restartLabel = SKLabelNode(fontNamed: "Avenir")
        restartLabel.text = "Restart Game"
        restartLabel.fontSize = 18
        restartLabel.verticalAlignmentMode = .center
        restartButton.addChild(restartLabel)
        
        assassinationView.addChild(restartButton)
        
        // New Game button (new players)
        let newGameButton = SKSpriteNode(color: .green, size: CGSize(width: buttonWidth, height: buttonHeight))
        newGameButton.position = CGPoint(x: buttonWidth/2 + buttonSpacing/2, y: -frame.height * 0.2)
        newGameButton.name = "newGame"
        
        let newGameLabel = SKLabelNode(fontNamed: "Avenir")
        newGameLabel.text = "New Players"
        newGameLabel.fontSize = 18
        newGameLabel.verticalAlignmentMode = .center
        newGameButton.addChild(newGameLabel)
        
        assassinationView.addChild(newGameButton)
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
                resetTeamSelection()
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
            if node.name == "newGame" {
                startNewGame()
            } else if node.name == "restartGame" {
                restartGameWithSamePlayers()
            } else if let playerId = UUID(uuidString: node.name?.replacingOccurrences(of: "assassinate_", with: "") ?? "") {
                if game.assassinate(targetId: playerId) {
                    statusLabel?.text = "Evil wins! Merlin was found!"
                } else {
                    statusLabel?.text = "Good wins! Merlin remains hidden!"
                }
                updateUI()
            }
            
        case .gameOver:
            if node.name == "newGame" {
                startNewGame()
            } else if node.name == "restartGame" {
                restartGameWithSamePlayers()
            }
            
        default:
            break
        }
    }
    
    private func startNewGame() {
        let setupScene = SetupScene(size: size)
        view?.presentScene(setupScene, transition: .crossFade(withDuration: 0.5))
    }
    
    private func restartGameWithSamePlayers() {
        let existingPlayers = game.players.map { $0.name }
        let newGame = Game()
        
        // Add all existing players to the new game
        for playerName in existingPlayers {
            _ = newGame.addPlayer(name: playerName)
        }
        
        // Assign new roles and start the game
        newGame.assignRoles()
        newGame.startRoleReveal()
        
        // Create new role reveal scene with the same players
        let roleRevealScene = RoleRevealScene(game: newGame, size: size)
        view?.presentScene(roleRevealScene, transition: .crossFade(withDuration: 0.5))
    }
    
    private func updateUI() {
        // Update quest board
        for (index, node) in questBoard?.children.enumerated() ?? [].enumerated() {
            if let result = game.getQuestResult(at: index) {
                (node as? SKSpriteNode)?.color = result ? .green : .red
            }
        }
        
        // Hide all special views by default
        teamVoteView?.isHidden = true
        preVoteView?.isHidden = true
        questResultView?.isHidden = true
        childNode(withName: "teamSelectionContainer")?.isHidden = true
        assassinationView?.isHidden = true
        toggleVoteButtons(visible: false)
        
        // Update status and UI elements based on game phase
        switch game.currentPhase {
        case .setup:
            statusLabel?.text = "Game Setup"
            questRequirementLabel?.text = "Waiting for players..."
            
        case .roleReveal:
            if currentRevealIndex < game.players.count {
                let player = game.players[currentRevealIndex]
                let isEvil = player.role.isEvil
                let teamText = isEvil ? "Evil Team" : "Good Team"
                statusLabel?.text = "Your Role: \(player.role)"
                questRequirementLabel?.text = "You are on the \(teamText)\nTap to continue"
                questRequirementLabel?.numberOfLines = 2
            } else {
                statusLabel?.text = "All Roles Revealed"
                questRequirementLabel?.text = "Starting game..."
            }
            
        case .questSelection:
            let questNumber = game.getCurrentQuestNumber()
            let requirement = game.getCurrentQuestRequirement() ?? 0
            let needsTwoFails = game.currentQuestRequiresTwoFails()
            
            statusLabel?.text = "Quest \(questNumber)"
            teamSizeLabel?.text = "Select \(requirement) players\(needsTwoFails ? "\n(Requires 2 fails to fail)" : "")"
            teamSizeLabel?.numberOfLines = 2
            updateTeamSelectionUI()
            childNode(withName: "teamSelectionContainer")?.isHidden = false
            
        case .teamVoting:
            statusLabel?.text = "Vote as a group to approve or reject the team"
            questRequirementLabel?.text = "Selected team: " + game.players
                .filter { game.selectedTeamMembers.contains($0.id) }
                .map { $0.name }
                .joined(separator: ", ")
            teamVoteView?.isHidden = false
            
        case .questVoting:
            currentVotingPlayerIndex = 0
            showNextVoter()
            
        case .questResult:
            updateQuestResultView()
            
        case .assassination:
            statusLabel?.text = "Choose your target"
            questRequirementLabel?.text = ""
            assassinationView?.isHidden = false
            
        case .gameOver:
            // Add both buttons if not already present
            if childNode(withName: "restartGame") == nil {
                let buttonWidth: CGFloat = 150
                let buttonHeight: CGFloat = 40
                let buttonSpacing: CGFloat = 20
                
                // Restart Game button
                let restartButton = SKSpriteNode(color: .blue, size: CGSize(width: buttonWidth, height: buttonHeight))
                restartButton.position = CGPoint(x: frame.midX - buttonWidth/2 - buttonSpacing/2, y: frame.height * 0.3)
                restartButton.name = "restartGame"
                
                let restartLabel = SKLabelNode(fontNamed: "Avenir")
                restartLabel.text = "Restart Game"
                restartLabel.fontSize = 18
                restartLabel.verticalAlignmentMode = .center
                restartButton.addChild(restartLabel)
                
                addChild(restartButton)
                
                // New Game button
                let newGameButton = SKSpriteNode(color: .green, size: CGSize(width: buttonWidth, height: buttonHeight))
                newGameButton.position = CGPoint(x: frame.midX + buttonWidth/2 + buttonSpacing/2, y: frame.height * 0.3)
                newGameButton.name = "newGame"
                
                let newGameLabel = SKLabelNode(fontNamed: "Avenir")
                newGameLabel.text = "New Players"
                newGameLabel.fontSize = 18
                newGameLabel.verticalAlignmentMode = .center
                newGameButton.addChild(newGameLabel)
                
                addChild(newGameButton)
            }
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
            // Check for button touches first
            if node.name == "newGame" || node.parent?.name == "newGame" {
                startNewGame()
                return
            }
            if node.name == "restartGame" || node.parent?.name == "restartGame" {
                restartGameWithSamePlayers()
                return
            }
            
            // Handle assassination buttons
            if let nodeName = node.name,
               nodeName.starts(with: "assassinate_") {
                let playerId = String(nodeName.dropFirst("assassinate_".count))
                if let targetId = UUID(uuidString: playerId) {
                    if game.assassinate(targetId: targetId) {
                        statusLabel?.text = "Evil wins! Merlin was found!"
                    } else {
                        statusLabel?.text = "Good wins! Merlin remains hidden!"
                    }
                    updateUI()
                }
                return
            }
            
            // Handle other game phase specific touches
            if game.currentPhase == .roleReveal {
                currentRevealIndex += 1
                if currentRevealIndex >= game.players.count {
                    game.nextPhase()
                }
                updateUI()
                return
            }
            
            if let checkboxIndex = Int(node.name?.replacingOccurrences(of: "checkbox_", with: "") ?? "") {
                toggleCheckbox(at: checkboxIndex)
            } else if node.name == "selectTeam" {
                handleTeamSelection()
            } else if node.name == "teamApprove" {
                game.submitTeamVoteResult(approved: true)
                updateUI()
            } else if node.name == "teamReject" {
                game.submitTeamVoteResult(approved: false)
                resetTeamSelection()
                updateUI()
            } else if node.name == "readyToVote" {
                let teamMembers = game.players.filter { game.selectedTeamMembers.contains($0.id) }
                if currentVotingPlayerIndex < teamMembers.count {
                    let currentVoter = teamMembers[currentVotingPlayerIndex]
                    showVotingScreen(for: currentVoter)
                }
            } else if node.name == "approve" || node.name == "reject" {
                if game.currentPhase == .questVoting {
                    let teamMembers = game.players.filter { game.selectedTeamMembers.contains($0.id) }
                    if currentVotingPlayerIndex < teamMembers.count {
                        let currentVoter = teamMembers[currentVotingPlayerIndex]
                        _ = game.submitQuestVote(playerId: currentVoter.id, succeeded: node.name == "approve")
                        currentVotingPlayerIndex += 1
                        showNextVoter()
                    }
                }
            } else if node.name == "continueButton" {
                if game.currentPhase == .questResult {
                    game.continueFromQuestResult()
                    updateUI()
                }
            }
        }
    }
}
