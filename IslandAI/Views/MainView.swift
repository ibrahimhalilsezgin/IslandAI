import SwiftUI

struct MainView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @StateObject private var liveActivityManager = LiveActivityManager()

    @State private var messages: [ChatMessage] = []
    @State private var isThinking: Bool = false
    @State private var showSettings: Bool = false

    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("baseURL") private var baseURL: String = "https://ai.ibrahimhalilsezgin.com/v1"
    @AppStorage("selectedModel") private var selectedModel: String = "ag/gemini-3.6-flash-high"
    @AppStorage("systemPrompt") private var systemPrompt: String = "Sen Türkçe yanıt veren, yardımsever ve hızlı bir kişisel asistansın."

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Island AI")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        toggleLiveActivity()
                    } label: {
                        Image(systemName: liveActivityManager.isActivityActive ? "platter.filled.top.iphone" : "iphone")
                            .foregroundColor(liveActivityManager.isActivityActive ? .green : .secondary)
                            .imageScale(.large)
                    }
                    .padding(.trailing, 10)

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Divider()

                // Chat List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            if isThinking {
                                HStack {
                                    ProgressView()
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("thinking")
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isThinking) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Live Transcript Preview
                if speechRecognizer.isRecording {
                    Text(speechRecognizer.transcript.isEmpty ? "Dinliyor..." : speechRecognizer.transcript)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .lineLimit(2)
                }

                // Bottom Bar
                HStack {
                    if speechRecognizer.isRecording {
                        AudioWaveView(isAnimating: true, color: .red)
                            .frame(width: 40)
                    } else if speechSynthesizer.isSpeaking {
                        AudioWaveView(isAnimating: true, color: .accentColor)
                            .frame(width: 40)
                    } else {
                        Spacer().frame(width: 40) // Placeholder
                    }

                    Spacer()

                    Button {
                        toggleRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(speechRecognizer.isRecording ? Color.red : Color.accentColor)
                                .frame(width: 70, height: 70)
                                .shadow(radius: 5)

                            Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(speechRecognizer.isRecording ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechRecognizer.isRecording)

                    Spacer()

                    Spacer().frame(width: 40) // Balance
                }
                .padding()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerRecord"))) { _ in
                handleDeepLinkRecord()
            }
            .onChange(of: speechSynthesizer.isSpeaking) { speaking in
                if !speaking && !isThinking && !speechRecognizer.isRecording {
                    liveActivityManager.updateActivity(status: .idle)
                }
            }
            .onAppear {
                liveActivityManager.startActivity()
            }
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
            let question = speechRecognizer.transcript
            if !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                processUserQuestion(question)
            }
        } else {
            // Stop TTS if speaking
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stop()
            }
            speechRecognizer.startRecording()
            liveActivityManager.updateActivity(status: .listening)
        }
    }

    private func processUserQuestion(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        isThinking = true
        liveActivityManager.updateActivity(status: .thinking, question: text)

        Task {
            let aiService = AIService()
            do {
                let responseText = try await aiService.sendMessage(
                    messages: messages,
                    baseURL: baseURL,
                    apiKey: apiKey,
                    model: selectedModel,
                    systemPrompt: systemPrompt
                )

                await MainActor.run {
                    isThinking = false
                    let aiMessage = ChatMessage(role: .assistant, content: responseText)
                    messages.append(aiMessage)

                    liveActivityManager.updateActivity(status: .speaking, question: text, answer: responseText)
                    speechSynthesizer.speak(text: responseText)
                }
            } catch {
                await MainActor.run {
                    isThinking = false
                    let errorMessage = ChatMessage(role: .assistant, content: "Hata oluştu: \(error.localizedDescription)")
                    messages.append(errorMessage)
                    liveActivityManager.updateActivity(status: .idle)
                }
            }
        }
    }

    private func toggleLiveActivity() {
        if liveActivityManager.isActivityActive {
            liveActivityManager.endActivity()
        } else {
            liveActivityManager.startActivity()
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            if isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func handleDeepLinkRecord() {
        if !speechRecognizer.isRecording {
            toggleRecording()
        }
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            Text(message.content)
                .padding(12)
                .background(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundColor(message.role == .user ? .white : .primary)
                .cornerRadius(16)
                .padding(.horizontal)

            if message.role != .user { Spacer() }
        }
    }
}

#Preview {
    MainView()
}
