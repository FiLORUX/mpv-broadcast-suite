# mpv Broadcast Suite  
### Precision Tools for Modern Broadcast Workflows  

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![mpv ≥ 0.35 Required](https://img.shields.io/badge/mpv-0.35%2B-informational)](https://mpv.io/installation/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)]()

---

**mpv Broadcast Suite** brings the legendary *mpv* playback core — born from the MPlayer lineage - into a professional broadcast context.  
Designed for engineers who grew up with waveform monitors, colour bars and baseband matrices - yet demand today's precision, scripting power and open workflows.  

Might suit broadcast engineers, QC ops and post-production. Features broadcast-style timecode display, quite advanced multi-channel audio routing, and loudness compliance tooling.

> Built for those who never stopped caring about frame accuracy.  

---

## 📺 Features

### Timecode & Monitoring
- **Broadcast-Style Timecode Display** - Large, centered SMPTE timecode with frame-accurate display
- **Drop-Frame Support** - Proper DF/NDF handling for all NTSC framerates (23.976, 29.97, 59.94, 119.88)
- **Progress Visualisation** - Clean progress bar showing file position
- **Real-Time Metadata** - Elapsed time, countdown timer, FPS indicator, duration display
- **Multiple Display Modes** - Full overlay, TC-only, minimal, and off modes

### Audio Management
- **Multi-Channel Routing** - Flexible channel selection for 8/16-channel embedded audio
- **Stereo Pair Selection** - Direct access to CH1+2, CH3+4, up to CH15+16
- **Solo Monitoring** - Monitor individual channels in isolation (mono→stereo)
- **Intelligent Downmix** - RMS-normalised all-channel summation prevents clipping
- **Loudness Compliance** - Built-in EBU R128, ATSC A/85, and podcast normalisation
- **Visual Feedback** - On-screen confirmation of routing changes

### Quality Control Tools
- **Frame-Accurate Seeking** - Precise frame-by-frame navigation
- **High-Quality Screenshots** - Lossless PNG capture with customisable naming
- **Video Inspection** - Zoom, pan, and deinterlacing controls
- **Metadata Display** - Quick access to codec, resolution, and audio parameters
- **Playback Control** - Variable speed, looping, and A-B repeat functionality

---

## 📋 Requirements

- **mpv 0.35.0+** (compiled with Lua and libavfilter support)
- **Operating System**: Linux, macOS, or Windows
- **Optional**: GPU with hardware decode support for improved performance

---

## 🚀 Quick Start

### Installation

**Linux/macOS:**
```bash
# Clone repository
git clone https://github.com/FiLORUX/mpv-broadcast-suite.git
cd mpv-broadcast-suite

# Run installer
chmod +x install.sh
./install.sh
```

**Windows (PowerShell):**
```powershell
# Clone repository
git clone https://github.com/FiLORUX/mpv-broadcast-suite.git
cd mpv-broadcast-suite

# Run installer
.\install.ps1
```

**Manual Installation:**
```bash
# Copy files to mpv config directory
cp mpv.conf ~/.config/mpv/
cp input.conf ~/.config/mpv/
cp scripts/*.lua ~/.config/mpv/scripts/
```

### Verification

Launch mpv with any video file:
```bash
mpv your_video.mp4
```

You should see:
- Large timecode display centred at bottom of screen
- Information overlay in top-left corner
- Green progress bar beneath timecode

---

## ⌨️ Keybindings

All core functions are accessible from the keyboard — designed for operators who prefer precision over menus.

→ [Full reference: docs/KEYBINDINGS.md](docs/KEYBINDINGS.md)

---

## 🎨 Customisation

Every display and routing element can be adjusted through plain-text Lua configuration.  
No GUI layers, no hidden logic — just direct control.

→ [Configuration guide: docs/CUSTOMISATION.md](docs/CUSTOMISATION.md)

---

## 🔧 Technical Details

Framerates, loudness, and multi-channel routing follow established broadcast standards.  
No reinvention, only careful implementation.

→ [Technical reference: docs/TECHDETAILS.md](docs/TECHDETAILS.md)

---

## 📁 Repository Structure

```
mpv-broadcast-suite/
├── README.md                  # Primary documentation and overview
├── LICENSE                    # MIT License
├── CONTRIBUTING.md            # Contribution guidelines
├── .gitignore                 # Git ignore rules
├── install.sh                 # Installation script (Linux/macOS)
├── install.ps1                # Installation script (Windows)
├── mpv.conf                   # Main mpv configuration
├── input.conf                 # Keyboard bindings
├── scripts/
│   ├── timecode.lua           # Broadcast-style timecode display
│   └── audiomap.lua           # Multi-channel audio routing and loudness control
├── docs/
│   ├── KEYBINDINGS.md         # Keyboard reference and operator shortcuts
│   ├── CUSTOMISATION.md       # Lua configuration and display options
│   ├── TECHDETAILS.md         # Framerates, audio formats and loudness standards
│   ├── ADVANCED.md            # Advanced configuration and automation
│   └── TROUBLESHOOTING.md     # Common issues and practical fixes
└── examples/
    ├── ffmpeg_commands.md     # Useful FFmpeg commands for broadcast pipelines
    └── sample_profiles.conf   # Example mpv profile presets
```

---

## 🐛 Troubleshooting  — Quick Reference

Common first-line fixes for typical playback or routing issues.  
For in-depth analysis, platform-specific cases, and extended logs, see  
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

### Timecode Not Visible
**Symptom:** No timecode appears when playing file  
**Solution:** Press `t` to cycle display modes (may be set to 'off')  
**Verify:** Check that `timecode.lua` exists in `scripts/` directory

### Audio Routing Ineffective
**Symptom:** Pressing `Ctrl+1-8` has no effect  
**Solution:** Press `Ctrl+i` to verify channel count. If file reports "2 channels", it's already stereo—routing not needed  
**Note:** For files with multiple audio **tracks** (not channels), use `#` to select the track first, then use `Ctrl+1-8` for channel routing within that track

### Drop-Frame Timecode Incorrect
**Symptom:** Timecode appears wrong or doesn't match external reference  
**Solution:** Press `i` to verify actual framerate. Drop-frame only applies to NTSC-derived rates (~23.976, ~29.97, ~59.94)  
**Debug:** Edit `timecode.lua` and adjust tolerance values in `get_fps_info()` if framerate detection is incorrect

### Loudness Filter Causes Performance Issues
**Symptom:** Playback stutters when loudness normalisation enabled  
**Solution:** Loudness filtering is CPU-intensive. Press `Ctrl+l` to cycle to "none" on older hardware  
**Alternative:** Use offline loudness normalisation with dedicated tools for critical listening

### Multiple Audio Tracks Confusion
**Symptom:** Cannot access expected channels  
**Solution:** Distinguish between **tracks** (separate audio streams) and **channels** (within a track):
- Use `#` to cycle between tracks
- Use `Ctrl+1-8` to route channels within the active track
- Press `Ctrl+i` to see track count and channel layout

---

## 🤝 Contributing

Contributions are welcome! This project aims to serve the broadcast engineering community with reliable, professional tooling.

### Development Guidelines

1. **Code Style:** Follow existing Lua conventions with British English spelling in comments
2. **Testing:** Test changes across Linux, macOS, and Windows before submitting
3. **Documentation:** Update README.md and inline comments for any user-facing changes
4. **Commit Messages:** Use clear, descriptive commit messages in present tense

### Reporting Issues

When reporting bugs, please include:
- mpv version (`mpv --version`)
- Operating system and version
- File format and codec information
- Steps to reproduce
- Expected vs. actual behaviour

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

**Third-Party Components:**
- mpv player: GPL-2.0+ ([mpv.io](https://mpv.io))
- FFmpeg libavfilter: LGPL-2.1+ / GPL-2.0+ ([ffmpeg.org](https://ffmpeg.org))

---

## Get mpv (required)

<details>
<summary>Windows</summary>

- Latest community build:
  - GitHub: https://github.com/shinchiro/mpv-winbuild-cmake/releases/latest
  - SourceForge (direct “latest”): https://sourceforge.net/projects/mpv-player-windows/files/

Unpack and run `mpv.exe`. User configuration lives in
%APPDATA%\mpv\  (create if missing).
</details>

<details>
<summary>macOS</summary>

- Homebrew (recommended):

    brew install mpv

Alternative builds and notes: https://mpv.io/installation/
</details>

<details>
<summary>Linux</summary>

Install via your distribution:

    # Debian / Ubuntu
    sudo apt install mpv
    # Fedora
    sudo dnf install mpv
    # Arch
    sudo pacman -S mpv

Further guidance: https://mpv.io/installation/
</details>

---

## 📦 Install this suite

Linux / macOS:

    git clone https://github.com/FiLORUX/mpv-broadcast-suite.git
    cd mpv-broadcast-suite && chmod +x install.sh && ./install.sh

Windows (PowerShell 5+):

    git clone https://github.com/FiLORUX/mpv-broadcast-suite.git
    cd mpv-broadcast-suite; .\install.ps1

The installer copies `mpv.conf`, `input.conf`, and `scripts/` to your user mpv configuration directory. No binaries are included.

---

## 🔄 Optional: fetch latest platform builds from scripts

If you prefer fully automated set-up, the provided installers can (optionally) resolve the latest mpv builds per platform without bundling any upstream code. See comments inside `install.sh` and `install.ps1`.

---

## 🙏 Acknowledgements

This suite stands on the shoulders of open-source giants.  
It does not distribute their binaries, only configuration and logic designed for professional broadcast environments.

- [**mpv Development Team**](https://mpv.io) — the resilient playback engine at its core  
- [**FFmpeg Project**](https://ffmpeg.org) — the invisible open(-source) heart pulsing beneath almost every broadcast chain on earth
- **EBU (European Broadcasting Union)** — R128 loudness & tech standards  
- **SMPTE (Society of Motion Picture and Television Engineers)** — frame-accurate timecode foundations  
- **Broadcast Engineers Worldwide** — for decades of obsessive precision

---

## 📞 Support & Community

- **Issues:** [GitHub Issues](https://github.com/FiLORUX/mpv-broadcast-suite/issues)
- **Discussions:** [GitHub Discussions](https://github.com/FiLORUX/mpv-broadcast-suite/discussions)
- **mpv Manual:** [mpv.io/manual](https://mpv.io/manual/stable/)

---

## 🔄 Changelog

### Version 1.0.0 (2025-10-16)
- Initial public release
- broadcast-style timecode display with drop-frame support
- Multi-channel audio routing (up to 16 channels)
- EBU R128, ATSC A/85, and podcast loudness normalisation
- Comprehensive keyboard shortcuts for broadcast workflows
- Support for all common broadcast framerates
- Cross-platform compatibility (Linux, macOS, Windows)

---

**Made with ⚡ for broadcast engineers, by broadcast engineers.**

*If this project helps your workflow, consider starring the repository on GitHub!*