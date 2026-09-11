import Foundation
import Speech
import AVFoundation

public class SpeechRecognizer: ObservableObject {
    @Published public var transcript: String = ""
    @Published public var isRecording: Bool = false
    @Published public var errorMessage: String? = nil

    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR")) ?? SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 1.8

    public var onSilenceDetected: (() -> Void)?

    public init() {
        requestPermissions()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch authStatus {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    self.errorMessage = "Ses tanıma izni verilmedi."
                @unknown default:
                    self.errorMessage = "Bilinmeyen izin durumu."
                }
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if !allowed {
                    self.errorMessage = "Mikrofon izni verilmedi."
                }
            }
        }
    }

    public func startRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }

        reset()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            self.errorMessage = "Ses tanıma şu anda kullanılamıyor."
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = "Ses oturumu başlatılamadı: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.errorMessage = "Tanıma isteği oluşturulamadı."
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            self.errorMessage = "Ses motoru başlatılamadı: \(error.localizedDescription)"
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            var isFinal = false

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                    self.resetSilenceTimer()
                }
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.stopRecording()
            }
        }
    }

    public func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    public func reset() {
        DispatchQueue.main.async {
            self.transcript = ""
            self.errorMessage = nil
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !self.transcript.isEmpty && self.isRecording {
                    self.onSilenceDetected?()
                }
            }
        }
    }
}
