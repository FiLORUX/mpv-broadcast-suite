-- ============================================================================
-- Professional Broadcast Timecode Overlay for mpv
-- ============================================================================
-- SMPTE-compliant timecode display with responsive design and efficient
-- rendering pipeline for broadcast and post-production workflows.
--
-- Features:
--   • SMPTE 12M-1 compliant drop-frame compensation for NTSC rates
--   • Fully responsive layout adapting to viewport changes
--   • Efficient event-driven rendering (no wasteful polling)
--   • Support for 23.976-120 fps including high frame rate formats
--   • Broadcast-style information overlay with elapsed/remaining/duration
--   • Multiple display modes: full, tc_only, minimal, off
--
-- Keybindings:
--   t     Cycle through display modes
--   T     Toggle countdown display
--
-- Version: 2.0.0
-- Licence: MIT
-- ============================================================================

local mp = require 'mp'
local assdraw = require 'mp.assdraw'

-- ============================================================================
-- Configuration
-- ============================================================================

local config = {
    -- Display mode: 'full', 'tc_only', 'minimal', 'off'
    mode = 'full',
    
    -- Responsive sizing (as fraction of viewport)
    safe_margin = 0.03,          -- Inner safe area margin
    tc_rel_size = 0.065,         -- Timecode font size (relative to height)
    tc_border_rel = 0.003,       -- Outline thickness
    info_rel_size = 0.022,       -- Info text size
    bar_height_rel = 0.010,      -- Progress bar height
    bar_gap_rel = 0.005,         -- Gap between TC and progress bar
    
    -- Display toggles
    show_elapsed = true,
    show_countdown = true,
    show_duration = true,
    show_fps = true,
    show_filename = false,       -- Disabled by default for cleaner display
    
    -- Colour palette (RGB hex, broadcast-safe)
    colours = {
        tc_fg = 'FFFFFF',        -- Timecode foreground (white)
        tc_border = '000000',    -- Timecode outline (black)
        info_fg = 'FFFF00',      -- Info text (yellow)
        bar_fg = '00FF00',       -- Progress bar (green)
        bar_bg = '404040',       -- Progress background (dark grey)
    },
    
    -- Opacity values (0.0 = transparent, 1.0 = opaque)
    opacity = {
        tc_fg = 1.00,
        info_fg = 1.00,
        bar_fg = 0.95,
        bar_bg = 0.35,
    },
    
    -- Framerate detection tolerance
    fps_epsilon = 0.05,          -- Increased tolerance for variable sources
}

-- ============================================================================
-- State Management
-- ============================================================================

local state = {
    overlay = nil,               -- OSD overlay object
    last_dimensions = nil,       -- Cache for dimension changes
    is_paused = false,           -- Playback pause state
    needs_update = true,         -- Render flag
}

-- ============================================================================
-- Utility Functions
-- ============================================================================

--- Clamp value between minimum and maximum
local function clamp(x, min_val, max_val)
    if x < min_val then return min_val
    elseif x > max_val then return max_val
    else return x end
end

--- Convert opacity (0-1) to libass alpha (00-FF, inverted)
local function opacity_to_alpha(opacity)
    local alpha_val = math.floor((1 - clamp(opacity, 0, 1)) * 255 + 0.5)
    return string.format('%02X', alpha_val)
end

--- Convert RGB hex to BGR hex (libass format)
local function rgb_to_bgr(rgb_hex)
    return rgb_hex:sub(5, 6) .. rgb_hex:sub(3, 4) .. rgb_hex:sub(1, 2)
end

--- Generate libass colour string with opacity
local function ass_colour(rgb_hex, opacity)
    return string.format('\\1c&H%s&\\1a&H%s&',
        rgb_to_bgr(rgb_hex),
        opacity_to_alpha(opacity))
end

--- Generate libass border string
local function ass_border(rgb_hex, width_px)
    return string.format('\\bord%d\\3c&H%s&\\3a&H00&',
        math.floor(width_px + 0.5),
        rgb_to_bgr(rgb_hex))
end

--- Check if two floating point values are approximately equal
local function is_close(a, b, epsilon)
    return math.abs(a - b) < epsilon
end

-- ============================================================================
-- Framerate Detection and Classification
-- ============================================================================

