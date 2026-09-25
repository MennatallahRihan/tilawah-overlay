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

## Install (double-click app)

```bash
cd tilawah-overlay
./scripts/install.sh
```

Copies **Tilawah Overlay.app** into `/Applications`. Open it from Applications, Spotlight, or the Dock. Quit from the menu bar book icon. Re-run `install.sh` after you change the code.

## Build & run (dev)

```bash
cd tilawah-overlay
./scripts/run.sh
```

Rebuilds a debug `.app` under `.build/` and opens it. Use this while iterating; use `install.sh` for daily launch.

Do **not** run `.build/debug/TilawahOverlay` or `.build/release/TilawahOverlay` in the terminal — those binaries have no app bundle.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## License

MIT — see [LICENSE](LICENSE).
