import Foundation

enum Role {
    case merlin
    case percival
    case loyalServant
    case assassin
    case morgana
    case mordredServant
    case mordred
    case oberon
    
    var isEvil: Bool {
        switch self {
        case .merlin, .percival, .loyalServant:
            return false
        case .assassin, .morgana, .mordredServant, .mordred, .oberon:
            return true
        }
    }
    
    var description: String {
        switch self {
        case .merlin: return "Merlin"
        case .percival: return "Percival"
        case .loyalServant: return "Loyal Servant of Arthur"
        case .assassin: return "Assassin"
        case .morgana: return "Morgana"
        case .mordredServant: return "Minion of Mordred"
        case .mordred: return "Mordred"
        case .oberon: return "Oberon"
        }
    }
    
    static func from(string: String) -> Role? {
        switch string {
        case "merlin": return .merlin
        case "percival": return .percival
        case "loyalServant": return .loyalServant
        case "assassin": return .assassin
        case "morgana": return .morgana
        case "mordredServant": return .mordredServant
        case "mordred": return .mordred
        case "oberon": return .oberon
        default: return nil
        }
    }
}

class Player {
    let id: UUID
    let name: String
    var role: Role
    var isLeader: Bool = false
    var votesInFavor: Bool?
    var isSelected: Bool = false
    
    init(name: String, role: Role) {
        self.id = UUID()
        self.name = name
        self.role = role
    }
    
    func canSee(_ otherPlayer: Player) -> Bool {
        switch role {
        case .merlin:
            // Merlin sees all evil except Mordred
            return otherPlayer.role.isEvil && otherPlayer.role != .mordred
        case .percival:
            // Percival sees Merlin and Morgana (but can't distinguish between them)
            return otherPlayer.role == .merlin || otherPlayer.role == .morgana
        case .assassin, .morgana, .mordredServant, .mordred:
            // Evil players see all other evil players except Oberon
            return otherPlayer.role.isEvil && otherPlayer.role != .oberon
        case .oberon:
            // Oberon sees no one
            return false
        case .loyalServant:
            // Loyal servants see no one
            return false
        }
    }
    
    func vote(inFavor: Bool) {
        votesInFavor = inFavor
    }
    
    func clearVote() {
        votesInFavor = nil
    }
} 