import Foundation

enum GamePhase {
    case setup           // Players entering names
    case roleReveal     // Players viewing their roles
    case questSelection // Leader selecting quest team
    case teamVoting     // Group voting on team
    case questVoting    // Team members voting on quest
    case questResult    // Showing quest result
    case assassination  // Assassin trying to identify Merlin
    case gameOver      // Game ended, showing results
}

class Game {
    // Game configuration
    private(set) var players: [Player] = []
    private(set) var currentPhase: GamePhase = .setup
    private(set) var currentLeaderIndex: Int = 0
    private(set) var currentQuestIndex: Int = 0
    private(set) var failedVoteCount: Int = 0
    private(set) var questResults: [Bool] = []
    private var selectedRoles: [Role: Bool] = [
        .merlin: true,      // Merlin is mandatory
        .assassin: true,    // Assassin is mandatory
        .percival: false,
        .morgana: false,
        .mordred: false,
        .oberon: false
    ]
    
    // Current state tracking
    private(set) var currentPlayerViewingRole: Player?
    private(set) var selectedTeamMembers: Set<UUID> = []
    private(set) var questVotes: [UUID: Bool] = [:]
    
    // Quest requirements based on player count
    private let questRequirements: [Int: [Int]] = [
        5: [2, 3, 2, 3, 3],
        6: [2, 3, 4, 3, 4],
        7: [2, 3, 3, 4, 4],
        8: [3, 4, 4, 5, 5],
        9: [3, 4, 4, 5, 5],
        10: [3, 4, 4, 5, 5]
    ]
    
    // Required fails per quest (quest 4 in 7+ player games needs 2 fails)
    private func requiredFails(forQuest quest: Int) -> Int {
        // Quest 4 (index 3) requires 2 fails for 7+ players
        return players.count >= 7 && quest == 3 ? 2 : 1
    }
    
    // Get the current quest number (1-based) for display
    func getCurrentQuestNumber() -> Int {
        return currentQuestIndex + 1
    }
    
    // Get whether current quest requires two fails
    func currentQuestRequiresTwoFails() -> Bool {
        return requiredFails(forQuest: currentQuestIndex) == 2
    }
    
    // Get quest requirements for current player count
    func getQuestRequirements() -> [Int]? {
        return questRequirements[players.count]
    }
    
    // Check if a specific quest requires two fails
    func questRequiresTwoFails(questIndex: Int) -> Bool {
        return players.count >= 7 && questIndex == 3
    }
    
    // MARK: - Game Setup
    
    func addPlayer(name: String) -> Bool {
        guard players.count < 10 else { return false }
        players.append(Player(name: name, role: .loyalServant)) // Temporary role
        return true
    }
    
    func setSelectedRoles(_ roles: [Role: Bool]) {
        // Ensure mandatory roles are always included
        var updatedRoles = roles
        updatedRoles[.merlin] = true
        updatedRoles[.assassin] = true
        selectedRoles = updatedRoles
    }
    
    func assignRoles() {
        guard currentPhase == .setup else { return }
        
        // Start with mandatory roles
        var roles: [Role] = [.merlin, .assassin]
        
        // Add selected optional roles
        if selectedRoles[.percival] == true { roles.append(.percival) }
        if selectedRoles[.morgana] == true { roles.append(.morgana) }
        if selectedRoles[.mordred] == true { roles.append(.mordred) }
        if selectedRoles[.oberon] == true { roles.append(.oberon) }
        
        // Calculate remaining slots
        let remainingCount = players.count - roles.count
        
        // Calculate good vs evil balance
        let totalEvil = roles.filter { $0.isEvil }.count
        let targetEvil = (players.count + 2) / 3  // Round up division
        let additionalEvil = max(0, targetEvil - totalEvil)
        let additionalGood = remainingCount - additionalEvil
        
        // Fill remaining slots
        roles += Array(repeating: .loyalServant, count: additionalGood)
        roles += Array(repeating: .mordredServant, count: additionalEvil)
        
        // Shuffle and assign
        roles.shuffle()
        for (index, role) in roles.enumerated() {
            players[index].role = role
        }
        
        currentPhase = .roleReveal
    }
    
    // MARK: - Role Reveal Phase
    
    func startRoleReveal() {
        guard currentPhase == .roleReveal else { return }
        currentPlayerViewingRole = players.first
    }
    
    func nextPlayerRoleReveal() -> Bool {
        guard let current = currentPlayerViewingRole,
              let currentIndex = players.firstIndex(where: { $0.id == current.id }) else {
            return false
        }
        
        if currentIndex + 1 < players.count {
            currentPlayerViewingRole = players[currentIndex + 1]
            return true
        } else {
            currentPhase = .questSelection
            currentPlayerViewingRole = nil
            return false
        }
    }
    
