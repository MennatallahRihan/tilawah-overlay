import SwiftUI

struct OverlayMetrics {
    let width: CGFloat
    let height: CGFloat

    var scale: CGFloat {
        min(width / 360, height / 320)
    }

    var activeAyahSize: CGFloat {
        clamped(22 * max(scale, 0.75), min: 16, max: 48)
    }

    var idleAyahSize: CGFloat {
        clamped(activeAyahSize * 0.72, min: 12, max: 32)
    }

    var titleSize: CGFloat {
        clamped(15 * max(scale, 0.8), min: 12, max: 22)
    }

    var captionSize: CGFloat {
        clamped(11 * max(scale, 0.8), min: 9, max: 14)
    }

    var padding: CGFloat {
        clamped(12 * max(scale, 0.7), min: 8, max: 22)
    }

    var ayahSpacing: CGFloat {
        clamped(12 * max(scale, 0.7), min: 8, max: 22)
    }

    private func clamped(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(max, Swift.max(min, value))
    }
}

struct AyahLyricsView: View {
    let session: SurahSession
    let currentAyahNumber: Int?
    let isPlaying: Bool
    let elapsedSeconds: Double
    let durationSeconds: Double
    let onToggle: () -> Void
    let onPrevSurah: () -> Void
    let onNextSurah: () -> Void
    let onSkipAyah: (Int) -> Void
    let onSeek: (Double) -> Void
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onToggleLibrary: () -> Void
    let isLibraryOpen: Bool

    var body: some View {
        GeometryReader { geo in
            let metrics = OverlayMetrics(width: geo.size.width, height: geo.size.height)

            VStack(spacing: metrics.ayahSpacing * 0.55) {
                header(metrics)
                playbackControls(metrics)
                progressBar(metrics)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: metrics.ayahSpacing) {
                            ForEach(session.ayahs) { ayah in
                                let isCurrent = ayah.number == currentAyahNumber
                                Text(ayah.text)
                                    .font(.system(size: isCurrent ? metrics.activeAyahSize : metrics.idleAyahSize, weight: isCurrent ? .semibold : .regular))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.7)
                                    .foregroundStyle(isCurrent ? Color.primary : Color.secondary)
                                    .opacity(isCurrent ? 1 : 0.42)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 4)
                                    .id(ayah.number)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentAyahNumber)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onChange(of: currentAyahNumber) { _, ayah in
                        guard let ayah else { return }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            proxy.scrollTo(ayah, anchor: .center)
                        }
                    }
                }

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .help("Drag any edge or corner to resize")
            }
            .padding(metrics.padding)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    private func header(_ metrics: OverlayMetrics) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onToggleLibrary) {
                Image(systemName: isLibraryOpen ? "sidebar.left" : "line.3.horizontal")
                    .font(.system(size: metrics.titleSize))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(isLibraryOpen ? "Hide list" : "Show surah list")

            VStack(spacing: 2) {
                Text(session.surahName)
                    .font(.system(size: metrics.titleSize, weight: .semibold))
                Text("\(session.reciterName) · \(positionLabel)")
                    .font(.system(size: metrics.captionSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: metrics.titleSize))
                    .foregroundStyle(isFavorite ? Color.pink : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(isFavorite ? "Remove from Favourites" : "Add to Favourites")
        }
    }

    private func playbackControls(_ metrics: OverlayMetrics) -> some View {
        HStack(spacing: 14) {
            Button(action: onPrevSurah) {
                Image(systemName: "backward.end.fill")
            }
            .help("Previous surah")

            Button { onSkipAyah(-1) } label: {
                Image(systemName: "backward.fill")
            }
            .help("Previous ayah")

            Button(action: onToggle) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: max(22, metrics.titleSize + 8)))
            }
            .help(isPlaying ? "Pause" : "Play")

            Button { onSkipAyah(1) } label: {
                Image(systemName: "forward.fill")
            }
            .help("Next ayah")

            Button(action: onNextSurah) {
                Image(systemName: "forward.end.fill")
            }
            .help("Next surah")
        }
        .buttonStyle(.borderless)
        .font(.system(size: metrics.titleSize))
        .foregroundStyle(.primary)
    }

    private func progressBar(_ metrics: OverlayMetrics) -> some View {
        VStack(spacing: 2) {
            Slider(
                value: Binding(
                    get: { elapsedSeconds },
                    set: { onSeek($0) }
                ),
                in: 0 ... max(durationSeconds, 0.1)
            )
            HStack {
                Text(formatTime(elapsedSeconds))
                Spacer()
                Text(formatTime(durationSeconds))
            }
            .font(.system(size: max(9, metrics.captionSize - 1)).monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private var positionLabel: String {
        "Ayah \(currentAyahNumber.map(String.init) ?? "—")"
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct IdleOverlayView: View {
    let statusMessage: String
    let onPlay: () -> Void
    let onToggleLibrary: () -> Void

    var body: some View {
        GeometryReader { geo in
            let metrics = OverlayMetrics(width: geo.size.width, height: geo.size.height)
            VStack(spacing: metrics.ayahSpacing) {
                HStack {
                    Button(action: onToggleLibrary) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Show surah list")
                    Spacer()
                }

                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: max(22, metrics.activeAyahSize)))
                    .foregroundStyle(.secondary)

                Text(statusMessage)
                    .font(.system(size: metrics.idleAyahSize))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.secondary)

                Button("Play", action: onPlay)
                    .buttonStyle(.borderless)
            }
            .padding(metrics.padding)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct LibrarySidebar: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("List", selection: $appState.libraryTab) {
                ForEach(AppState.LibraryTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            TextField("Search surahs", text: $appState.surahSearch)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if appState.visibleLibraryChapters.isEmpty {
                        Text(emptyMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(appState.visibleLibraryChapters) { chapter in
                        Button {
                            appState.selectSurah(chapter.id)
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(chapter.id)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22, alignment: .trailing)
                                Text(chapter.nameSimple)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if appState.favoriteSurahs.contains(chapter.id) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.pink)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(chapter.id == appState.selectedSurah ? Color.accentColor.opacity(0.22) : Color.clear)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
    }

    private var emptyMessage: String {
        if appState.libraryTab == .favourites {
            return "Heart a surah to save it here."
        }
        return "No matching surahs."
    }
}
