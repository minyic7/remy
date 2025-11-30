import Foundation

/// Main view model for chat functionality.
/// - Note: @MainActor ensures all property mutations happen on the main thread,
///   which is required for SwiftUI observation. This includes the streaming updates
///   to `conversation.messages[assistantIndex].content` during SSE response handling.
@Observable
@MainActor
final class ChatViewModel {
    var conversation: Conversation = Conversation()
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let apiClient: ClaudeAPIClient

    init(apiClient: ClaudeAPIClient = ClaudeAPIClient()) {
        self.apiClient = apiClient
    }

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func sendMessage() async {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        let userMessage = Message(role: .user, content: trimmedText)
        conversation.addMessage(userMessage)
        inputText = ""

        let assistantMessage = Message(role: .assistant, content: "")
        conversation.addMessage(assistantMessage)
        let assistantIndex = conversation.messages.count - 1

        do {
            let stream = try await apiClient.sendMessage(messages: Array(conversation.messages.dropLast()))

            // Safe to mutate here because @MainActor guarantees main thread execution
            for try await text in stream {
                conversation.messages[assistantIndex].content += text
            }
        } catch {
            conversation.messages.remove(at: assistantIndex)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }

    func clearConversation() {
        conversation = Conversation()
        errorMessage = nil
    }

    /// Retry sending the last user message after an error
    func retryLastMessage() async {
        guard conversation.messages.contains(where: { $0.role == .user }) else {
            return
        }

        errorMessage = nil
        isLoading = true

        let assistantMessage = Message(role: .assistant, content: "")
        conversation.addMessage(assistantMessage)
        let assistantIndex = conversation.messages.count - 1

        do {
            let stream = try await apiClient.sendMessage(messages: Array(conversation.messages.dropLast()))

            for try await text in stream {
                conversation.messages[assistantIndex].content += text
            }
        } catch {
            conversation.messages.remove(at: assistantIndex)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
