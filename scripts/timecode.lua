-- ============================================================================
-- Broadcast Replay & Playout System Style Timecode Display for mpv
-- ============================================================================
-- Professional broadcast timecode overlay with progress visualisation
--
-- Features:
--   • Large, centred SMPTE timecode display (HH:MM:SS:FF format)
--   • Automatic drop-frame/non-drop-frame detection for all framerates
--   • Progress bar visualisation showing file position
--   • Broadcast-style information overlay (elapsed, countdown, duration, FPS)
--   • Multiple display modes for different workflows
--
-- Supported Framerates:
--   23.976, 24, 25, 29.97 (DF), 30, 50, 59.94 (DF), 60, 119.88 (DF), 120
--
-- Drop-Frame Implementation:
--   Complies with SMPTE 12M-1 standard for NTSC-derived framerates
--   Compensates for 0.1% speed difference by dropping frame numbers
--   (not actual frames) at start of each minute except every 10th minute
--
-- Author: mpv Broadcast Suite Contributors
-- License: MIT
-- Version: 1.0.0
-- ============================================================================

local mp = require 'mp'
local assdraw = require 'mp.assdraw'

-- Configuration options
-- Modify these values to customise appearance and behaviour
local opts = {
    -- Display mode: 'full', 'tc_only', 'minimal', 'off'
    -- 'full'     = Large TC + progress bar + info overlay
    -- 'tc_only'  = Large TC + progress bar only
    -- 'minimal'  = Small TC in corner
    -- 'off'      = No display
    mode = 'full',
    
    -- Main timecode display settings
    tc_size = 72,                -- Font size in pixels
    tc_color = 'FFFFFF',         -- Colour in hex RGB (white)
    tc_border = 3,               -- Border width for legibility
    tc_shadow = 2,               -- Shadow offset for depth
    
    -- Progress bar settings
    bar_height = 8,              -- Height in pixels
    bar_margin = 20,             -- Distance from TC to bar
    bar_color_fg = '00FF00',     -- Foreground colour (green)
    bar_color_bg = '404040',     -- Background colour (dark grey)
    
    -- Information overlay settings (Broadcast-style, top-left)
    info_size = 32,              -- Font size for info text
    info_color = 'FFFF00',       -- Colour (yellow for visibility)
    show_countdown = true,       -- Display remaining time
    show_elapsed = true,         -- Display elapsed time
    show_duration = true,        -- Display total duration
    show_fps = true,             -- Display framerate with DF/NDF indicator
    
    -- Update frequency
    refresh = 0.05,              -- Seconds between updates (20fps)
}

-- Module state
local timer = nil
local screen_w, screen_h = 1920, 1080  -- Default resolution, updated dynamically

-- ============================================================================
-- Framerate Detection and Classification
-- ============================================================================

--- Check if two values are approximately equal within tolerance
-- @param a First value
-- @param b Second value
-- @param eps Epsilon tolerance (default: 0.01)
-- @return boolean True if values are within tolerance
local function is_close(a, b, eps)
    return math.abs(a - b) < (eps or 0.01)
end

--- Analyse framerate and determine drop-frame/non-drop-frame mode
-- Detects NTSC-derived framerates (23.976, 29.97, 59.94, 119.88) and
-- classifies them as drop-frame. All other rates use non-drop-frame.
--
-- @param fps Frames per second (from container or stream metadata)
-- @return fps_rounded Rounded FPS for calculation (24, 30, 60, 120, etc.)
-- @return is_drop_frame Boolean indicating if drop-frame compensation needed
-- @return separator String separator for timecode display (':' or ';')
local function get_fps_info(fps)
    -- NTSC film rate: 24000/1001 (~23.976 fps)
    if is_close(fps, 23.976, 0.01) or is_close(fps, 24000/1001, 0.001) then
        return 24, true, ';'
    
    -- NTSC standard definition: 30000/1001 (~29.97 fps)
    elseif is_close(fps, 29.97, 0.01) or is_close(fps, 30000/1001, 0.001) then
        return 30, true, ';'
    
    -- NTSC high definition: 60000/1001 (~59.94 fps)
    elseif is_close(fps, 59.94, 0.02) or is_close(fps, 60000/1001, 0.002) then
        return 60, true, ';'
    
    -- NTSC high framerate: 120000/1001 (~119.88 fps)
    elseif is_close(fps, 119.88, 0.05) or is_close(fps, 120000/1001, 0.005) then
        return 120, true, ';'
    
    -- All other framerates: non-drop-frame
    else
        return math.floor(fps + 0.5), false, ':'
    end
