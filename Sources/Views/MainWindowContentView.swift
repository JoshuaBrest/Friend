import AVFoundation
import Luminare
import MarkdownUI
import SwiftUI

struct ChatBubbleView: View {
    let message: AgentModel.ChatMessage

    var body: some View {
        HStack(alignment: .center) {
            if case .user(let text) = message.data {
                Spacer()
                Markdown(text)
                    .padding(12)
                    .background(.quinary.opacity(0.5))
                    .modifier(LuminareBordered())
                    .cornerRadius(8)
                    .padding(.leading, 24)
                    .multilineTextAlignment(.leading)
            } else if case .assistant(let text) = message.data {
                Markdown(text)
                    .padding(12)
                    .background(.quinary.opacity(0.5))
                    .modifier(LuminareBordered())
                    .cornerRadius(8)
                    .padding(.trailing, 24)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}

struct MainWindowContentView: View {
    @AppStorage("apiKey") private var apiKeyStorage: String?

    var body: some View {
        if let apiKey = apiKeyStorage, !apiKey.isEmpty {
            MainWindowContentViewWithApiKey(apiKey: apiKey)
                .padding(12)
                .frame(width: 512, height: 512, alignment: .topLeading)
                .luminareBackground()
        } else {
            VStack(alignment: .center) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("chat.missingApiKey")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.secondary)
                    Button {
                        MainApp.shared.showSettingsWindow()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gear")
                            Text("chat.openSettings")
                        }
                        .padding(8)
                    }
                    .buttonStyle(LuminareCompactButtonStyle(extraCompact: true))
                    .modifier(LuminareBordered())
                }
            }
            .padding(12)
            .frame(width: 512, height: 512, alignment: .center)
            .luminareBackground()
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ChatScrollView: View {
    let chats: [AgentModel.ChatMessage]
    let generating: Bool

    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolledDown: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { scrollOffset = geo.frame(in: .global).minY }
                                .onChange(of: geo.frame(in: .global).minY) { newY in
                                    isScrolledDown = newY < scrollOffset - 10
                                }
                        }
                        .frame(height: 0)

                        ForEach(chats, id: \.id) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }

                        if generating {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("chat.generating")
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer().frame(height: 256)

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                }
                .onChange(of: chats.count) { _ in scrollToBottom(proxy) }
                .onChange(of: generating) { _ in scrollToBottom(proxy) }
            }
            .mask(topFadeOverlay)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private var topFadeOverlay: some View {
        if isScrolledDown {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct MainWindowContentViewWithApiKey: View {
    private var apiKey: String
    @State private var prompt: String = ""
    @State private var promptDisabled: Bool = false
    @State private var transcriptionLoading: Bool = false
    @State private var microphoneRecording: Bool = false
    @State private var microphoneDeniedErrorShown: Bool = false
    @State private var chats: [AgentModel.ChatMessage] = []
    @StateObject var agent: AgentModel
    @StateObject var mic = MicrophoneRecorderModel()

    public init(apiKey: String) {
        self.apiKey = apiKey
        _agent = StateObject(wrappedValue: AgentModel(apiToken: apiKey))
    }

    var body: some View {
        VStack(spacing: 16) {
            if chats.isEmpty {
                VStack(alignment: .center) {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        VStack(spacing: 8) {
                            Text("chat.introduction")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.secondary)
                            Text("chat.introduction.message")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ChatScrollView(chats: chats, generating: agent.generating)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if microphoneRecording {
                VStack(alignment: .trailing) {
                    VStack {
                        CapsuleWaveformView(bars: mic.bars)
                    }
                    .padding(12)
                    .cornerRadius(8)
                    .background(.quinary.opacity(0.5))
                    .modifier(LuminareBordered())
                    .transition(.opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: nil, alignment: .trailing)
            }
            HStack {
                LuminareTextField(
                    "chat.startHere", text: $prompt,
                    onSubmit: {
                        submitPrompt(prompt: prompt)
                    }
                )
                .disabled(
                    promptDisabled || microphoneRecording || transcriptionLoading
                        || agent.generating
                )
                .modifier(LuminareBordered())
                Button {
                    if microphoneRecording {
                        mic.stop()
                        withAnimation {
                            microphoneRecording = false
                            promptDisabled = false
                            transcriptionLoading = true
                        }
                        Task { await transcribeAndSubmit(mic.getOutputURL()) }
                        return
                    }
                    Task {
                        await startRecording()
                    }
                } label: {
                    HStack {
                        if transcriptionLoading {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 16, height: 16)
                                .opacity(transcriptionLoading ? 1 : 0)
                        } else {
                            Image(systemName: microphoneRecording ? "pause.fill" : "mic.fill")
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .buttonStyle(LuminareCompactButtonStyle())
                .disabled(
                    (promptDisabled && !microphoneRecording) || transcriptionLoading
                        || agent.generating)
                Button {
                    agent.reset()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 16, height: 16)
                }
                .aspectRatio(1, contentMode: .fit)
                .buttonStyle(LuminareCompactButtonStyle())
                .disabled(
                    promptDisabled || microphoneRecording || transcriptionLoading
                        || agent.generating
                )

            }
            .frame(height: 32)
        }
        .alert("chat.microphoneDenied", isPresented: $microphoneDeniedErrorShown) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("chat.microphoneDenied.message")
        }
        .onChange(of: agent.chats) { newValue in
            withAnimation {
                chats = newValue
            }
        }
        .onChange(of: apiKey) { newValue in
            agent.updateApiToken(newValue)
        }
    }

    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() async {
        let granted = await requestPermission()
        if !granted {
            microphoneDeniedErrorShown = true
            return
        }

        withAnimation {
            promptDisabled = true
            microphoneRecording = true
        }

        mic.start()
    }

    func transcribeAndSubmit(_ url: URL) async {
        let result = await WhisperModel.transcribe(url)
        if let result = result {
            submitPrompt(prompt: result)
        }

        withAnimation {
            transcriptionLoading = false
        }
    }

    func submitPrompt(prompt: String) {
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty prompts
        guard !prompt.isEmpty else { return }

        Task {
            await agent.chat(query: prompt)
        }

        withAnimation {
            self.prompt = ""
        }
    }
}

struct CapsuleWaveformView: View {
    var bars: [Float?]

    @State private var displayedBars: [Float] = Array(repeating: 0.2, count: 60)
    @State private var pixelOffset: CGFloat = 0

    static let barWidth: CGFloat = 4
    static let spacing: CGFloat = 2
    static let visibleCount = 60
    static let barDistance: CGFloat = 6
    static let updateInterval: TimeInterval = 0.016

    let timer = Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            HStack(spacing: Self.spacing) {
                ForEach(displayedBars.indices, id: \.self) { i in
                    Capsule()
                        .fill(Color.gray)
                        .frame(width: Self.barWidth, height: max(4, CGFloat(displayedBars[i]) * 48))
                }
            }
            .offset(x: -pixelOffset)
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.1),
                        .init(color: .black, location: 0.9),
                        .init(color: .clear, location: 1),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .frame(width: CGFloat(Self.visibleCount) * Self.barDistance, height: 48)
        .onReceive(timer) { _ in
            pixelOffset += 1

            if pixelOffset >= Self.barDistance {
                guard let newBar = bars.first, let newBar else { return }

                displayedBars.removeFirst()
                displayedBars.append(newBar)
                pixelOffset = 0
            }
        }
    }
}
