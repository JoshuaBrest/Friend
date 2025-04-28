import Foundation
import OpenAI

let systemMessage = """
    Locale: \(Locale.current.identifier)

    You are a helpful assistant named \(String(localized: "app.name")), powered by OpenAI's GPT-4o model and created by [Joshua Brest](https://github.com/JoshuaBrest). If asked about your origins, briefly mention your basis on GPT-4o and your creator.

    Your role is similar to Siri, capable of controlling the user's local system through available tools.

    **Interaction Guidelines:**
    - When explaining your capabilities, maintain a casual, friendly, and descriptive tone.
    - For direct commands or explicit instructions, respond concisely and clearly, optimizing for brevity and precision.
    - Prefer short acknowledgments (e.g., "On it," "Dark mode enabled") rather than verbose confirmations.
    - Avoid repeating the user's query or providing unnecessary context or justification.
    - Do not conclude responses with phrases like "Let me know if you need anything else."

    **Language and Formatting:**
    - Always use gender-neutral language.
    - Feel free to use first-person references ("I", "me") naturally in conversation.
    - Markdown formatting is enabled. Use markdown where appropriate to enhance readability and clarity—for instance, use `code` formatting for code snippets and *italics* for emphasis.
    """

final public class AgentModel: ObservableObject {
    private var openAI: OpenAI
    private let tools: [ChatQuery.ChatCompletionToolParam.FunctionDefinition]
    private var messages: [ChatQuery.ChatCompletionMessageParam] = [
        .system(.init(content: systemMessage))
    ]

    public enum ChatMessageData: Hashable {
        case user(String)
        case assistant(String)
    }

    public struct ChatMessage: Identifiable, Hashable {
        public let id = UUID()
        public var data: ChatMessageData
    }

    public enum DataError: LocalizedError {
        case noChoice
    }

    public enum ToolNames: String {
        case getCurrentDateTime = "getCurrentDateTime"
        case setDarkMode = "setDarkMode"
        case getCurrentLocation = "getCurrentLocation"
        case getLocationFromString = "getLocationFromString"
        case requestWeather = "requestWeather"
        case getVolume = "getVolume"
        case setVolume = "setVolume"
    }

    public struct StringResult: Codable {
        let result: String
    }

    @Published var chats: [ChatMessage] = []
    @Published var generating: Bool = false

