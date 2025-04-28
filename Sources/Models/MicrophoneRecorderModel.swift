import AVFoundation

public class MicrophoneRecorderModel: ObservableObject {
    private var engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var timer: Timer?
    private let format: AVAudioFormat
    private var outputURL: URL
    private let maxSamples = 60
    private var waveformHistory: Float?

    @Published var bars: [Float?] = Array(repeating: nil, count: 60)

    init() {
        let dir = FileManager.default.temporaryDirectory
        outputURL = dir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        format = engine.inputNode.outputFormat(forBus: 0)
    }

    func start() {
        Task {
            // Clear bars.
            DispatchQueue.main.async {
                self.bars = Array(repeating: nil, count: 60)
            }
        }

        let dir = FileManager.default.temporaryDirectory
        outputURL = dir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")

        do {
            file = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        } catch {
            print("couldn't create file: \(error)")
            return
        }

        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            try? self.file?.write(from: buffer)

            guard let data = buffer.floatChannelData?[0] else { return }

            let frameLength = Int(buffer.frameLength)
            let bufferPointer = UnsafeBufferPointer(start: data, count: frameLength)
            let samples = Array(bufferPointer)
            let downsampled = stride(from: 0, to: samples.count, by: 10).map { abs(samples[$0]) }
            let maxSample = downsampled.max() ?? 0
            let normalized = min(maxSample * 10, 1.0)  // boost it x10 but cap at 1.0

            self.waveformHistory = normalized
        }

        // Start the timer to update the bars
        if let timer = timer {
            timer.invalidate()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Push the waveform history to the bars and remove the oldest one
            if let waveformHistory = self.waveformHistory {
                self.bars.insert(waveformHistory, at: 0)
                if self.bars.count > self.maxSamples {
                    self.bars.removeLast()
                }
            }
        }

        do {
            try engine.start()
        } catch {
            print("engine didn't start: \(error)")
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        timer?.invalidate()
        timer = nil
    }

    func getOutputURL() -> URL {
        return outputURL
    }
}
