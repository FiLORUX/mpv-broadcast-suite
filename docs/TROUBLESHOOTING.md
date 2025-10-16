
# Troubleshooting Guide

Common issues and solutions for mpv Broadcast Suite.

## Timecode Display Issues

### Timecode Not Visible

**Symptoms:**
- No timecode appears when playing files
- Screen remains blank except for video

**Solutions:**
1. **Check display mode:** Press `t` repeatedly to cycle through modes
   - The suite may have been left in 'off' mode
   - Try each mode: Full → TC Only → Minimal → Off

2. **Verify Lua script installation:**
   ```bash
   ls ~/.config/mpv/scripts/timecode.lua
   # Should exist and be readable
   ```

3. **Check mpv Lua support:**
   ```bash
   mpv --version | grep lua
   # Should show Lua version
   ```

4. **Test with minimal config:**
   ```bash
   mpv --no-config --script=~/.config/mpv/scripts/timecode.lua test.mp4
   # If this works, conflict exists in main config
   ```

### Drop-Frame Timecode Incorrect

**Symptoms:**
- Timecode doesn't match reference (e.g., Avid, Premiere)
- Semicolon appears when colon expected (or vice versa)

**Solutions:**
1. **Verify actual framerate:**
   ```bash
   mpv --msg-level=all=info test.mp4 | grep fps
   # Or press 'i' during playback
   ```

2. **Check tolerance values:** Edit `timecode.lua`:
   ```lua
   -- Adjust tolerance if mpv reports imprecise framerates
   local function is_close(a, b, eps)
       return math.abs(a - b) < (eps or 0.01)  -- Increase if needed
   end
   ```

3. **Manual framerate override:** If automatic detection fails:
   ```lua
   -- In timecode.lua, force framerate:
   local fps = 29.97  -- Force NTSC drop-frame
   -- local fps = mp.get_property_number("container-fps") or 25  -- Comment out
   ```

### Progress Bar Not Updating

**Symptoms:**
- Progress bar frozen
- Bar doesn't reflect playback position

**Solutions:**
1. **Check file duration property:**
   - Some formats (e.g., raw streams) may not report duration
   - Press `` ` `` and type: `print-text "${duration}"`
   - If "undefined", progress bar cannot display

2. **Increase update rate:** Edit `timecode.lua`:
   ```lua
   local opts = {
       refresh = 0.1,  -- Increase from 0.05 if system is slow
   }
   ```

---

## Audio Routing Issues

### Channel Selection Has No Effect

**Symptoms:**
- Pressing `Ctrl+1-8` doesn't change audio
- Always hearing same channels

**Solutions:**
1. **Verify channel count:**
   ```bash
   mpv --no-video --msg-level=all=info test.mp4 | grep channels
   # Or press 'Ctrl+i' during playback
   ```

2. **Check for multiple tracks vs. channels:**
   - Multiple **tracks**: Use `#` to cycle tracks first
   - Multiple **channels** within track: Use `Ctrl+1-8`
   - Press `Ctrl+i` to see track and channel count

3. **Codec limitations:**
   - AC3/E-AC3/DTS may not support custom routing
   - Use `Ctrl+0` for default downmix instead
   - Consider remuxing to PCM for full control:
     ```bash
     ffmpeg -i input.mp4 -c:v copy -c:a pcm_s16le output.mov
     ```

4. **Verify lavfi support:**
   ```bash
   mpv --vf=help | grep lavfi
   # Should show lavfi wrapper available
   ```

### Solo Monitoring Plays Wrong Channel

**Symptoms:**
- `Ctrl+Alt+1` doesn't play channel 1
- Channels appear offset

**Solutions:**
1. **Channel numbering:** Remember that channels are **zero-indexed** internally:
   - User sees: CH1, CH2, CH3...
   - Internal: c0, c1, c2...
   - `Ctrl+Alt+1` = c0 (first channel)

2. **Check channel layout:**
   ```bash
   ffprobe -show_streams input.mp4 | grep channel_layout
   # Unusual layouts may need manual mapping
   ```

### Loudness Normalisation Causes Distortion

**Symptoms:**
- Audio clips or distorts when `Ctrl+l` activated
- Excessive loudness even at low volume

**Solutions:**
1. **Check true peak limiting:**
   - EBU R128 and ATSC targets include -1 dBTP limiting
   - If source is already hot, may cause pumping
   - Solution: Cycle `Ctrl+l` to 'none' for critical listening

2. **Reduce target level:** Edit `audiomap.lua`:
   ```lua
   local LOUDNESS_TARGETS = {
       ebu_r128 = -25,  -- Reduce from -23 for more headroom
       atsc = -26,      -- Reduce from -24
   }
   ```