    public init(apiToken: String) {
        self.openAI = OpenAI(apiToken: apiToken)
        self.tools = [
            .init(
                name: ToolNames.getCurrentDateTime.rawValue,
                description: "Get the current date and time.",
            ),
            .init(
                name: ToolNames.getCurrentLocation.rawValue,
                description: "Get the current location of the system.",
            ),
            .init(
                name: ToolNames.getLocationFromString.rawValue,
                description: "Geocode a location from a string.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "location": .init(
                            type: .string,
                            description: "The location to geocode."
                        )
                    ],
                    required: ["location"]
                )
            ),
            .init(
                name: ToolNames.requestWeather.rawValue,
                description: "Request the weather for a location.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "latitude": .init(
                            type: .number,
                            description: "The latitude of the location."
                        ),
                        "longitude": .init(
                            type: .number,
                            description: "The longitude of the location."
                        ),
                    ],
                    required: ["latitude", "longitude"]
                )
            ),
            .init(
                name: ToolNames.setDarkMode.rawValue,
                description: "Set the dark mode of the system.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "enabled": .init(
                            type: .boolean,
                            description: "Enable or disable dark mode. Leave blank to toggle."
                        )
                    ]
                )
            ),
            .init(
                name: ToolNames.getVolume.rawValue,
                description:
                    "Get the current volume of the system. Returns a number between 0 and 1.",
            ),
            .init(
                name: ToolNames.setVolume.rawValue,
                description: "Set the volume of the system.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "volume": .init(
                            type: .number,
                            description: "The volume to set, between 0 and 1."
                        )
                    ],
                    required: ["volume"]
                )
            ),
        ]
    }

    public func reset() {
        self.messages = [
            .system(.init(content: systemMessage))
        ]
        self.chats = []
    }

    public func updateApiToken(_ apiToken: String) {
        self.openAI = OpenAI(apiToken: apiToken)
    }

    public func handleToolCalls(
        _ toolCalls: [ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam]
    ) async {
        for toolCall in toolCalls {
            let arguments = toolCall.function.arguments
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            var data: String?

            switch toolCall.function.name {
            case ToolNames.getCurrentDateTime.rawValue:
                let dateTime = ToolsModel.getCurrentTime()
                data = try? String(
                    data: encoder.encode(dateTime),
                    encoding: .utf8
                )
            case ToolNames.getCurrentLocation.rawValue:
                let location = await ToolsModel.getCurrentLocation()
                switch location {
                case .success(let loc):
                    let json = StringResult(result: "\(loc.latitude), \(loc.longitude)")
                    data = try? String(data: encoder.encode(json), encoding: .utf8)
                case .failure(let error):
                    let errorMessage = StringResult(result: "Error: \(error.rawValue)")
                    data = try? String(data: encoder.encode(errorMessage), encoding: .utf8)
                }
            case ToolNames.getLocationFromString.rawValue:
                struct Parameters: Codable {
                    let location: String
                }

                guard let argumentData = arguments.data(using: .utf8),
                    let parameters = try? JSONDecoder().decode(Parameters.self, from: argumentData)
                else {
                    continue
                }

                let location = await ToolsModel.geocodeString(parameters.location)

                if let location = location {
                    let json = StringResult(result: "\(location.latitude), \(location.longitude)")
                    data = try? String(data: encoder.encode(json), encoding: .utf8)
                } else {
                    let errorMessage = StringResult(result: "Error: Could not geocode location.")
                    data = try? String(data: encoder.encode(errorMessage), encoding: .utf8)
                }
            case ToolNames.requestWeather.rawValue:
                struct Parameters: Codable {
                    let latitude: Double
                    let longitude: Double
                }

                guard let argumentData = arguments.data(using: .utf8),
                    let parameters = try? JSONDecoder().decode(Parameters.self, from: argumentData)
                else {
                    continue
                }

                let weather = await ToolsModel.getWeather(
                    latitude: parameters.latitude,
                    longitude: parameters.longitude
                )

                if let weather = weather {
                    data = try? String(data: encoder.encode(weather), encoding: .utf8)
                } else {
                    let errorMessage = StringResult(result: "Error: Could not fetch weather.")
                    data = try? String(data: encoder.encode(errorMessage), encoding: .utf8)
                }
            case ToolNames.setDarkMode.rawValue:
                struct Parameters: Codable {
                    let enabled: Bool?
                }

                guard let argumentData = arguments.data(using: .utf8),
                    let parameters = try? JSONDecoder().decode(Parameters.self, from: argumentData)
                else {
                    continue
                }

                let darkMode = ToolsModel.setDarkMode(darkMode: parameters.enabled)
                let returnMessage =
                    switch parameters.enabled {
                    case .some(true):
                        darkMode ? "Dark mode set to true" : "Dark mode already set to true"
                    case .some(false):
                        darkMode ? "Dark mode set to false" : "Dark mode already set to false"
                    case .none:
                        darkMode ? "Dark mode toggled to true" : "Dark mode toggled to false"
                    }
                let json = StringResult(result: returnMessage)
                data = try? String(data: encoder.encode(json), encoding: .utf8)
            case ToolNames.getVolume.rawValue:
                let volume = ToolsModel.getSystemVolume()
                let json = StringResult(result: "\(volume)")
                data = try? String(data: encoder.encode(json), encoding: .utf8)
            case ToolNames.setVolume.rawValue:
                struct Parameters: Codable {
                    let volume: Double
                }

                guard let argumentData = arguments.data(using: .utf8),
                    let parameters = try? JSONDecoder().decode(Parameters.self, from: argumentData)
                else {
                    continue
                }

                let _ = ToolsModel.setSystemVolume(Float(parameters.volume))
                let json = StringResult(result: "Volume set to \(parameters.volume)")
                data = try? String(data: encoder.encode(json), encoding: .utf8)
            default:
                print("Unknown tool call: \(toolCall.function.name)")
                continue
            }

            // If data is nil, we skip appending the message
            guard let data = data else { continue }

            let message: ChatQuery.ChatCompletionMessageParam = .tool(
                .init(content: data, toolCallId: toolCall.id)
            )
            self.messages.append(message)
        }
    }

    public func chat(
        query: String,
    ) async {
        self.generating = true
        chats.append(.init(data: .user(query)))
        messages.append(.user(.init(content: .string(query))))

        while true {
            let query = ChatQuery(
                messages: messages,
                model: .gpt4_o,
                tools: tools.map { .init(function: $0) },
            )

            do {
                let response = try await openAI.chats(query: query)
                let choice = response.choices.first
                guard let choice else { throw DataError.noChoice }

                // Append the assistant's message to the messages.
                self.messages.append(
                    .assistant(
                        .init(
                            content: choice.message.content,
                            toolCalls: choice.message.toolCalls
                        )))

                if let content = choice.message.content {
                    self.chats.append(.init(data: .assistant(content)))
                }

                if let toolCalls = choice.message.toolCalls {
                    await self.handleToolCalls(toolCalls)
                    if toolCalls.isEmpty {
                        break
                    }
                } else {
                    break
                }
            } catch {
                print("Error: \(error)")
                break
            }
        }

        self.generating = false
    }

}