end

-- ============================================================================
-- Drop-Frame Timecode Calculation
-- ============================================================================

--- Calculate drop-frame compensation per SMPTE 12M-1
-- Drop-frame timecode skips frame NUMBERS (not actual frames) to maintain
-- sync with real clock time. For 29.97 fps, frames 00 and 01 are skipped
-- at the start of each minute EXCEPT minutes 00, 10, 20, 30, 40, 50.
-- For 59.94 fps, frames 00, 01, 02, 03 are skipped with the same logic.
--
-- Formula: adjusted_frames = frames + (drops_per_minute × complete_minutes) 
--                                   - (drops_per_10min × complete_10min_blocks)
--
-- @param frames Total frame count from video start
-- @param fps_rounded Rounded framerate (30, 60, 120)
-- @param is_df Boolean indicating if drop-frame mode active
-- @return Adjusted frame count with drop-frame compensation
local function calc_dropframe(frames, fps_rounded, is_df)
    if not is_df then return frames end
    
    -- Determine drop count per minute based on framerate
    -- 30 fps: drop 2 frames per minute
    -- 60 fps: drop 4 frames per minute
    -- 120 fps: drop 8 frames per minute
    local drop_per_min = (fps_rounded == 60) and 4 or 2
    if fps_rounded == 120 then drop_per_min = 8 end
    
    -- Calculate frames per time unit
    local fpm = fps_rounded * 60       -- Frames per minute
    local fp10m = fps_rounded * 600    -- Frames per 10 minutes
    
    -- Decompose total frames into 10-minute blocks and remainder
    local d = frames
    local ten_min = math.floor(d / fp10m)
    local rem10 = d % fp10m
    
    -- Calculate dropped frames
    -- Drop occurs every minute except 10th minute
    -- Therefore: 9 minutes per 10-minute block have drops
    local dropped = ten_min * (drop_per_min * 9)
    
    -- Handle remaining minutes after complete 10-minute blocks
    local mins = math.floor(rem10 / fpm)
    if mins > 0 then
        -- Don't drop on 10th minute (minute 0, 10, 20, etc.)
        local extra_drop = drop_per_min * (mins - math.floor(mins / 10))
        dropped = dropped + extra_drop
    end
    
    return frames + dropped
end

-- ============================================================================
-- Timecode Formatting
-- ============================================================================

--- Format seconds as SMPTE timecode string
-- Generates HH:MM:SS:FF or HH:MM:SS;FF depending on drop-frame mode
--
-- @param seconds Time position in seconds
-- @param fps Framerate from video metadata
-- @return tc_string Formatted timecode string
-- @return is_df Boolean indicating drop-frame mode
-- @return separator Character used between seconds and frames
local function format_timecode(seconds, fps)
    if not seconds or seconds < 0 then
        return "--:--:--:--", false, ':'
    end
    
    -- Classify framerate and get parameters
    local fps_rounded, is_df, sep = get_fps_info(fps)
    
    -- Convert seconds to total frame count
    local total_frames = math.floor(seconds * fps + 0.5)
    
    -- Apply drop-frame compensation if needed
    local frames = calc_dropframe(total_frames, fps_rounded, is_df)
    
    -- Decompose into hours, minutes, seconds, frames
    local h = math.floor(frames / (fps_rounded * 3600))
    local rem = frames % (fps_rounded * 3600)
    local m = math.floor(rem / (fps_rounded * 60))
    rem = rem % (fps_rounded * 60)
    local s = math.floor(rem / fps_rounded)
    local f = rem % fps_rounded
    
    -- Format as HH:MM:SS:FF with appropriate separator
    return string.format("%02d:%02d:%02d%s%02d", h, m, s, sep, f), is_df, sep
