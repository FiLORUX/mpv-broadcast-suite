# Copilot Instructions for mpv-broadcast-suite

## Project Overview
This suite extends the [mpv](https://mpv.io/) media player for professional broadcast, QC, and post-production workflows. It provides:
- SMPTE-compliant timecode overlays (see `scripts/timecode.lua`)
- Advanced multi-channel audio routing and loudness tools
- Keyboard-driven operation for frame-accurate control

## Architecture & Key Components
- `scripts/` — Lua scripts for mpv, e.g. `timecode.lua` (timecode overlay), `audiomap.lua` (audio routing)
- `mpv.conf`, `input.conf` — mpv configuration and keybindings
- `docs/` — Guides: `KEYBINDINGS.md`, `CUSTOMISATION.md`, `TECHDETAILS.md`, `TROUBLESHOOTING.md`
- `examples/` — Sample configs and usage

## Developer Workflows
- **Install:** Use `install.sh` (Linux/macOS) or `install.ps1` (Windows) to copy configs/scripts to your mpv user directory.
- **Run:** Launch mpv with `mpv your_video.mp4` after installing configs/scripts.
- **Configure:** Edit `mpv.conf`, `input.conf`, and scripts in `scripts/` for custom behaviour. See `docs/CUSTOMISATION.md`.
- **Keybindings:** All major features are accessible via keyboard. Reference `docs/KEYBINDINGS.md` for details.

## Project-Specific Patterns
- **Lua scripting:** All overlays and routing logic are implemented in Lua, using mpv's API (`mp`, `mp.assdraw`).
- **Event-driven design:** Scripts use mpv property observers and events for efficient updates (see `timecode.lua`).
- **Broadcast standards:** Timecode, framerate, and audio handling follow SMPTE and EBU conventions. See `docs/TECHDETAILS.md`.
- **No GUI:** All configuration is via plain-text files and scripts. No graphical interface.

## Integration Points
- **mpv >= 0.35.0 required** (with Lua and libavfilter support)
- Scripts are loaded by mpv from the user's `scripts/` directory
- Config files (`mpv.conf`, `input.conf`) must be placed in the user's mpv config directory

## Examples
- To add a new overlay, create a Lua script in `scripts/` and register it via `mp.add_key_binding`.
- To change timecode display behaviour, edit `scripts/timecode.lua` and reload mpv.

## References
- [README.md](../README.md) — Project overview, install, and usage
- [docs/KEYBINDINGS.md](../docs/KEYBINDINGS.md) — Keyboard controls
- [docs/CUSTOMISATION.md](../docs/CUSTOMISATION.md) — Configuration options
- [docs/TECHDETAILS.md](../docs/TECHDETAILS.md) — Technical standards and implementation

---
For questions about conventions or unclear workflows, consult the relevant file in `docs/` or ask for clarification.