    // MARK: - Quest Management
    
    func getCurrentQuestRequirement() -> Int? {
        guard let requirements = questRequirements[players.count] else { return nil }
        return requirements[currentQuestIndex]
    }
    
    func togglePlayerSelection(_ playerId: UUID) -> Bool {
        guard currentPhase == .questSelection else { return false }
        
        if selectedTeamMembers.contains(playerId) {
            selectedTeamMembers.remove(playerId)
        } else {
            if let requirement = getCurrentQuestRequirement(),
               selectedTeamMembers.count < requirement {
                selectedTeamMembers.insert(playerId)
            } else {
                return false
            }
        }
        return true
    }
    
    func submitTeam() -> Bool {
        guard let requirement = getCurrentQuestRequirement(),
              selectedTeamMembers.count == requirement else {
            return false
        }
        
        currentPhase = .teamVoting
        return true
    }
    
    // MARK: - Voting
    
    func submitTeamVoteResult(approved: Bool) {
        guard currentPhase == .teamVoting else { return }
        
        if approved {
            currentPhase = .questVoting
            failedVoteCount = 0
        } else {
            failedVoteCount += 1
            if failedVoteCount >= 5 {
                // Evil wins if 5 votes fail
                currentPhase = .gameOver
            } else {
                // Move to next leader
                currentLeaderIndex = (currentLeaderIndex + 1) % players.count
                currentPhase = .questSelection
                selectedTeamMembers.removeAll()
            }
        }
    }
    
    func submitQuestVote(playerId: UUID, succeeded: Bool) {
        guard currentPhase == .questVoting,
              selectedTeamMembers.contains(playerId) else { return }
        
        questVotes[playerId] = succeeded
        
        if questVotes.count == selectedTeamMembers.count {
            processQuestResults()
        }
    }
    
    // MARK: - Quest Results

    func getQuestVoteCounts() -> (success: Int, fail: Int)? {
        guard currentPhase == .questResult else { return nil }
        let successCount = questVotes.values.filter { $0 }.count
        let failCount = questVotes.values.filter { !$0 }.count
        return (successCount, failCount)
    }

    private func processQuestResults() {
        let failCount = questVotes.values.filter { !$0 }.count
        let questSucceeded = failCount < requiredFails(forQuest: currentQuestIndex)
        questResults.append(questSucceeded)
        currentPhase = .questResult
    }
    
    func continueFromQuestResult() {
        guard currentPhase == .questResult else { return }
        
        // Clear state for next quest
        questVotes.removeAll()
        selectedTeamMembers.removeAll()
        
        if questResults.count >= 3 && questResults.filter({ $0 }).count >= 3 {
            // Good team has won, move to assassination phase
            currentPhase = .assassination
        } else if questResults.count >= 3 && questResults.filter({ !$0 }).count >= 3 {
            // Evil team has won
            currentPhase = .gameOver
        } else {
            // Move to next quest
            currentQuestIndex += 1
            currentLeaderIndex = (currentLeaderIndex + 1) % players.count
            currentPhase = .questSelection
        }
    }
    
    // MARK: - Assassination Phase
    
    func assassinate(targetId: UUID) -> Bool {
        guard currentPhase == .assassination,
              let target = players.first(where: { $0.id == targetId }) else {
            return false
        }
        
        // If assassin correctly identifies Merlin, evil wins
        let evilWins = target.role == .merlin
        currentPhase = .gameOver
        return evilWins
    }
    
    // MARK: - Game State Queries
    
    func isGameOver() -> Bool {
        return currentPhase == .gameOver
    }
    
    func getCurrentLeader() -> Player {
        return players[currentLeaderIndex]
    }
    
    func getQuestResult(at index: Int) -> Bool? {
        guard index < questResults.count else { return nil }
        return questResults[index]
    }
    
    // MARK: - Phase Management
    
    func nextPhase() {
        switch currentPhase {
        case .setup:
            currentPhase = .roleReveal
        case .roleReveal:
            currentPhase = .questSelection
        case .questSelection:
            // This transition is handled by submitTeam()
            break
        case .teamVoting:
            // This transition is handled by submitTeamVoteResult()
            break
        case .questVoting:
            // This transition is handled by submitQuestVote()
            break
        case .questResult:
            // This transition is handled by continueFromQuestResult()
            break
        case .assassination:
            // This transition is handled by assassinate()
            break
        case .gameOver:
            // Game is over, no next phase
            break
        }
    }
} 