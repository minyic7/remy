import SwiftUI

struct MessageBubble: View {
    let message: Message

    private var isUser: Bool {
        message.role == .user
    }

    private var backgroundColor: Color {
        isUser ? .blue : Color(.systemGray5)
    }

    private var textColor: Color {
        isUser ? .white : .primary
    }

    private var alignment: HorizontalAlignment {
        isUser ? .trailing : .leading
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 60)
            }

            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if !isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(message: Message(role: .user, content: "Hello, how are you?"))
        MessageBubble(message: Message(role: .assistant, content: "I'm doing well, thank you for asking!"))
    }
}
