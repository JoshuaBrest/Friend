import AudioKit
import Foundation
import SwiftWhisper

public enum WhisperModel {
    private class SharedWhisperModel {
        public static let shared = SharedWhisperModel()
        public let whisper: Whisper?

        private init() {
            guard
                let modelURL = Bundle.main.url(
                    forResource: "Resources/tiny", withExtension: "bin")
            else {
                print("Model file not found...")
                whisper = nil
                return
            }
            self.whisper = Whisper(fromFileURL: modelURL)
        }
    }

    static func convertFormat(_ url: URL) async -> Result<[Float], Error> {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        let converter = FormatConverter(inputURL: url, outputURL: tempURL, options: options)

        let conversionResult = await withCheckedContinuation {
            (continuation: CheckedContinuation<Result<Void, Error>, Never>) in
            converter.start { error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(()))
                }
            }
        }

        switch conversionResult {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }

        guard let data = try? Data(contentsOf: tempURL) else {
            return .failure(NSError(domain: "read-fail", code: 1))
        }

        let floats: [Float] = stride(from: 44, to: data.count, by: 2).map {
            data[$0..<$0 + 2].withUnsafeBytes {
                let short = Int16(littleEndian: $0.load(as: Int16.self))
                return max(-1.0, min(Float(short) / 32767.0, 1.0))
            }
        }

        try? FileManager.default.removeItem(at: tempURL)

        return .success(floats)
    }

    static func transcribe(_ audio: URL) async -> String? {
        let result = await WhisperModel.convertFormat(audio)
        // Delete the file after conversion
        try? FileManager.default.removeItem(at: audio)

        if case .failure(let error) = result {
            print("Error converting file: \(error)")
            return nil
        }

        guard case .success(let floats) = result else {
            return nil
        }

        guard let whisper = SharedWhisperModel.shared.whisper else {
            print("Whisper model not loaded")
            return nil
        }

        // Transcribe the audio
        let segments = try? await whisper.transcribe(audioFrames: floats)
        guard let segments else {
            print("Transcription failed")
            return nil
        }

        // Join the segments into a single string
        let transcription = segments.map { $0.text }.joined(separator: " ")

        // Submit the transcription
        return transcription
    }
}
