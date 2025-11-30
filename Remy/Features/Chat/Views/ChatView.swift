import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var showScrollButton = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList

                Divider()

                InputBar(
                    text: $viewModel.inputText,
                    canSend: viewModel.canSend,
                    isLoading: viewModel.isLoading,
                    onSend: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                )
            }
            .navigationTitle("Remy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.clearConversation()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.conversation.messages.isEmpty)
                    .accessibilityLabel("Clear conversation")
                }
            }
            .alert(
                "Error",
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button("Retry") {
                    Task {
                        await viewModel.retryLastMessage()
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.conversation.messages) { message in
                            // Hide empty assistant message when showing typing indicator
                            if !(message.role == .assistant && message.content.isEmpty && viewModel.isLoading) {
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }

                        if viewModel.isLoading,
                           let lastMessage = viewModel.conversation.messages.last,
                           lastMessage.role == .assistant,
                           lastMessage.content.isEmpty {
                            TypingIndicator()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .id("typing-indicator")
                        }

                        // Bottom anchor for scroll detection
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                            .onAppear { showScrollButton = false }
                            .onDisappear { showScrollButton = true }
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.conversation.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isLoading) { _, isLoading in
                    if isLoading {
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Scroll to bottom button
                if showScrollButton && !viewModel.conversation.messages.isEmpty {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        scrollToBottom(proxy: proxy)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Scroll to bottom")
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showScrollButton)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

#Preview {
    ChatView(viewModel: ChatViewModel())
}
