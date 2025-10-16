## 🎨 Customisation

### Timecode Display Options

Edit `scripts/timecode.lua` to customise appearance:

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
