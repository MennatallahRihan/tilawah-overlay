import Foundation

/// Hidden for now: Apple Music / Spotify AppleScript bridge.
/// Used only by `NowPlayingMonitor` when external follow-along is re-enabled.
enum AppleScriptBridge {
    static func nowPlaying(from source: MediaSource) -> NowPlayingInfo? {
        let processName: String
        let script: String

        switch source {
        case .appleMusic:
            processName = "Music"
            script = """
            function isRunning(name) {
              const se = Application("System Events");
              return se.applicationProcesses.whose({ name: name })().length > 0;
            }
            if (!isRunning("Music")) { JSON.stringify({ playing: false }); }
            else {
              const app = Application("Music");
              if (!app.running() || app.playerState() !== "playing") {
                JSON.stringify({ playing: false });
              } else {
                const t = app.currentTrack;
                JSON.stringify({
                  playing: true,
                  title: t.name(),
                  artist: t.artist(),
                  elapsed: app.playerPosition(),
                  duration: t.duration()
                });
              }
            }
            """
        case .spotify:
            processName = "Spotify"
            script = """
            function isRunning(name) {
              const se = Application("System Events");
              return se.applicationProcesses.whose({ name: name })().length > 0;
            }
            if (!isRunning("Spotify")) { JSON.stringify({ playing: false }); }
            else {
              const app = Application("Spotify");
              if (!app.running() || String(app.playerState()).includes("paused")) {
                JSON.stringify({ playing: false });
              } else {
                const t = app.currentTrack;
                JSON.stringify({
                  playing: true,
                  title: t.name(),
                  artist: t.artist(),
                  elapsed: app.playerPosition(),
                  duration: t.duration() / 1000
                });
              }
            }
            """
        case .unknown:
            return nil
        }

        _ = processName

        guard
            let json = runJXA(script),
            let data = json.data(using: .utf8),
            let payload = try? JSONDecoder().decode(JXANowPlaying.self, from: data),
            payload.playing == true,
            let title = payload.title
        else {
            return nil
        }

        return NowPlayingInfo(
            source: source,
            title: title,
            artist: payload.artist ?? "",
            elapsedSeconds: payload.elapsed ?? 0,
            durationSeconds: payload.duration ?? 0,
            isPlaying: true,
            sampledAt: Date()
        )
    }

    private static func runJXA(_ source: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "JavaScript", "-e", source]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            return nil
        }

        let deadline = Date().addingTimeInterval(2)
        while process.isRunning, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        if process.isRunning {
            process.terminate()
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return output?.isEmpty == false ? output : nil
    }
}

private struct JXANowPlaying: Decodable {
    let playing: Bool
    let title: String?
    let artist: String?
    let elapsed: Double?
    let duration: Double?
}
