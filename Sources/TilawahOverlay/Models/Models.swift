import Foundation

enum MediaSource: String, Sendable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case unknown = "Unknown"
}

struct NowPlayingInfo: Equatable, Sendable {
    var source: MediaSource
    var title: String
    var artist: String
    var elapsedSeconds: Double
    var durationSeconds: Double
    var isPlaying: Bool
    var sampledAt: Date

    static let empty = NowPlayingInfo(
        source: .unknown,
        title: "",
        artist: "",
        elapsedSeconds: 0,
        durationSeconds: 0,
        isPlaying: false,
        sampledAt: .distantPast
    )

    func interpolatedElapsed(at date: Date = Date()) -> Double {
        guard isPlaying else { return elapsedSeconds }
        let drifted = elapsedSeconds + date.timeIntervalSince(sampledAt)
        if durationSeconds > 0 {
            return min(max(0, drifted), durationSeconds)
        }
        return max(0, drifted)
    }
}

struct Ayah: Identifiable, Equatable, Sendable {
    let number: Int
    let text: String
    var isBismillah: Bool { number == Self.bismillahNumber }

    static let bismillahNumber = 0
    static let bismillahText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"

    var id: Int { number }
}

struct SurahSession: Equatable, Sendable {
    var surahNumber: Int
    var surahName: String
    var reciterName: String
    var recitationID: Int
    var audioURL: URL
    var ayahs: [Ayah]
    var ayahTimings: [AyahTiming]
    var timingDurationMs: Int
}

struct AyahTiming: Equatable, Sendable {
    let ayahNumber: Int
    let startMs: Int
    let endMs: Int
}

struct OverlayState: Equatable, Sendable {
    var session: SurahSession?
    var currentAyahNumber: Int?
    var nowPlaying: NowPlayingInfo
    var statusMessage: String
    var userOffsetMs: Int
    var autoOffsetMs: Int
    var isPlaying: Bool
    var elapsedSeconds: Double
    var durationSeconds: Double

    static let idle = OverlayState(
        session: nil,
        currentAyahNumber: nil,
        nowPlaying: .empty,
        statusMessage: "Choose a surah to play",
        userOffsetMs: 0,
        autoOffsetMs: 0,
        isPlaying: false,
        elapsedSeconds: 0,
        durationSeconds: 0
    )
}
