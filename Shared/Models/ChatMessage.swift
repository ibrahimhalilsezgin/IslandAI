import Foundation

public enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public var id: UUID
    public var role: MessageRole
    public var content: String
    public var timestamp: Date

    public init(id: UUID = UUID(), role: MessageRole = .user, content: String = "", timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
