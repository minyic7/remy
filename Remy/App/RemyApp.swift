import SwiftUI

@main
struct RemyApp: App {
    @State private var viewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: viewModel)
        }
    }
}
