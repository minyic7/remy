import Foundation

struct Conversation: Identifiable {
    let id: UUID
    var messages: [Message]
    let createdAt: Date

    init(id: UUID = UUID(), messages: [Message] = [], createdAt: Date = Date()) {
        self.id = id
        self.messages = messages
        self.createdAt = createdAt
    }

    mutating func addMessage(_ message: Message) {
        messages.append(message)
    }
}
