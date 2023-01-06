import SwiftUI
import AVFoundation

class Settings: ObservableObject {
    static let shared = Settings()

    var engine: AVAudioEngine!
    var sourceNode: AVAudioSourceNode!
    var wavData: Data!

    func prepare() {
        if let sourceNode = sourceNode {
            engine.detach(sourceNode)
        }

        let mixerNode = engine.mainMixerNode

        let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 1,
            interleaved: false
        )

        guard let audioFormat = audioFormat else {
            return
        }

        sourceNode = AVAudioSourceNode(format: audioFormat) { silence, timeStamp, frameCount, audioBufferList in
            guard let data = SoundFontHelper.sharedInstance().getSound(Int32(frameCount)),
                  let wavData = Self.createWAV(pcmData: data) else {
                return 1
            }

            let documentDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first

            guard let url = documentDirectory?.appendingPathComponent("output.wav") else {
                return 1
            }

            do {
                try wavData.write(to: url)

                let file = try AVAudioFile(forReading: url)

                guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
                    return noErr
                }

                // https://stackoverflow.com/a/34759136/3151675
                try file.read(into: buffer)
                let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: Int(buffer.frameLength)))

                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

                for frame in 0 ..< floatArray.count {
                    let value = floatArray[frame]

                    for buffer in ablPointer {
                        let buf: UnsafeMutableBufferPointer<Float> = .init(buffer)
                        buf[frame] = value
                    }
                }

                return noErr
            } catch {
                print(error)

                return 1
            }
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixerNode, format: audioFormat)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print(error)
        }
    }

    // https://stackoverflow.com/a/63653883/3151675
    @discardableResult
    static func createWAV(pcmData: Data) -> Data? {
        var numChannels: CShort = 1
        let numChannelsInt: CInt = 1
        var bitsPerSample: CShort = 16
        let bitsPerSampleInt: CInt = 16
        var samplingRate: CInt = 44100
        let numOfSamples = CInt(pcmData.count)
        var byteRate = numChannelsInt * bitsPerSampleInt * samplingRate / 8
        var blockAlign = numChannelsInt * bitsPerSampleInt / 8
        var dataSize = numChannelsInt * numOfSamples * bitsPerSampleInt / 8
        var chunkSize: CInt = 16
        var totalSize = 46 + dataSize
        var audioFormat: CShort = 1

        let wavNSData = NSMutableData()
        wavNSData.append("RIFF".cString(using: .ascii) ?? .init(), length: MemoryLayout<CChar>.size * 4)
        wavNSData.append(&totalSize, length: MemoryLayout<CInt>.size)
        wavNSData.append("WAVE".cString(using: .ascii) ?? .init(), length: MemoryLayout<CChar>.size * 4)
        wavNSData.append("fmt ".cString(using: .ascii) ?? .init(), length: MemoryLayout<CChar>.size * 4)
        wavNSData.append(&chunkSize, length: MemoryLayout<CInt>.size)
        wavNSData.append(&audioFormat, length: MemoryLayout<CShort>.size)
        wavNSData.append(&numChannels, length: MemoryLayout<CShort>.size)
        wavNSData.append(&samplingRate, length: MemoryLayout<CInt>.size)
        wavNSData.append(&byteRate, length: MemoryLayout<CInt>.size)
        wavNSData.append(&blockAlign, length: MemoryLayout<CShort>.size)
        wavNSData.append(&bitsPerSample, length: MemoryLayout<CShort>.size)
        wavNSData.append("data".cString(using: .ascii) ?? .init(), length: MemoryLayout<CChar>.size * 4)
        wavNSData.append(&dataSize, length: MemoryLayout<CInt>.size)

        wavNSData.append(pcmData)

        let wavData = Data(referencing: wavNSData)

        return wavData
    }
}
