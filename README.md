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

## Download (recommended)

Grab the latest **`.dmg`** from [Releases](https://github.com/MennatallahRihan/tilawah-overlay/releases):

1. Open the `.dmg`
2. Drag **Tilawah Overlay** into **Applications**
3. Open it from Applications, Spotlight, or the Dock
4. Quit from the menu bar book icon

If macOS says the app can’t be opened (unsigned build), right‑click the app → **Open** → **Open**.

## Install from source

```bash
cd tilawah-overlay
./scripts/install.sh
```

Copies **Tilawah Overlay.app** into `/Applications`. Re-run after you change the code.

## Package a Release `.dmg`

```bash
./scripts/package-dmg.sh
```

Writes `dist/Tilawah-Overlay-<version>.dmg`. Attach it to a GitHub Release (UI or `gh release create` — the script prints an example).

## Build & run (dev)

```bash
cd tilawah-overlay
./scripts/run.sh
```

Rebuilds a debug `.app` under `.build/` and opens it. Use this while iterating.

Do **not** run `.build/debug/TilawahOverlay` or `.build/release/TilawahOverlay` in the terminal — those binaries have no app bundle.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## License

MIT — see [LICENSE](LICENSE).