--- Analyse framerate and determine drop-frame mode
-- Detects NTSC-derived framerates and classifies them appropriately.
-- Uses increased tolerance to handle sources with slight variation.
--
-- @param fps Frames per second from container or stream metadata
-- @return fps_rounded Rounded FPS for timecode calculation
-- @return is_drop_frame Boolean indicating drop-frame mode
-- @return separator Timecode separator character (':' or ';')
local function get_fps_info(fps)
    if not fps or fps <= 0 then
        mp.msg.warn('Invalid framerate received, defaulting to 25 fps NDF')
        return 25, false, ':'
    end
    
    local eps = config.fps_epsilon
    
    -- NTSC film rate: 24000/1001 (≈23.976)
    if is_close(fps, 23.976, eps) or is_close(fps, 24000/1001, 0.001) then
        return 24, true, ';'
    
    -- NTSC standard definition: 30000/1001 (≈29.97)
    elseif is_close(fps, 29.97, eps) or is_close(fps, 30000/1001, 0.001) then
        return 30, true, ';'
    
    -- NTSC high definition: 60000/1001 (≈59.94)
    elseif is_close(fps, 59.94, eps) or is_close(fps, 60000/1001, 0.001) then
        return 60, true, ';'
    
    -- NTSC high framerate: 120000/1001 (≈119.88)
    elseif is_close(fps, 119.88, eps) or is_close(fps, 120000/1001, 0.001) then
        return 120, true, ';'
    
    -- NTSC 48 fps (less common but valid): 48000/1001 (≈47.952)
    elseif is_close(fps, 47.952, eps) or is_close(fps, 48000/1001, 0.001) then
        return 48, true, ';'
    
    -- All other framerates: non-drop-frame
    else
        return math.floor(fps + 0.5), false, ':'
    end
end

-- ============================================================================
-- Drop-Frame Timecode Calculation
-- ============================================================================

--- Calculate drop-frame compensation per SMPTE 12M-1 standard
-- Drop-frame skips frame NUMBERS (not actual frames) to maintain sync
-- with real clock time. Frames are dropped at the start of each minute
-- except every 10th minute (00, 10, 20, 30, 40, 50).
--
-- Drop pattern by framerate:
--   29.97 fps: Skip frames 00, 01 (2 frames per minute)
--   59.94 fps: Skip frames 00, 01, 02, 03 (4 frames per minute)
--  119.88 fps: Skip frames 00-07 (8 frames per minute)
--   47.952fps: Skip frames 00-03 (4 frames per minute)
--
-- @param total_frames Absolute frame count from video start
-- @param fps_rounded Rounded framerate (24, 30, 48, 60, 120)
-- @param is_drop_frame Boolean indicating drop-frame mode active
-- @return Adjusted frame count with drop-frame compensation applied
local function calc_dropframe(total_frames, fps_rounded, is_drop_frame)
    if not is_drop_frame then
        return total_frames
    end
    
    -- Determine drop count per minute based on framerate
    local drop_per_min
    if fps_rounded == 30 or fps_rounded == 24 then
        drop_per_min = 2
    elseif fps_rounded == 60 or fps_rounded == 48 then
        drop_per_min = 4
    elseif fps_rounded == 120 then
        drop_per_min = 8
    else
        mp.msg.warn(string.format('Unexpected DF framerate: %d, using 2 frame drop', fps_rounded))
        drop_per_min = 2
    end
    
    -- Calculate frames per time unit
    local frames_per_min = fps_rounded * 60
    local frames_per_10min = fps_rounded * 600
    
    -- Decompose into 10-minute blocks and remainder
    local ten_min_blocks = math.floor(total_frames / frames_per_10min)
    local remaining_frames = total_frames % frames_per_10min
    
    -- Calculate total dropped frames
    -- Each 10-minute block drops frames in 9 out of 10 minutes
    local total_dropped = ten_min_blocks * (drop_per_min * 9)
    
    -- Handle remaining minutes after complete 10-minute blocks
    local remaining_minutes = math.floor(remaining_frames / frames_per_min)
    if remaining_minutes > 0 then
        -- Don't drop on the first minute of each 10-minute block (minute 0)
        total_dropped = total_dropped + (drop_per_min * remaining_minutes)
    end
    
    return total_frames + total_dropped
