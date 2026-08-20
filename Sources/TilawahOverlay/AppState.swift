import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var overlay = OverlayState.idle
    @Published private(set) var chapters: [ChapterInfo] = []
    @Published private(set) var reciters: [ReciterInfo] = []
    @Published var selectedSurah = 1
    @Published var selectedReciterID = 7
    @Published private(set) var favoriteSurahs: [Int] = []
    @Published var isLibraryOpen = false
    @Published var libraryTab: LibraryTab = .favourites
    @Published var surahSearch = ""

    let player = RecitationPlayer()
    private let quranAPI = QuranAPIClient()
    private let defaults = UserDefaults.standard

    // Hidden for now: Apple Music / Spotify follow-along.
    // let nowPlayingMonitor = NowPlayingMonitor()

    private var loadTask: Task<SurahSession, Error>?

    private let favoritesKey = "favoriteSurahs"
    private let libraryOpenKey = "libraryOpen"

    enum LibraryTab: String, CaseIterable, Identifiable {
        case favourites
        case all

        var id: String { rawValue }
        var title: String {
            switch self {
            case .favourites: "Favourites"
            case .all: "All"
            }
        }
    }

    var selectedReciterName: String {
        reciters.first(where: { $0.id == selectedReciterID })?.name ?? "Mishari Rashid al-Afasy"
    }

    var favoriteChapters: [ChapterInfo] {
        favoriteSurahs.compactMap { id in chapters.first(where: { $0.id == id }) }
    }

    var isCurrentFavorite: Bool {
        favoriteSurahs.contains(selectedSurah)
    }

    var visibleLibraryChapters: [ChapterInfo] {
        let query = surahSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let source: [ChapterInfo]
        switch libraryTab {
        case .favourites:
            source = favoriteChapters
        case .all:
            source = chapters
        }
        guard !query.isEmpty else { return source }
        return source.filter {
            $0.nameSimple.lowercased().contains(query) || String($0.id).contains(query)
        }
    }

    func start() {
        favoriteSurahs = defaults.array(forKey: favoritesKey) as? [Int] ?? []
        isLibraryOpen = defaults.bool(forKey: libraryOpenKey)
        // nowPlayingMonitor.start()
        player.onFinished = { [weak self] in
            self?.playNextSurah()
        }
        Task {
            await loadCatalog()
            await loadAndPlay(surahNumber: defaults.integer(forKey: "lastSurah").clampedSurah, autoplay: false)
        }
    }

    func stop() {
        // nowPlayingMonitor.stop()
        loadTask?.cancel()
        player.stop()
    }

    func refresh() async {
        overlay.isPlaying = player.isPlaying
        overlay.elapsedSeconds = player.elapsedSeconds
        overlay.durationSeconds = player.durationSeconds

        guard let session = overlay.session else { return }
        let elapsedMs = Int(player.elapsedSeconds * 1000)
        overlay.currentAyahNumber = SyncEngine.currentAyah(in: session, elapsedMs: elapsedMs)
        overlay.statusMessage = player.isPlaying ? "Playing \(session.surahName)" : "Paused · \(session.surahName)"
    }

    func togglePlayback() {
        player.toggle()
    }

    func skipAyah(by delta: Int) {
        guard let session = overlay.session else { return }
        let current = overlay.currentAyahNumber ?? 1
        let numbers = session.ayahs.map(\.number)
        guard let index = numbers.firstIndex(of: current) else { return }
        let nextIndex = min(max(0, index + delta), numbers.count - 1)
        let ayah = numbers[nextIndex]
        if let timing = session.ayahTimings.first(where: { $0.ayahNumber == ayah }) {
            player.seek(to: Double(timing.startMs) / 1000)
            if !player.isPlaying { player.play() }
        }
    }

    func playPreviousSurah() {
        Task { await loadAndPlay(surahNumber: selectedSurah - 1, autoplay: true) }
    }

    func playNextSurah() {
        Task { await loadAndPlay(surahNumber: selectedSurah + 1, autoplay: true) }
    }

    func selectSurah(_ number: Int) {
        Task { await loadAndPlay(surahNumber: number, autoplay: true) }
    }

    func selectReciter(_ id: Int) {
        selectedReciterID = id
        Task { await loadAndPlay(surahNumber: selectedSurah, autoplay: player.isPlaying) }
    }

    func seek(to seconds: Double) {
        player.seek(to: seconds)
    }

    func toggleFavorite() {
        toggleFavorite(surah: selectedSurah)
    }

    func toggleFavorite(surah: Int) {
        if let index = favoriteSurahs.firstIndex(of: surah) {
            favoriteSurahs.remove(at: index)
        } else {
            favoriteSurahs.insert(surah, at: 0)
        }
        defaults.set(favoriteSurahs, forKey: favoritesKey)
    }

    func toggleLibrary() {
        isLibraryOpen.toggle()
        defaults.set(isLibraryOpen, forKey: libraryOpenKey)
    }

    private func loadCatalog() async {
        do {
            async let chapterList = quranAPI.fetchChapters()
            async let reciterList = quranAPI.fetchReciters()
            chapters = try await chapterList
            reciters = try await reciterList
        } catch {
            overlay.statusMessage = error.localizedDescription
        }
    }

    private func loadAndPlay(surahNumber: Int, autoplay: Bool) async {
        let surah = surahNumber.clampedSurah
        selectedSurah = surah
        defaults.set(surah, forKey: "lastSurah")
        loadTask?.cancel()
        overlay.statusMessage = "Loading Surah \(surah)…"

        let reciterName = selectedReciterName
        let recitationID = selectedReciterID
        let task = Task {
            try await quranAPI.loadSession(
                surahNumber: surah,
                recitationID: recitationID,
                reciterName: reciterName
            )
        }
        loadTask = task

        do {
            let session = try await task.value
            overlay.session = session
            overlay.userOffsetMs = 0
            overlay.autoOffsetMs = 0
            overlay.statusMessage = "Ready · \(session.surahName)"
            player.load(url: session.audioURL)
            if autoplay {
                player.play()
            }
        } catch is CancellationError {
            return
        } catch {
            overlay.session = nil
            overlay.currentAyahNumber = nil
            overlay.statusMessage = error.localizedDescription
        }
    }
}

private extension Int {
    var clampedSurah: Int {
        let value = self == 0 ? 1 : self
        return Swift.min(114, Swift.max(1, value))
    }
}
