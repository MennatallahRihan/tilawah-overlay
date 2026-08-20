# Tilawah Overlay

A macOS menu bar HUD that plays Quran recitation and highlights **ayah-by-ayah** Arabic text in a floating, resizable overlay.

Audio and timestamps come from the same [Quran.com / QuranicAudio](https://quran.com/) gapless files, so the lyrics lock to the voice.

## Features

- Always-on-top overlay (does not steal focus)
- In-app playback (Mishari Alafasy by default, other reciters in the menu)
- Ayah highlight + auto-scroll, including basmala
- Resizable panel; text scales with the window

Apple Music / Spotify follow-along is in the repo but **disabled** for now (see `NowPlayingMonitor`).

## Requirements

- macOS 14+
- Network access (streams recitation MP3s from QuranicAudio)

## Build & run

```bash
cd tilawah-overlay
./scripts/run.sh
```

A floating panel opens. Use **Play** on the overlay, or the menu bar book icon to pick a surah / reciter.

Do **not** run `.build/debug/TilawahOverlay` in the terminal — that binary has no app bundle.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## License

MIT — see [LICENSE](LICENSE).
