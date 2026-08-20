# Tilawah Overlay — Architecture

Personal macOS menu bar HUD: plays Quran recitation in-app and highlights Arabic ayahs in a floating overlay.

External Apple Music / Spotify follow-along is implemented but disabled (`NowPlayingMonitor.start()` is commented out).

## Scope (v1)

| Decision | Choice |
|---|---|
| Platform | macOS 14+ |
| Sync granularity | Ayah-by-ayah |
| Text | Arabic only (Uthmani script) |
| Sources | Apple Music, Spotify |
| Distribution | Open source, direct build (not App Store) |

Out of scope for v1: word-by-word highlight, translations, YouTube live audio, iOS.

## Components

```
MenuBarExtra ──▶ AppState (ObservableObject)
                      │
         ┌────────────┼────────────┐
         ▼            ▼            ▼
  NowPlayingMonitor  SyncEngine  OverlayPanelController
         │            │            │
  AppleScriptBridge   │       NSPanel + AyahLyricsView
         │            │
         ▼            ▼
   Music / Spotify   QuranAPIClient ──▶ api.quran.com
                      QuranCache (SQLite, later)
```

### Now Playing

Reads track title, artist (reciter), elapsed time, and duration via AppleScript (JXA). Requires **Automation** permission for Music and/or Spotify in System Settings.

macOS 15.4+ restricts MediaRemote to Apple-signed processes. v1 uses AppleScript; v1.5 may add a MediaRemote helper binary (see [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter)).

### Track matching

Parse metadata into `(surahNumber, reciterID?)`:

- Title patterns: `Surah Al-Kahf`, `Al-Kahf`, `018`, `سورة الكهف`
- Artist field → reciter slug for timing lookup
- Fuzzy match against a bundled reciter alias table

When matching fails, show a manual surah picker in the menu bar.

### Sync engine

Playback uses Quran.com **gapless chapter MP3s** (QuranicAudio) plus the timestamps that belong to those files:

```
GET /api/v4/chapter_recitations/{reciter}/{chapter}?segments=true
```

```
elapsedMs = AVPlayer.currentTime
currentAyah = ayah whose [startMs, endMs) contains elapsedMs
```

No stretching or intro guessing. Apple Music/Spotify mapping remains in git under `Sources/TilawahOverlay/NowPlaying/` but is not started.

### Overlay UI

`NSPanel` with:

- `.nonactivatingPanel` — does not steal focus
- `.floating` level — stays above other windows
- `.canJoinAllSpaces`, `.fullScreenAuxiliary` — visible in full screen

SwiftUI `AyahLyricsView`: previous / **current** / next ayah with opacity gradient and spring scroll on ayah change.

## Data sources

- **Arabic text + ayah timings**: `GET /api/v4/verses/by_chapter/{n}?fields=text_uthmani&audio={recitation_id}` (EveryAyah word segments)
- **Chapter metadata**: `GET /api/v4/chapters/{n}` (`bismillah_pre`, name)
- **Reciters**: `GET /api/v4/resources/recitations`

Cache surah text and timings locally after first fetch.

## Roadmap

### Phase 0 — Spike (current)
- [x] Repo scaffold
- [ ] Floating overlay panel
- [ ] Apple Music now playing
- [ ] One surah ayah sync end-to-end

### Phase 1 — MVP
- [ ] Spotify support
- [ ] Reciter matching for top reciters
- [ ] All 114 surahs
- [ ] Local cache
- [ ] Manual surah override

### Phase 2 — YouTube & polish
- [ ] Manual mode for unknown sources
- [ ] Live audio + Quranic ASR (research spike)
- [ ] Browser extension hint for YouTube titles

## Permissions

| Permission | Why |
|---|---|
| Automation (Music, Spotify) | Read now playing + playback position |
| Screen Recording | Only if live audio mode is added (v2) |

## Build

```bash
swift build
.build/debug/TilawahOverlay
```

For a proper `.app` bundle with `LSUIElement` (no Dock icon), use the Xcode project (added in Phase 1) or `scripts/build-app.sh`.
