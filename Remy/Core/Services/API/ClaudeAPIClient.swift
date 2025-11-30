import Foundation
import OSLog

// MARK: - Configuration

enum ClaudeAPIConfig {
    /// Claude model to use for chat completions.
    /// See: https://docs.anthropic.com/en/docs/about-claude/models
    static let model = "claude-sonnet-4-20250514"

    /// Maximum tokens for response. Claude Sonnet supports up to 8192 output tokens.
    /// Set to 4096 for reasonable response length while keeping costs manageable.
    static let maxTokens = 4096

    /// Anthropic API version. Update when migrating to newer API versions.
    /// See: https://docs.anthropic.com/en/api/versioning
    static let anthropicVersion = "2023-06-01"
}

// MARK: - Client

actor ClaudeAPIClient {
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiKey: String
    private let logger = Logger(subsystem: "com.remy.app", category: "ClaudeAPI")

    init(apiKey: String = AppConfig.claudeAPIKey) {
        self.apiKey = apiKey
    }

    func sendMessage(messages: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(ClaudeAPIConfig.anthropicVersion, forHTTPHeaderField: "anthropic-version")

        let apiMessages = messages.map { message in
            APIMessage(role: message.role.rawValue, content: message.content)
        }

        let requestBody = APIRequest(
            model: ClaudeAPIConfig.model,
            maxTokens: ClaudeAPIConfig.maxTokens,
            stream: true,
            messages: apiMessages
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            var errorBody = ""
            for try await line in bytes.lines {
                errorBody += line
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        return createStream(from: bytes)
    }

    private func createStream(
        from bytes: URLSession.AsyncBytes
    ) -> AsyncThrowingStream<String, Error> {
        let logger = self.logger
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines where line.hasPrefix("data: ") {
                        let shouldStop = self.processSSELine(
                            line,
                            continuation: continuation,
                            logger: logger
                        )
                        if shouldStop { return }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func processSSELine(
        _ line: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation,
        logger: Logger
    ) -> Bool {
        let jsonString = String(line.dropFirst(6))

        if jsonString == "[DONE]" {
            continuation.finish()
            return true
        }

        guard let data = jsonString.data(using: .utf8) else { return false }

        do {
            let event = try JSONDecoder().decode(StreamEvent.self, from: data)
            if let delta = event.delta, let text = delta.text {
                continuation.yield(text)
            }
            if event.type == "message_stop" {
                continuation.finish()
                return true
            }
        } catch {
            #if DEBUG
            logger.warning("SSE decode error: \(error.localizedDescription)")
            logger.debug("Failed JSON: \(jsonString)")
            #endif
        }
        return false
    }
}

// MARK: - API Models

private struct APIRequest: Encodable {
    let model: String
    let maxTokens: Int
    let stream: Bool
    let messages: [APIMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case stream
        case messages
    }
}

private struct APIMessage: Encodable {
    let role: String
    let content: String
}

private struct StreamEvent: Decodable {
    let type: String
    let delta: Delta?

    struct Delta: Decodable {
        let type: String?
        let text: String?
    }
}
