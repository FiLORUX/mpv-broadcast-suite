# ⌨️ Keybindings Reference

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