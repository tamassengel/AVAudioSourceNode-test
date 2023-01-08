import SwiftUI
import AVFoundation

class Settings: ObservableObject {
    static let shared = Settings()

    var engine: AVAudioEngine!
    var sourceNode: AVAudioSourceNode!

    var tinySoundFont: OpaquePointer!

    func prepare() {
        let soundFontPath = Bundle.main.path(forResource: "GMGSx", ofType: "sf2")
        tinySoundFont = tsf_load_filename(soundFontPath)
        tsf_set_output(tinySoundFont, TSF_MONO, 44100, 0)

        setUpSound()
    }

    func setUpSound() {
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
            guard let data = self.getSound(length: Int(frameCount)) else {
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

    func playSound() {
        tsf_note_on(tinySoundFont, 0, 60, 1)
    }

    func getSound(length: Int) -> Data? {
        let array = [Int16]()
        var storage = UnsafeMutablePointer<Int16>.allocate(capacity: length)
        storage.initialize(from: array, count: length)

        tsf_render_short(tinySoundFont, storage, Int32(length), 0)
        let data = Data(bytes: storage, count: length)

        storage.deallocate()

        return data
    }
}
