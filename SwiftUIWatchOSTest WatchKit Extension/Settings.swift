import SwiftUI
import AVFoundation

class Settings: ObservableObject {
    static let shared = Settings()

    var engine: AVAudioEngine!
    var sourceNode: AVAudioSourceNode!

    func prepare() {

        if let engine = engine,
           let sourceNode = sourceNode {
            engine.detach(sourceNode)
        }

        engine = .init()

        let mixerNode = engine.mainMixerNode

        let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 44100,
            channels: 1,
            interleaved: false
        )

        guard let audioFormat = audioFormat else {
            return
        }

        sourceNode = AVAudioSourceNode(format: audioFormat) { silence, timeStamp, frameCount, audioBufferList in
            guard let data = SoundFontHelper.sharedInstance().getSound(Int32(frameCount)) else {
                return 1
            }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            data.withUnsafeBytes { (intPointer: UnsafePointer<Int16>) in
                for index in 0 ..< Int(frameCount) {
                    let value = intPointer[index]

                    // Set the same value on all channels (due to the inputFormat, there's only one channel though).
                    for buffer in ablPointer {
                        let buf: UnsafeMutableBufferPointer<Int16> = UnsafeMutableBufferPointer(buffer)
                        buf[index] = value
                    }
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixerNode, format: audioFormat)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print(error)
        }
    }
}