end

-- ============================================================================
-- Timecode Formatting
-- ============================================================================

--- Format seconds as SMPTE timecode string
-- Generates HH:MM:SS:FF or HH:MM:SS;FF depending on drop-frame mode
--
-- @param seconds Time position in seconds
-- @param fps Framerate from video metadata
-- @return tc_string Formatted timecode string (HH:MM:SS:FF)
-- @return is_drop_frame Boolean indicating drop-frame mode
-- @return separator Character used between seconds and frames
local function format_timecode(seconds, fps)
    if not seconds or seconds < 0 then
        return '00:00:00:00', false, ':'
    end
    
    -- Classify framerate and get parameters
    local fps_rounded, is_df, separator = get_fps_info(fps)
    
    -- Convert seconds to total frame count
    local total_frames = math.floor(seconds * fps + 0.5)
    
    -- Apply drop-frame compensation if needed
    local adjusted_frames = calc_dropframe(total_frames, fps_rounded, is_df)
    
    -- Decompose into time components
    local frames_per_hour = fps_rounded * 3600
    local frames_per_min = fps_rounded * 60
    
    local hours = math.floor(adjusted_frames / frames_per_hour)
    local remainder = adjusted_frames % frames_per_hour
    
    local minutes = math.floor(remainder / frames_per_min)
    remainder = remainder % frames_per_min
    
    local secs = math.floor(remainder / fps_rounded)
    local frames = remainder % fps_rounded
    
    -- Format as HH:MM:SS:FF with appropriate separator
    local tc_string = string.format('%02d:%02d:%02d%s%02d',
        hours, minutes, secs, separator, frames)
    
    return tc_string, is_df, separator
end

--- Format duration as human-readable time string
-- @param seconds Duration in seconds
-- @return Formatted duration string (H:MM:SS or M:SS)
local function format_duration(seconds)
    if not seconds or seconds < 0 then
        return '--:--'
    end
    
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format('%d:%02d:%02d', hours, mins, secs)
    else
        return string.format('%d:%02d', mins, secs)
    end
end

-- ============================================================================
-- Viewport Dimension Handling
-- ============================================================================

--- Get OSD dimensions with fallback
-- Prefers osd-dimensions property for correct handling of letterboxing
-- and safe areas, falls back to get_osd_size if unavailable.
--
-- @return dimensions Table with {w, h, ml, mr, mt, mb}
local function get_osd_dimensions()
    local dims = mp.get_property_native('osd-dimensions')
    
    if not dims then
        local width, height = mp.get_osd_size()
        return {
            w = width or 1920,
            h = height or 1080,
            ml = 0, mr = 0, mt = 0, mb = 0
        }
    end
    
    return dims
end

  -- ============================================================================
-- Overlay Rendering
-- ============================================================================

