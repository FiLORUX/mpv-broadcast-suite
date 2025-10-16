
# Advanced Configuration Guide

Advanced customisation and integration for power users.

## Table of Contents

1. [Custom Loudness Targets](#custom-loudness-targets)
2. [Advanced Keybindings](#advanced-keybindings)
3. [Integration with External Tools](#integration-with-external-tools)
4. [Network Stream Monitoring](#network-stream-monitoring)
5. [Multi-Instance Workflows](#multi-instance-workflows)
6. [Performance Optimisation](#performance-optimisation)
7. [Custom Timecode Formats](#custom-timecode-formats)

---

## Custom Loudness Targets

### Adding Organisation-Specific Standards

Edit `scripts/audiomap.lua` to add custom loudness targets:

```lua
local LOUDNESS_TARGETS = {
    ebu_r128 = -23,
    atsc = -24,
    podcast = -16,
    
    -- Add custom targets
    itv_uk = -23,        -- ITV UK standard
    bbc_r1 = -20,        -- BBC Radio 1
    netflix = -27,       -- Netflix dialogue normalisation
    youtube = -14,       -- YouTube normalisation
    spotify = -14,       -- Spotify normalisation
    apple_music = -16,   -- Apple Music
    tidal = -14,         -- Tidal
}
```

Update the cycling order:

```lua
local function toggle_loudness()
    local targets = {
        "none", 
        "ebu_r128", 
        "atsc", 
        "podcast",
        "netflix",    -- Add to cycle
        "youtube",    -- Add to cycle
    }
    -- [rest of function]
end
```

### True Peak Limiting Adjustment

Modify true peak limiting for specific delivery requirements:

```lua
local function build_loudness_filter(target_lufs)
    if target_lufs == 0 then return nil end
    
    -- Default: -1.0 dBTP (EBU R128 / ATSC)
    -- Netflix requires: -2.0 dBTP
    -- Adjust as needed:
    local true_peak = -1.0  -- Change to -2.0 for Netflix
    
    local filter = string.format(
        "loudnorm=I=%.1f:TP=%.1f:LRA=11",
        target_lufs, true_peak
    )
    return filter
end
```

---

## Advanced Keybindings

### Macro Keybindings

Create complex workflows with macro keys. Add to `input.conf`:

```ini
# QC preset: Reset audio, enable EBU R128, activate qc-accurate profile
F9 script-message-to audiomap reset; script-message-to audiomap toggle_loudness; apply-profile qc-accurate; show-text "QC Mode: Active"

# Quick export: Screenshot burst (10 frames at 1fps)
F10 run "bash" "-c" "for i in {1..10}; do sleep 1; echo screenshot > /tmp/mpv-commands; done"

# Channel pair cycling for quick review
Ctrl+9 script-message-to audiomap pair 1; show-text "CH1+2"; add timer 2 "script-message-to audiomap pair 2; show-text 'CH3+4'"; add timer 4 "script-message-to audiomap pair 3; show-text 'CH5+6'"
```

### MIDI Controller Integration

Use MIDI controllers for tactile control (requires lua-midi):

```lua
-- Add to scripts/midi_control.lua
local midi = require 'midi'
local mp = require 'mp'

-- Map MIDI CC to channel selection
midi.cc(1, function(value)
    local pair = math.floor(value / 16) + 1  -- CC value 0-127 → pairs 1-8
    mp.commandv("script-message-to", "audiomap", "pair", tostring(pair))
end)

-- Map MIDI fader to volume
midi.cc(7, function(value)
    local volume = (value / 127) * 150  -- Map to 0-150%
    mp.set_property("volume", volume)
end)
```

### External Control via IPC

Enable JSON IPC for external control:

Add to `mpv.conf`:
```ini
input-ipc-server=/tmp/mpvsocket
```

Control from command line:
```bash
# Change to channel pair 3 (CH5+6)
echo '{"command": ["script-message-to", "audiomap", "pair", "3"]}' | socat - /tmp/mpvsocket

# Query current timecode
echo '{"command": ["get_property", "time-pos"]}' | socat - /tmp/mpvsocket
```

Python example:
```python
import socket
import json

def send_command(command):
    sock = socket.socket(socket.AF_UNIX)
    sock.connect('/tmp/mpvsocket')
    sock.send((json.dumps({"command": command}) + '\n').encode())
    response = sock.recv(4096)
    sock.close()
    return json.loads(response)

# Route to CH7+8
send_command(["script-message-to", "audiomap", "pair", "4"])

# Get current timecode
tc = send_command(["get_property", "time-pos"])
print(f"Current position: {tc['data']:.3f} seconds")
```

---

## Integration with External Tools

### FFmpeg Preprocessing Pipeline

Pre-process files before QC:

```bash
#!/bin/bash
# qc-prep.sh - Prepare file for QC review

INPUT="$1"
OUTPUT="${INPUT%.*}_qc.mov"

ffmpeg -i "$INPUT" \
    -c:v prores_ks -profile:v 3 -qscale:v 5 \
    -c:a pcm_s24le \
    -vf "drawtext=text='%{pts\:hms}':x=10:y=10:fontsize=48:fontcolor=yellow" \
    "$OUTPUT"

mpv --profile=qc-accurate "$OUTPUT"
```

### Avid Media Composer Integration

Export timecode data for Avid:

```lua
-- Add to scripts/export_tc.lua
local mp = require 'mp'
local utils = require 'mp.utils'

mp.register_script_message("export_tc", function()
    local tc = mp.get_property("time-pos")
    local fps = mp.get_property_number("container-fps")
    local filename = mp.get_property("filename")
    
    -- Format for Avid EDL
    local data = string.format("001 %s V C %s %s\n", 
        filename, format_tc(tc, fps), format_tc(tc, fps))
    
    local file = io.open("avid_export.edl", "a")
    file:write(data)
    file:close()
    
    mp.osd_message("Timecode exported to avid_export.edl")
end)

mp.add_key_binding("Ctrl+e", "export_tc", function()
    mp.commandv("script-message", "export_tc")
end)
```

### DaVinci Resolve EDL Generation

```bash
# Create EDL from mpv A-B loops
# Usage: Loop section with 'L', then run this command

echo "TITLE: QC Notes" > resolve_import.edl
echo "FCM: NON-DROP FRAME" >> resolve_import.edl

# Get loop points from mpv
mpv --msg-level=all=info file.mp4 | grep "ab-loop" >> resolve_import.edl
```

---

## Network Stream Monitoring

### UDP Multicast Monitoring

Configure for live stream monitoring:

```ini
# Add to mpv.conf
[stream-monitor]
profile-desc="Live stream monitoring"
cache=yes
cache-secs=1
demuxer-readahead-secs=2
video-sync=audio
framedrop=vo
untimed=yes
```

Launch:
```bash
mpv --profile=stream-monitor udp://239.1.1.1:5000
```

### RTMP/SRT Stream Inspection

```bash
# SRT with statistics
mpv --profile=stream-monitor \
    --script-opts=stats-bindlist=i \
    srt://remote-host:5000?mode=caller

# RTMP with buffer analysis
mpv --profile=stream-monitor \
    --demuxer-max-bytes=10M \
    rtmp://streamserver/live/streamkey
```

### Multi-View Monitoring

Monitor multiple streams simultaneously using mpv-grid:

```bash
#!/bin/bash
# quad-monitor.sh - Four-stream monitoring

mpv --geometry=960x540+0+0 --profile=stream-monitor udp://239.1.1.1:5000 &
mpv --geometry=960x540+960+0 --profile=stream-monitor udp://239.1.1.2:5000 &
mpv --geometry=960x540+0+540 --profile=stream-monitor udp://239.1.1.3:5000 &
mpv --geometry=960x540+960+540 --profile=stream-monitor udp://239.1.1.4:5000 &
```

---

## Multi-Instance Workflows

### Comparison Viewing

View source and transcode side-by-side:

```bash
# Left: Source
mpv --geometry=960x1080+0+0 --title="Source" source.mov &

# Right: Transcode
mpv --geometry=960x1080+960+0 --title="Transcode" output.mp4 &

# Synchronise playback
mpv-sync left right  # Requires external script
```

### Reference Monitoring

Keep reference material open whilst working:

```bash
# Main QC window
mpv --profile=qc-accurate --title="QC Review" dailies.mp4 &

# Reference window (always on top)
mpv --ontop --geometry=640x360+1280+0 --title="Reference" reference.mp4 &
```

---

## Performance Optimisation

### GPU Shader Caching

Improve start-up performance:

```ini
# Add to mpv.conf
gpu-shader-cache-dir=~/.cache/mpv/shaders
icc-cache-dir=~/.cache/mpv/icc

# Pre-compile shaders
shader-cache-dir=/tmp/mpv-shader-cache
```

### Large File Optimisation

For very large files (>50GB):

```ini
[large-files]
profile-desc="Optimisation for large files"
demuxer-max-bytes=1G
demuxer-readahead-secs=60
cache-secs=30
demuxer-max-back-bytes=500M
hr-seek-demuxer-offset=1
```

### Low-Latency Mode

Minimise monitoring latency:

```ini
[low-latency]
profile-desc="Minimal latency monitoring"
cache=no
video-sync=audio
interpolation=no
vd-lavc-threads=1
audio-buffer=0.05
untimed=yes
```

---

## Custom Timecode Formats

### Feet+Frames Display

Add 35mm film-style feet+frames:

```lua
-- Add to evs_timecode.lua
local function format_feet_frames(seconds, fps)
    local frames = math.floor(seconds * fps)
    -- 35mm 4-perf: 16 frames per foot
    local feet = math.floor(frames / 16)
    local ff = frames % 16
    return string.format("%d+%02d", feet, ff)
end
```

### Absolute Frame Number

Display absolute frame count:

```lua
local function format_frame_number(seconds, fps)
    local frames = math.floor(seconds * fps + 0.5)
    return string.format("Frame: %d", frames)
end
```

### Timecode with Subframes

For audio post-production (80 subframes per frame):

```lua
local function format_tc_subframes(seconds, fps)
    local total_subframes = math.floor(seconds * fps * 80 + 0.5)
    local frames = math.floor(total_subframes / 80)
    local subframes = total_subframes % 80
    
    -- Format as HH:MM:SS:FF.SF
    local h = math.floor(frames / (fps * 3600))
    local m = math.floor((frames % (fps * 3600)) / (fps * 60))
    local s = math.floor((frames % (fps * 60)) / fps)
    local f = frames % fps
    
    return string.format("%02d:%02d:%02d:%02d.%02d", h, m, s, f, subframes)
end
```

---

## Scripting Examples

### Auto-Screenshot on Scene Change

```lua
-- scripts/auto_screenshot.lua
local mp = require 'mp'

local last_pts = 0
local threshold = 0.3  -- Scene change threshold

mp.observe_property("vf-metadata", "native", function(_, metadata)
    if not metadata then return end
    
    local scene_score = metadata["lavfi.scene"]
    if scene_score and tonumber(scene_score) > threshold then
        local pts = mp.get_property_number("time-pos")
        if pts - last_pts > 1.0 then  -- Minimum 1 second between shots
            mp.commandv("screenshot", "video")
            mp.osd_message("Scene change detected - screenshot captured")
            last_pts = pts
        end
    end
end)
```

### Automated QC Report Generation

```lua
-- scripts/qc_report.lua
local mp = require 'mp'
local utils = require 'mp.utils'

local report = {}

mp.register_script_message("qc_mark", function(severity, note)
    local tc = mp.get_property("time-pos")
    local fps = mp.get_property_number("container-fps")
    
    table.insert(report, {
        timecode = format_timecode(tc, fps),
        severity = severity,
        note = note
    })
    
    mp.osd_message(string.format("QC Mark: %s", note))
end)

mp.register_script_message("qc_export", function()
    local filename = mp.get_property("filename")
    local output = io.open(filename .. "_qc_report.txt", "w")
    
    output:write(string.format("QC Report: %s\n", filename))
    output:write(string.format("Generated: %s\n\n", os.date()))
    
    for _, mark in ipairs(report) do
        output:write(string.format("[%s] %s: %s\n", 
            mark.timecode, mark.severity, mark.note))
    end
    
    output:close()
    mp.osd_message("QC report exported")
end)

-- Keybindings
mp.add_key_binding("Ctrl+m", "qc_mark_minor", function()
    mp.commandv("script-message", "qc_mark", "MINOR", "Issue noted")
end)

mp.add_key_binding("Ctrl+Shift+m", "qc_mark_major", function()
    mp.commandv("script-message", "qc_mark", "MAJOR", "Significant issue")
end)

mp.add_key_binding("Ctrl+r", "qc_export_report", function()
    mp.commandv("script-message", "qc_export")
end)
```

---

For more examples and community scripts, see the [mpv user scripts repository](https://github.com/mpv-player/mpv/wiki/User-Scripts).