3. **Use offline normalisation for deliverables:**
   - Real-time loudness is for monitoring only
   - For deliverables, use ffmpeg-normalize or similar:
     ```bash
     ffmpeg-normalize input.mp4 -o output.mp4 -c:a aac -b:a 192k
     ```

---

## Performance Issues

### Playback Stutters or Drops Frames

**Symptoms:**
- Jerky playback
- Frame drops reported in terminal
- Audio/video desync

**Solutions:**
1. **Disable interpolation:**
   - Press `` ` `` (backtick) for console
   - Type: `set interpolation no`
   - Or use profile: `mpv --profile=qc-accurate test.mp4`

2. **Enable hardware decode:**
   - Check current: `mpv --msg-level=all=info test.mp4 | grep hwdec`
   - Force enable: Add to mpv.conf:
     ```ini
     hwdec=auto-copy  # Or: vaapi (Linux), videotoolbox (macOS), d3d11va (Windows)
     ```

3. **Reduce timecode update rate:** Edit `timecode.lua`:
   ```lua
   local opts = {
       refresh = 0.2,  -- Update every 200ms instead of 50ms
   }
   ```

4. **Disable loudness filter:**
   - Loudness normalisation is CPU-intensive
   - Press `Ctrl+l` until "None" displays
   - Or disable globally: Comment out in `audiomap.lua`

### High CPU Usage When Idle

**Symptoms:**
- CPU usage remains high when paused
- Fan noise increases

**Solutions:**
1. **Check update timers:**
   - Timecode should pause when file paused
   - If not, edit `timecode.lua`:
     ```lua
     mp.observe_property("pause", "bool", function(_, paused)
         if paused then
             stop_timer()
         else
             start_timer()
         end
     end)
     ```

2. **Disable background processing:**
   - Add to mpv.conf:
     ```ini
     cursor-autohide=1000
     stop-screensaver=yes
     ```

---

## Platform-Specific Issues

### macOS: Scripts Not Loading

**Symptoms:**
- Clean install, scripts don't run
- "script failed to load" errors

**Solutions:**
1. **Check path case sensitivity:**
   - macOS is case-insensitive but case-preserving
   - Ensure: `~/.config/mpv/scripts/` (lowercase)

2. **Verify file permissions:**
   ```bash
   chmod 644 ~/.config/mpv/scripts/*.lua
   ```

3. **Check for quarantine attribute:**
   ```bash
   xattr -d com.apple.quarantine ~/.config/mpv/scripts/*.lua
   ```

### Windows: PowerShell Script Execution

**Symptoms:**
- `install.ps1` refuses to run
- "execution of scripts is disabled" error

**Solutions:**
1. **Enable script execution temporarily:**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\install.ps1
   ```

2. **Or run with bypass:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```

### Linux: GPU Decode Not Working

**Symptoms:**
- `hwdec=auto` has no effect
- Software decode only

**Solutions:**
1. **Install VA-API drivers:**
   ```bash
   # Intel
   sudo apt install intel-media-va-driver

   # AMD
   sudo apt install mesa-va-drivers

   # NVIDIA (requires proprietary drivers)
   sudo apt install vdpau-va-driver
   ```

2. **Verify VA-API availability:**
   ```bash
   vainfo
   # Should list supported profiles
   ```

3. **Force VA-API in mpv.conf:**
   ```ini
   hwdec=vaapi
   vo=gpu
   ```

---

## Configuration Conflicts

### Scripts Work Standalone But Not Together

**Symptoms:**
- Individual scripts function when tested alone
- Combined installation causes issues

**Solutions:**
1. **Check for keybinding conflicts:**
   - Open `input.conf` and search for duplicate bindings
   - mpv uses first match, subsequent ignored

2. **Test with minimal config:**
   ```bash
   mpv --no-config \
       --include=~/.config/mpv/mpv.conf \
       --include=~/.config/mpv/input.conf \
       test.mp4
   ```

3. **Check script load order:**
   - Scripts in `scripts/` folder load alphabetically
   - If order matters, prefix with numbers:
     ```
     01_timecode.lua
     02_audiomap.lua
     ```

---

## Getting Help

If issues persist:

1. **Collect diagnostic info:**
   ```bash
   mpv --version > diagnostics.txt
   mpv --log-file=mpv.log test.mp4
   # Play for a few seconds, then quit
   ```

2. **Create minimal reproduction:**
   - Isolate the issue to smallest config
   - Note exact steps to reproduce

3. **Report on GitHub:**
   - Include: mpv version, OS, file format, steps, logs
   - Use issue template if provided
   - Include `diagnostics.txt` and relevant logs

4. **Community resources:**
   - mpv manual: `man mpv` or https://mpv.io/manual/
   - mpv IRC: #mpv on Libera.Chat
   - Project discussions: GitHub Discussions

---

**Remember:** Many "issues" are actually correct behaviour for broadcast standards. For example, drop-frame timecode intentionally skips frame numbers—this is not a bug!