-- Build and render complete OSD overlay
-- Constructs timecode display, progress bar, and information overlay
-- using responsive layout based on current viewport dimensions.
local function render_overlay()
    -- Early out if overlay is disabled
    if config.mode == 'off' then
        if state.overlay then
            state.overlay:remove()
            state.overlay = nil -- ensure overlay object is cleared
        end
        return
    end

    -- Get viewport dimensions
    local dims = get_osd_dimensions()
    local vp_w, vp_h = dims.w, dims.h
    if (not vp_w) or (not vp_h) or vp_w <= 0 or vp_h <= 0 then
        return
    end

    -- Retrieve playback properties
    local time_pos     = mp.get_property_number('time-pos')
    local duration     = mp.get_property_number('duration')
    local fps          = mp.get_property_number('container-fps')
                          or mp.get_property_number('fps')
                          or 25
    local progress_pct = mp.get_property_number('percent-pos') or 0

    -- Initialise overlay if needed
    if not state.overlay then
        state.overlay = mp.create_osd_overlay('ass-events')
    end
    state.overlay.res_x = vp_w
    state.overlay.res_y = vp_h

    local ass = assdraw.ass_new()

    -- Calculate responsive dimensions
    local margin      = math.floor(math.min(vp_w, vp_h) * config.safe_margin + 0.5)
    local safe_left   = dims.ml + margin
    local safe_right  = vp_w - dims.mr - margin
    local safe_top    = dims.mt + margin
    local safe_bottom = vp_h - dims.mb - margin
    local safe_width  = safe_right - safe_left
    local safe_height = safe_bottom - safe_top

    local tc_font_size   = clamp(math.floor(vp_h * config.tc_rel_size     + 0.5), 16, 160)
    local info_font_size = clamp(math.floor(vp_h * config.info_rel_size   + 0.5), 12, 96)
    local border_width   = clamp(math.floor(vp_h * config.tc_border_rel   + 0.5), 0, 8)
    local bar_height     = clamp(math.floor(vp_h * config.bar_height_rel  + 0.5), 2, 32)

    -- Calculate layout positions
    local centre_x    = math.floor(safe_left + safe_width / 2)
    local tc_y        = math.floor(safe_bottom - vp_h * (config.bar_gap_rel + config.bar_height_rel) - tc_font_size * 0.5)
    local bar_y_top   = safe_bottom - bar_height
    local bar_y_bottom= safe_bottom

    -- ========================================
    -- Progress Bar
    -- ========================================
    if config.mode ~= 'minimal' and duration and duration > 0 then
        -- Bar width (60% of safe width, centred)
        local bar_width = math.floor(safe_width * 0.6)
        local bar_left  = math.floor(centre_x - bar_width / 2)
        local bar_right = bar_left + bar_width

        -- Defensive: ensure coordinates are valid
        if bar_left < bar_right and bar_y_top < bar_y_bottom then
            -- Background bar
            ass:new_event()
            ass:append('{\\an7\\pos(0,0)\\bord0\\shad0\\p1}')
            ass:append(ass_colour(config.colours.bar_bg, config.opacity.bar_bg))
            ass:draw_start()
            ass:rect_cw(bar_left, bar_y_top, bar_right, bar_y_bottom)
            ass:draw_stop()
            ass:append('{\\p0}') -- reset path after drawing

            -- Foreground progress bar
            if progress_pct > 0 then
                local progress_width = math.floor(bar_width * (progress_pct / 100) + 0.5)
                local progress_right = bar_left + progress_width

                if progress_right > bar_left then
                    ass:new_event()
                    ass:append('{\\an7\\pos(0,0)\\bord0\\shad0\\p1}')
                    ass:append(ass_colour(config.colours.bar_fg, config.opacity.bar_fg))
                    ass:draw_start()
                    ass:rect_cw(bar_left, bar_y_top, progress_right, bar_y_bottom)
                    ass:draw_stop()
                    ass:append('{\\p0}') -- reset path after drawing
                end
            end
        end
    end

    -- ========================================
    -- Main Timecode Display
    -- ========================================
    if config.mode ~= 'minimal' and time_pos then
        local tc_string, is_df = format_timecode(time_pos, fps)
        local df_indicator = is_df and ' DF' or ' NDF'

        ass:new_event()
        ass:append(string.format('{\\an8\\pos(%d,%d)\\fs%d%s%s\\shad2}',
            centre_x, tc_y, tc_font_size,
            ass_colour(config.colours.tc_fg, config.opacity.tc_fg),
            ass_border(config.colours.tc_border, border_width)))
        ass:append(tc_string)
        ass:append(string.format('{\\fs%d}', math.floor(tc_font_size * 0.3)))
        ass:append(df_indicator)
    end

    -- ========================================
    -- Information Overlay (Broadcast Style)
    -- ========================================
    if config.mode == 'full' and time_pos and duration then
        local info_x = safe_left
        local info_y = safe_top
        local line_height = math.floor(info_font_size * 1.15)

        local function add_info_line(text)
            ass:new_event()
            ass:append(string.format('{\\an7\\pos(%d,%d)\\fs%d%s\\bord2\\shad1}',
                info_x, info_y, info_font_size,
                ass_colour(config.colours.info_fg, config.opacity.info_fg)))
            ass:append(text)
            info_y = info_y + line_height
        end

        -- Elapsed time
        if config.show_elapsed then
            add_info_line(string.format('ELAPSED: %s', format_duration(time_pos)))
        end

        -- Remaining time
        if config.show_countdown then
            local remaining = math.max(0, (duration or 0) - (time_pos or 0))
            add_info_line(string.format('REMAIN:  -%s', format_duration(remaining)))
        end

        -- Total duration
        if config.show_duration and duration then
            add_info_line(string.format('TOTAL:   %s', format_duration(duration)))
        end

        -- Framerate with DF/NDF indicator
        if config.show_fps and fps then
            local _, is_df_meta = get_fps_info(fps)
            add_info_line(string.format('%.2f fps %s', fps, is_df_meta and '(DF)' or '(NDF)'))
        end

        -- Filename (optional, off by default)
        if config.show_filename then
            local filename = mp.get_property('filename', '')
            if filename ~= '' then add_info_line(filename) end
        end
    end

    -- ========================================
    -- Minimal Mode (Corner Timecode)
    -- ========================================
    if config.mode == 'minimal' and time_pos then
        local tc_string = (function(ts, f) local s = format_timecode(ts, f); return s end)(time_pos, fps)
        ass:new_event()
        ass:append(string.format('{\\an7\\pos(%d,%d)\\fs%d%s\\bord2}',
            safe_left, safe_top, info_font_size,
            ass_colour(config.colours.tc_fg, config.opacity.tc_fg)))
        ass:append(tc_string)
    end

    -- Commit overlay to display
    state.overlay.data = ass.text
    state.overlay:update()
    state.needs_update = false