end

--- Format duration as human-readable time
-- Generates H:MM:SS or M:SS format depending on duration
--
-- @param seconds Duration in seconds
-- @return Formatted duration string
local function format_duration(seconds)
    if not seconds or seconds < 0 then return "--:--" end
    
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

-- ============================================================================
-- Overlay Construction
-- ============================================================================

--- Build ASS (Advanced SubStation Alpha) overlay string
-- Constructs the complete on-screen display using libass rendering
-- Includes timecode, progress bar, and information overlay
--
-- @return ASS format string ready for rendering
local function build_overlay()
    if opts.mode == 'off' then return "" end
    
    -- Retrieve playback properties
    local time_pos = mp.get_property_number("time-pos")
    local duration = mp.get_property_number("duration")
    local fps = mp.get_property_number("container-fps") 
             or mp.get_property_number("fps") 
             or 25  -- Fallback to PAL standard
    
    -- Get current OSD dimensions (updates on window resize)
    local osd_w = mp.get_property_number("osd-width", 1920)
    local osd_h = mp.get_property_number("osd-height", 1080)
    screen_w, screen_h = osd_w, osd_h
    
    local ass = assdraw.ass_new()
    
    -- ========================================
    -- MAIN TIMECODE (Bottom Centre)
    -- ========================================
    if opts.mode ~= 'minimal' and time_pos then
        local tc, is_df, sep = format_timecode(time_pos, fps)
        local df_indicator = is_df and " DF" or " NDF"
        
        -- Position: centred horizontally, 15% from bottom
        local tc_y = osd_h - (osd_h * 0.15)
        
        ass:new_event()
        ass:an(8)  -- Alignment: top-centre (we position manually)
        ass:pos(osd_w / 2, tc_y)
        ass:append(string.format("{\\fs%d\\bord%d\\shad%d\\c&H%s&}", 
                   opts.tc_size, opts.tc_border, opts.tc_shadow, opts.tc_color))
        ass:append(tc)
        
        -- Small drop-frame/non-drop-frame indicator
        ass:append(string.format("{\\fs%d}", math.floor(opts.tc_size * 0.3)))
        ass:append(df_indicator)
        
        -- ========================================
        -- PROGRESS BAR (Below Timecode)
        -- ========================================
        if duration and duration > 0 and opts.mode == 'full' then
            local progress = time_pos / duration
            local bar_y = tc_y - opts.tc_size - opts.bar_margin
            local bar_w = osd_w * 0.6  -- 60% of screen width
            local bar_x = (osd_w - bar_w) / 2
            
            -- Background bar (full width)
            ass:new_event()
            ass:pos(0, 0)
            ass:draw_start()
            ass:append(string.format("{\\c&H%s&\\bord0}", opts.bar_color_bg))
            ass:rect_cw(bar_x, bar_y, bar_x + bar_w, bar_y + opts.bar_height)
            ass:draw_stop()
            
            -- Foreground bar (progress)
            if progress > 0 then
                local fg_w = bar_w * math.min(progress, 1.0)
                ass:new_event()
                ass:pos(0, 0)
                ass:draw_start()
                ass:append(string.format("{\\c&H%s&\\bord0}", opts.bar_color_fg))
                ass:rect_cw(bar_x, bar_y, bar_x + fg_w, bar_y + opts.bar_height)
                ass:draw_stop()
            end
        end
    end
    
    -- ========================================
    -- INFO DISPLAY (Top-Left, Broadcast-Style)
    -- ========================================
    if opts.mode == 'full' and time_pos and duration then
        local info_lines = {}
        
        -- Elapsed time
        if opts.show_elapsed then
            table.insert(info_lines, "ELAPSED: " .. format_duration(time_pos))
        end
        
        -- Remaining time (countdown)
        if opts.show_countdown then
            local remaining = duration - time_pos
            table.insert(info_lines, "REMAIN: -" .. format_duration(remaining))
        end
        
        -- Total duration
        if opts.show_duration then
            table.insert(info_lines, "TOTAL: " .. format_duration(duration))
        end
        
        -- FPS with drop-frame indicator
        if opts.show_fps then
            local _, is_df = get_fps_info(fps)
            local fps_str = string.format("%.2f fps %s", fps, is_df and "(DF)" or "(NDF)")
            table.insert(info_lines, fps_str)
        end
        
        -- Filename
        local filename = mp.get_property("filename", "")
        table.insert(info_lines, filename)
        
        -- Draw info box line by line
        local info_y = 40
        for i, line in ipairs(info_lines) do
            ass:new_event()
            ass:an(7)  -- Alignment: top-left
            ass:pos(30, info_y + (i-1) * (opts.info_size + 5))
            ass:append(string.format("{\\fs%d\\bord2\\shad1\\c&H%s&}", 
                       opts.info_size, opts.info_color))
            ass:append(line)
        end
    end
    
    -- ========================================
    -- MINIMAL MODE (Corner Timecode Only)
    -- ========================================
    if opts.mode == 'minimal' and time_pos then
        local tc = format_timecode(time_pos, fps)
        ass:new_event()
        ass:an(7)  -- Top-left
        ass:pos(20, 20)
        ass:append(string.format("{\\fs%d\\bord2\\c&HFFFFFF&}", opts.info_size))
        ass:append(tc)
    end
    
    return ass.text
