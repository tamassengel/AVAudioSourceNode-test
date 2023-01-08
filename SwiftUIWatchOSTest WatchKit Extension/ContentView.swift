import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject var settings = Settings.shared

    init() {
        settings.prepare()
    }

    var body: some View {
        Button("Play Sound") {
            Settings.shared.playSound()

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