end

-- ============================================================================
-- Event-Driven Update System
-- ============================================================================

--- Request overlay update on next render cycle
local function request_update()
    if not state.needs_update then
        state.needs_update = true
        mp.add_timeout(0, render_overlay)
    end
end

--- Handle dimension changes
local function on_dimensions_change(_, dims)
    if dims then
        state.last_dimensions = dims
        request_update()
    end
end

--- Handle pause state changes
local function on_pause_change(_, paused)
    state.is_paused = paused
    if not paused then
        request_update()
    end
end

--- Handle time position changes
local function on_time_change()
    if not state.is_paused and config.mode ~= 'off' then
        request_update()
    end
end

-- ============================================================================
-- User Interface Controls
-- ============================================================================

--- Cycle through display modes
-- Sequence: full → tc_only → minimal → off → full
local function cycle_mode()
    local modes = {'full', 'tc_only', 'minimal', 'off'}
    local current_index = 1
    
    for i, mode in ipairs(modes) do
        if mode == config.mode then
            current_index = i
            break
        end
    end
    
    local next_index = (current_index % #modes) + 1
    config.mode = modes[next_index]
    
    mp.osd_message(string.format('Timecode Display: %s', config.mode:upper()), 1.5)
    request_update()
end

--- Toggle countdown display
local function toggle_countdown()
    config.show_countdown = not config.show_countdown
    mp.osd_message(string.format('Countdown: %s',
        config.show_countdown and 'ON' or 'OFF'), 1)
    request_update()
end

-- ============================================================================
-- Initialisation and Registration
-- ============================================================================

--- Clean up on file end
local function cleanup()
    if state.overlay then
        state.overlay:remove()
        state.overlay = nil
    end
    state.needs_update = false
end

--- Initialise on file load
local function initialise()
    cleanup()
    state.needs_update = true
    request_update()
end

-- Register event handlers (efficient, event-driven approach)
mp.observe_property('osd-dimensions', 'native', on_dimensions_change)
mp.observe_property('pause', 'bool', on_pause_change)
mp.observe_property('time-pos', 'number', on_time_change)
mp.observe_property('fullscreen', 'bool', request_update)
mp.observe_property('window-scale', 'number', request_update)

mp.register_event('file-loaded', initialise)
mp.register_event('end-file', cleanup)

-- Register keybindings
mp.add_key_binding('t', 'cycle_timecode_mode', cycle_mode)
mp.add_key_binding('T', 'toggle_countdown', toggle_countdown)

-- Register script messages for external control
mp.register_script_message('cycle_mode', cycle_mode)
mp.register_script_message('toggle_countdown', toggle_countdown)

-- Initial render
if config.mode ~= 'off' then
    request_update()
end

mp.msg.info('Superimposed timecode loaded. Press "t" to cycle modes.')