end

-- ============================================================================
-- Display Update and Timer Management
-- ============================================================================

--- Update on-screen display
-- Rebuilds and renders the overlay
local function update_display()
    if opts.mode == 'off' then
        mp.set_osd_ass(screen_w, screen_h, "")
        return
    end
    
    local overlay = build_overlay()
    mp.set_osd_ass(screen_w, screen_h, overlay)
end

--- Start periodic update timer
local function start_timer()
    if timer then timer:kill() end
    timer = mp.add_periodic_timer(opts.refresh, update_display)
    update_display()
end

--- Stop update timer and clear display
local function stop_timer()
    if timer then 
        timer:kill() 
        timer = nil 
    end
    mp.set_osd_ass(screen_w, screen_h, "")
end

-- ============================================================================
-- User Interface Controls
-- ============================================================================

--- Cycle through display modes
-- Sequence: full → tc_only → minimal → off → full
local function cycle_mode()
    local modes = {'full', 'tc_only', 'minimal', 'off'}
    local current_idx = 1
    
    -- Find current mode in list
    for i, m in ipairs(modes) do
        if m == opts.mode then 
            current_idx = i
            break 
        end
    end
    
    -- Advance to next mode (wrapping)
    local next_idx = (current_idx % #modes) + 1
    opts.mode = modes[next_idx]
    
    -- Provide user feedback
    mp.osd_message("TC Display: " .. opts.mode:upper(), 1.5)
    
    -- Update display state
    if opts.mode == 'off' then
        stop_timer()
    else
        if not timer then start_timer() end
        update_display()
    end
end

--- Toggle countdown display in full mode
local function toggle_countdown()
    opts.show_countdown = not opts.show_countdown
    mp.osd_message("Countdown: " .. (opts.show_countdown and "ON" or "OFF"), 1)
    update_display()
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

-- Update display when playback position changes
mp.observe_property("time-pos", "number", function()
    if opts.mode ~= 'off' then 
        update_display() 
    end
end)

-- Initialise on file load
mp.register_event("file-loaded", function()
    if opts.mode ~= 'off' then 
        start_timer() 
    end
end)

-- Clean up on file end
mp.register_event("end-file", function()
    stop_timer()
end)

-- ============================================================================
-- Script Messages (External Control)
-- ============================================================================

mp.register_script_message("cycle_mode", cycle_mode)
mp.register_script_message("toggle_countdown", toggle_countdown)

-- ============================================================================
-- Initialisation
-- ============================================================================

-- Start timer if not in 'off' mode
if opts.mode ~= 'off' then
    start_timer()
end

mp.msg.info("Timecode display loaded. Press 't' to cycle modes.")
