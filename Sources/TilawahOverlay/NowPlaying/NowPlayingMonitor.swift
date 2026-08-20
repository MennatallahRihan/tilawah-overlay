import Foundation

/// Hidden for now: Apple Music / Spotify now-playing.
/// Re-enable from `AppState.start()` when external follow-along returns.
@MainActor
final class NowPlayingMonitor: ObservableObject {
    @Published private(set) var info: NowPlayingInfo = .empty

    private var task: Task<Void, Never>?
    private let sources: [MediaSource] = [.appleMusic, .spotify]

    func start() {
        // Disabled: in-app QuranicAudio playback is the active source.
        /*
        guard task == nil else { return }
        task = Task.detached(priority: .utility) { [sources] in
            while !Task.isCancelled {
                var next = NowPlayingInfo.empty
                for source in sources {
                    if Task.isCancelled { return }
                    if let playing = AppleScriptBridge.nowPlaying(from: source) {
                        next = playing
                        break
                    }
                }
                await MainActor.run {
                    self.info = next
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        */
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
