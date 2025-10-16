# mpv Broadcast Suite
## Professional Quality Control & Monitoring for Broadcast Engineers

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![mpv](https://img.shields.io/badge/mpv-0.35%2B-red.svg)](https://mpv.io)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)]()

A comprehensive, production-ready mpv configuration suite designed for broadcast engineers, QC operators, and post-production professionals. Features EVS-style timecode display, advanced multi-channel audio routing, and loudness compliance tooling.

---

## 📺 Features

### Timecode & Monitoring
- **EVS-Style Timecode Display** - Large, centered SMPTE timecode with frame-accurate display
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

## ⌨️ Keyboard Reference

### Timecode Display
| Key | Action |
|-----|--------|
| `t` | Cycle timecode display modes (Full → TC Only → Minimal → Off) |
| `Ctrl+t` | Toggle countdown display |

### Audio Channel Routing
| Key | Action |
|-----|--------|
| `Ctrl+0` | **Reset** - Clear filters, apply intelligent downmix |
| `Ctrl+1` to `Ctrl+8` | Route stereo pairs (CH1+2, CH3+4, ..., CH15+16) |
| `Ctrl+Alt+1` to `Ctrl+Alt+8` | Solo channels CH1-8 (mono→stereo) |
| `Ctrl+Alt+Shift+1-8` | Solo channels CH9-16 (mono→stereo) |
| `Ctrl+l` | Cycle loudness normalisation (None → EBU R128 → ATSC → Podcast) |
| `Ctrl+i` | Display detailed audio information |

### Playback Control
| Key | Action |
|-----|--------|
| `.` / `,` | Step forward/backward one frame |
| `[` / `]` | Decrease/increase playback speed (0.5×, 2.0×) |
| `Backspace` | Reset playback speed to 1.0× |
| `→` / `←` | Seek ±1 second |
| `↑` / `↓` | Seek ±5 seconds |
| `Shift+→` / `Shift+←` | Seek ±10 seconds |

### Quality Control
| Key | Action |
|-----|--------|
| `i` | Show file metadata (resolution, codec, framerate, audio config) |
| `s` | Screenshot current frame (video only, no OSD) |
| `S` | Screenshot with OSD/subtitles |
| `Alt+↑` / `Alt+↓` | Zoom in/out for detail inspection |
| `Ctrl+Arrow Keys` | Pan whilst zoomed |
| `Alt+0` | Reset zoom and pan |
| `d` | Toggle deinterlacing |
| `a` | Cycle aspect ratio override |
| `l` / `L` | Toggle loop / Set A-B loop points |

### Help & Information
| Key | Action |
|-----|--------|
| `F1` | Display broadcast-specific quick reference |
| `?` | Show all keybindings |

---

## 📖 Usage Examples

### Scenario 1: Multi-Channel Embedded Audio QC

You receive a 1080p59.94 file with 16 channels of embedded PCM audio:

```bash
mpv broadcast_master.mxf
```

**Workflow:**
1. Press `Ctrl+i` to verify 16 channels detected
2. Press `Ctrl+1` to monitor CH1+2 (typically programme L+R)
3. Press `Ctrl+3` to check CH5+6 (often ambient or effects)
4. Press `Ctrl+Alt+1` to solo CH1 (hear left channel only in both ears)
5. Press `Ctrl+0` to reset and hear all channels intelligently mixed
6. Press `Ctrl+l` repeatedly until "EBU R128 (-23 LUFS)" appears for loudness normalisation

### Scenario 2: Frame-Accurate Review

You need to verify a specific frame for quality control:

```bash
mpv interview_cut.mp4
```

**Workflow:**
1. Use arrow keys for rough positioning
2. Press `,` and `.` to step frame-by-frame
3. Observe large timecode showing exact position: `01:23:45:18`
4. Press `s` to capture PNG screenshot
5. Press `Alt+↑` to zoom for pixel-peeping
6. Use `Ctrl+Arrow Keys` to pan around zoomed area
7. Press `Alt+0` to reset zoom when finished

### Scenario 3: Live Stream Monitoring

Monitoring a live ingest or stream:

```bash
mpv udp://239.1.1.1:5000
```

**Workflow:**
1. Timecode automatically displays elapsed time with countdown
2. Press `#` to cycle between multiple embedded audio tracks
3. Use `Ctrl+1-8` for rapid channel selection
4. Press `[` for half-speed review of recorded segments
5. Press `L` twice to set A-B loop on interesting sections

---

## 🎨 Customisation

### Timecode Display Options

Edit `scripts/evs_timecode.lua` to customise appearance:

```lua
local opts = {
    mode = 'full',              -- Start-up mode: 'full', 'tc_only', 'minimal', 'off'
    tc_size = 72,               -- Main timecode font size (pixels)
    tc_color = 'FFFFFF',        -- Timecode colour (hex RGB)
    tc_border = 3,              -- Border width
    tc_shadow = 2,              -- Shadow offset
    bar_height = 8,             -- Progress bar height
    bar_color_fg = '00FF00',    -- Progress bar colour (green)
    bar_color_bg = '404040',    -- Background colour (dark grey)
    show_countdown = true,      -- Display remaining time
    show_elapsed = true,        -- Display elapsed time
    show_fps = true,            -- Display framerate with DF/NDF indicator
    refresh = 0.05,             -- Update interval (20fps)
}
```

### Audio Routing & Loudness

Edit `scripts/audiomap.lua` for custom loudness targets:

```lua
local LOUDNESS_TARGETS = {
    ebu_r128 = -23,   -- EBU R128 (European broadcast standard)
    atsc = -24,       -- ATSC A/85 (North American broadcast)
    podcast = -16,    -- Podcast distribution
    custom = -18,     -- Add your organisation's target here
}
```

### Playback Profiles

Activate built-in profiles for specific workflows:

```bash
# Frame-accurate QC mode (no interpolation, exact seeking)
mpv --profile=qc-accurate video.mp4

# Real-time monitoring (smooth playback, framedrop allowed)
mpv --profile=qc-realtime stream.ts

# HDR content with proper tone mapping
mpv --profile=hdr hdr_content.mp4

# Slow-motion review at 0.25× speed
mpv --profile=slowmo action_sequence.mp4
```

Or apply profiles during playback by pressing `` ` `` (backtick) and typing:
```
apply-profile qc-accurate
```

---

## 🔧 Technical Details

### Supported Framerates

| Framerate | Type | Drop-Frame | Common Usage |
|-----------|------|------------|--------------|
| 23.976 fps | NTSC Film | Yes (`;`) | Film transferred to NTSC |
| 24.000 fps | Film | No (`:`) | Cinema, digital film |
| 25.000 fps | PAL | No (`:`) | European broadcast |
| 29.97 fps | NTSC | Yes (`;`) | North American SD broadcast |
| 30.000 fps | NTSC Progressive | No (`:`) | Progressive scan NTSC |
| 50.000 fps | PAL Progressive | No (`:`) | European HD broadcast |
| 59.94 fps | NTSC HD | Yes (`;`) | North American HD broadcast |
| 60.000 fps | Progressive HD | No (`:`) | High framerate progressive |
| 119.88 fps | HFR NTSC | Yes (`;`) | High framerate NTSC-derived |
| 120.00 fps | HFR Progressive | No (`:`) | High framerate progressive |

**Note:** Drop-frame timecode "drops" frame **numbers** (not actual frames) at the start of each minute except every 10th minute. This keeps timecode synchronised with real clock time for NTSC framerates.

### Audio Format Compatibility

| Format | Channel Routing | Loudness Normalisation | Notes |
|--------|----------------|------------------------|-------|
| PCM (WAV/AIF) | ✅ Full support | ✅ Full support | Recommended for QC work |
| AAC (Multi-channel) | ✅ Full support | ✅ Full support | Common in MP4/MOV containers |
| FLAC (Multi-channel) | ✅ Full support | ✅ Full support | Lossless compression |
| AC3/E-AC3 | ⚠️ Limited | ✅ Full support | Use default downmix for routing |
| DTS | ⚠️ Limited | ✅ Full support | Use default downmix for routing |
| Opus | ✅ Full support | ✅ Full support | Modern codec support |

**Recommendation:** For maximum compatibility with channel routing features, use uncompressed PCM or losslessly compressed FLAC audio.

### Loudness Standards Compliance

This suite implements industry-standard loudness normalisation:

| Standard | Target | True Peak | Region | Application |
|----------|--------|-----------|--------|-------------|
| EBU R128 | -23 LUFS | -1 dBTP | Europe, International | Broadcast television, cinema |
| ATSC A/85 | -24 LKFS | -2 dBTP | North America | Broadcast television (CALM Act) |
| AES Streaming | -16 LUFS | -1 dBTP | Global | Podcast, streaming platforms |

**Implementation:** Uses FFmpeg's `loudnorm` filter with linear mode for transparent, broadcast-compliant normalisation. Processing adds minimal latency suitable for real-time monitoring.

---

## 📁 Repository Structure

```
mpv-broadcast-suite/
├── README.md                  # This file
├── LICENSE                    # MIT License
├── CONTRIBUTING.md            # Contribution guidelines
├── .gitignore                 # Git ignore rules
├── install.sh                 # Installation script (Linux/macOS)
├── install.ps1                # Installation script (Windows)
├── mpv.conf                   # Main mpv configuration
├── input.conf                 # Keyboard bindings
├── scripts/
│   ├── evs_timecode.lua       # EVS-style timecode display
│   └── audiomap.lua           # Multi-channel audio router
├── docs/
│   ├── ADVANCED.md            # Advanced configuration guide
│   ├── TROUBLESHOOTING.md     # Common issues and solutions
│   └── KEYBOARD_REFERENCE.pdf # Printable keyboard reference card
└── examples/
    ├── ffmpeg_commands.md     # Useful FFmpeg commands for broadcast
    └── sample_profiles.conf   # Additional mpv profile examples
```

---

## 🐛 Troubleshooting

### Timecode Not Visible
**Symptom:** No timecode appears when playing file  
**Solution:** Press `t` to cycle display modes (may be set to 'off')  
**Verify:** Check that `evs_timecode.lua` exists in `scripts/` directory

### Audio Routing Ineffective
**Symptom:** Pressing `Ctrl+1-8` has no effect  
**Solution:** Press `Ctrl+i` to verify channel count. If file reports "2 channels", it's already stereo—routing not needed  
**Note:** For files with multiple audio **tracks** (not channels), use `#` to select the track first, then use `Ctrl+1-8` for channel routing within that track

### Drop-Frame Timecode Incorrect
**Symptom:** Timecode appears wrong or doesn't match external reference  
**Solution:** Press `i` to verify actual framerate. Drop-frame only applies to NTSC-derived rates (~23.976, ~29.97, ~59.94)  
**Debug:** Edit `evs_timecode.lua` and adjust tolerance values in `get_fps_info()` if framerate detection is incorrect

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

## 🙏 Acknowledgements

- **EVS Broadcast Equipment** - Inspiration for timecode display design
- **EBU (European Broadcasting Union)** - R128 loudness specification
- **SMPTE (Society of Motion Picture and Television Engineers)** - Timecode standards
- **mpv Development Team** - Exceptional media player foundation
- **Broadcast Engineering Community** - Feedback and testing

---

## 📞 Support & Community

- **Issues:** [GitHub Issues](https://github.com/FiLORUX/mpv-broadcast-suite/issues)
- **Discussions:** [GitHub Discussions](https://github.com/FiLORUX/mpv-broadcast-suite/discussions)
- **mpv Manual:** [mpv.io/manual](https://mpv.io/manual/stable/)

---

## 🔄 Changelog

### Version 1.0.0 (2025-10-16)
- Initial public release
- EVS-style timecode display with drop-frame support
- Multi-channel audio routing (up to 16 channels)
- EBU R128, ATSC A/85, and podcast loudness normalisation
- Comprehensive keyboard shortcuts for broadcast workflows
- Support for all common broadcast framerates
- Cross-platform compatibility (Linux, macOS, Windows)

---

**Made with ⚡ for broadcast engineers, by broadcast engineers.**

*If this project helps your workflow, consider starring the repository on GitHub!*