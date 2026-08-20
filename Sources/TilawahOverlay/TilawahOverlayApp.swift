import AppKit
import SwiftUI

@main
struct TilawahOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Tilawah", systemImage: "text.book.closed.fill") {
            MenuBarView()
                .environmentObject(appDelegate.appState)
                .environmentObject(appDelegate)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let overlayController = OverlayPanelController()
    let appState = AppState()
    private var refreshTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        Self.assertSurahMatching()
        #endif
        NSApp.setActivationPolicy(.accessory)
        appState.start()
        overlayController.show {
            OverlayRootView().environmentObject(appState)
        }
        startRefreshLoop()
    }

    #if DEBUG
    private static func assertSurahMatching() {
        let cases: [(String, Int)] = [
            ("Al Anbya'a", 21),
            ("Al-Anbya", 21),
            ("Surah Al-Anbiya", 21),
            ("The Prophets", 21),
            ("Surah Al-Kahf", 18),
            ("Ya-Sin", 36),
            ("Yaseen", 36),
            ("An-Nasr", 110),
            ("An-Nas", 114),
            ("Al-Fatihah", 1),
            ("021 Al Anbya", 21),
        ]
        for (title, expected) in cases {
            let actual = SurahMatcher.surahNumber(from: title)
            assert(actual == expected, "Expected \(title) -> \(expected), got \(String(describing: actual))")
        }
    }
    #endif

    func applicationWillTerminate(_ notification: Notification) {
        refreshTask?.cancel()
        appState.stop()
    }

    func startRefreshLoop() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.appState.refresh()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}

struct OverlayRootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            if appState.isLibraryOpen {
                LibrarySidebar()
                    .frame(width: 200)
                Divider()
            }

            Group {
                if let session = appState.overlay.session {
                    AyahLyricsView(
                        session: session,
                        currentAyahNumber: appState.overlay.currentAyahNumber,
                        isPlaying: appState.overlay.isPlaying,
                        elapsedSeconds: appState.overlay.elapsedSeconds,
                        durationSeconds: appState.overlay.durationSeconds,
                        onToggle: { appState.togglePlayback() },
                        onPrevSurah: { appState.playPreviousSurah() },
                        onNextSurah: { appState.playNextSurah() },
                        onSkipAyah: { appState.skipAyah(by: $0) },
                        onSeek: { appState.seek(to: $0) },
                        isFavorite: appState.isCurrentFavorite,
                        onToggleFavorite: { appState.toggleFavorite() },
                        onToggleLibrary: { appState.toggleLibrary() },
                        isLibraryOpen: appState.isLibraryOpen
                    )
                } else {
                    IdleOverlayView(
                        statusMessage: appState.overlay.statusMessage,
                        onPlay: { appState.selectSurah(appState.selectedSurah) },
                        onToggleLibrary: { appState.toggleLibrary() }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appDelegate: AppDelegate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let session = appState.overlay.session {
                Text(session.surahName)
                    .font(.headline)
                Text(session.reciterName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(appState.overlay.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(appState.overlay.isPlaying ? "Pause" : "Play") {
                appState.togglePlayback()
            }

            if appState.overlay.session != nil {
                Button(appState.isCurrentFavorite ? "Remove from Favourites" : "Add to Favourites") {
                    appState.toggleFavorite()
                }
            }

            Divider()

            Menu("Favourites") {
                if appState.favoriteChapters.isEmpty {
                    Text("No favourites yet")
                } else {
                    ForEach(appState.favoriteChapters) { chapter in
                        Button("\(chapter.id). \(chapter.nameSimple)") {
                            appState.selectSurah(chapter.id)
                        }
                    }
                }
            }

            Menu("Surah") {
                ForEach(appState.chapters) { chapter in
                    Button("\(chapter.id). \(chapter.nameSimple)") {
                        appState.selectSurah(chapter.id)
                    }
                }
            }

            if !appState.reciters.isEmpty {
                Menu("Reciter") {
                    ForEach(appState.reciters) { reciter in
                        Button(reciterLabel(reciter)) {
                            appState.selectReciter(reciter.id)
                        }
                    }
                }
            }

            Divider()

            Button(appDelegate.overlayController.isVisible ? "Hide Overlay" : "Show Overlay") {
                appDelegate.overlayController.toggle {
                    OverlayRootView().environmentObject(appState)
                }
            }

            Button(appState.isLibraryOpen ? "Hide Surah List" : "Show Surah List") {
                appState.toggleLibrary()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
        .frame(width: 280)
    }

    private func reciterLabel(_ reciter: ReciterInfo) -> String {
        if let style = reciter.style, !style.isEmpty, style != "None" {
            return "\(reciter.name) (\(style))"
        }
        return reciter.name
    }
}
