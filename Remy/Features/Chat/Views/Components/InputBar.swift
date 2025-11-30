import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let canSend: Bool
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)

            Button(action: onSend) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 32, height: 32)
                .background(canSend ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    VStack {
        Spacer()
        InputBar(text: .constant("Hello"), canSend: true, isLoading: false, onSend: {})
        InputBar(text: .constant(""), canSend: false, isLoading: true, onSend: {})
    }
}
