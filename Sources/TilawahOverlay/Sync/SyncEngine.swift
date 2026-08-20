import Foundation

enum SyncEngine {
    static func currentAyah(in session: SurahSession, elapsedMs: Int) -> Int? {
        guard !session.ayahTimings.isEmpty else { return session.ayahs.first?.number }

        var active: Int?
        for timing in session.ayahTimings {
            if elapsedMs >= timing.startMs {
                active = timing.ayahNumber
            } else {
                break
            }
        }
        return active
    }
}
