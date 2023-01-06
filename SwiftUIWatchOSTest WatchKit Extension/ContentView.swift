import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject var settings = Settings.shared

    init() {
        settings.engine = .init()

        settings.prepare()
    }

    var body: some View {
        Button("Play Sound") {
            SoundFontHelper.sharedInstance().playSound()

            if !settings.engine.isRunning {
                do {
                    try settings.engine.start()
                } catch {
                    print(error)
                }
            }
        }
    }
}
