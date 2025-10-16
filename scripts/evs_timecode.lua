
-- evs_timecode.lua – Professional broadcast timecode display (EVS-style)
-- Supports all common framerates with proper drop-frame handling
-- Large centered bottom TC + progress bar + optional countdown

local mp = require 'mp'
local assdraw = require 'mp.assdraw'

local opts = {
    mode = 'full',
    
    tc_size = 72,
    tc_color = 'FFFFFF',
    tc_border = 3,
    tc_shadow = 2,
    
    bar_height = 8,
    bar_margin = 20,
    bar_color_fg = '00FF00',
    bar_color_bg = '404040',
    
    info_size = 32,
    info_color = 'FFFF00',
    show_countdown = true,
    show_elapsed = true,
    show_duration = true,
    show_fps = true,
    
    refresh = 0.05,
}

local timer = nil
local screen_w, screen_h = 1920, 1080

local function is_close(a, b, eps)
    return math.abs(a - b) < (eps or 0.01)
end

local function get_fps_info(fps)
    if is_close(fps, 23.976, 0.01) then
        return 24, true, ';'
    elseif is_close(fps, 29.97, 0.01) then
        return 30, true, ';'
    elseif is_close(fps, 59.94, 0.02) then
        return 60, true, ';'
    elseif is_close(fps, 119.88, 0.05) then
        return 120, true, ';'
    else
        return math.floor(fps + 0.5), false, ':'
    end
end

local function calc_dropframe(frames, fps_rounded, is_df)
    if not is_df then return frames end
    
    local drop_per_min = (fps_rounded == 60 or fps_rounded == 120) and 4 or 2
    if fps_rounded == 120 then drop_per_min = 8 end
    
    local fpm = fps_rounded * 60
    local fp10m = fps_rounded * 600
    
    local d = frames
    local ten_min = math.floor(d / fp10m)
    local rem10 = d % fp10m
    
    local dropped = ten_min * (drop_per_min * 9)
    
    local mins = math.floor(rem10 / fpm)
    if mins > 0 then
        local extra_drop = drop_per_min * (mins - math.floor(mins / 10))
        dropped = dropped + extra_drop
    end
    
    return frames + dropped
end

local function format_timecode(seconds, fps)
    if not seconds or seconds < 0 then
        return "--:--:--:--", false, ':'
    end
    
    local fps_rounded, is_df, sep = get_fps_info(fps)
    local total_frames = math.floor(seconds * fps + 0.5)
    
    local frames = calc_dropframe(total_frames, fps_rounded, is_df)
    
    local h = math.floor(frames / (fps_rounded * 3600))
    local rem = frames % (fps_rounded * 3600)
    local m = math.floor(rem / (fps_rounded * 60))
    rem = rem % (fps_rounded * 60)
    local s = math.floor(rem / fps_rounded)
    local f = rem % fps_rounded
    
    return string.format("%02d:%02d:%02d%s%02d", h, m, s, sep, f), is_df, sep
end

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

local function build_overlay()
    if opts.mode == 'off' then return "" end
    
    local time_pos = mp.get_property_number("time-pos")
    local duration = mp.get_property_number("duration")
    local fps = mp.get_property_number("container-fps") 
             or mp.get_property_number("fps") 
             or 25
    
    local osd_w = mp.get_property_number("osd-width", 1920)
    local osd_h = mp.get_property_number("osd-height", 1080)
    screen_w, screen_h = osd_w, osd_h
    
    local ass = assdraw.ass_new()
    
    if opts.mode ~= 'minimal' and time_pos then
        local tc, is_df, sep = format_timecode(time_pos, fps)
        local df_indicator = is_df and " DF" or " NDF"
        
        local tc_y = osd_h - (osd_h * 0.15)
        
        ass:new_event()
        ass:an(8)
        ass:pos(osd_w / 2, tc_y)
        ass:append(string.format("{\\fs%d\\bord%d\\shad%d\\c&H%s&}", 
                   opts.tc_size, opts.tc_border, opts.tc_shadow, opts.tc_color))
        ass:append(tc)
        
        ass:append(string.format("{\\fs%d}", math.floor(opts.tc_size * 0.3)))
        ass:append(df_indicator)
        
        if duration and duration > 0 and opts.mode == 'full' then
            local progress = time_pos / duration
            local bar_y = tc_y - opts.tc_size - opts.bar_margin
            local bar_w = osd_w * 0.6
            local bar_x = (osd_w - bar_w) / 2
            
            ass:new_event()
            ass:pos(0, 0)
            ass:draw_start()
            ass:append(string.format("{\\c&H%s&\\bord0}", opts.bar_color_bg))
            ass:rect_cw(bar_x, bar_y, bar_x + bar_w, bar_y + opts.bar_height)
            ass:draw_stop()
            
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
    
    if opts.mode == 'full' and time_pos and duration then
        local info_lines = {}
        
        if opts.show_elapsed then
            table.insert(info_lines, "ELAPSED: " .. format_duration(time_pos))
        end
        
        if opts.show_countdown then
            local remaining = duration - time_pos
            table.insert(info_lines, "REMAIN: -" .. format_duration(remaining))
        end
        
        if opts.show_duration then
            table.insert(info_lines, "TOTAL: " .. format_duration(duration))
        end
        
        if opts.show_fps then
            local _, is_df = get_fps_info(fps)
            local fps_str = string.format("%.2f fps %s", fps, is_df and "(DF)" or "(NDF)")
            table.insert(info_lines, fps_str)
        end
        
        local filename = mp.get_property("filename", "")
        table.insert(info_lines, filename)
        
        local info_y = 40
        for i, line in ipairs(info_lines) do
            ass:new_event()
            ass:an(7)
            ass:pos(30, info_y + (i-1) * (opts.info_size + 5))
            ass:append(string.format("{\\fs%d\\bord2\\shad1\\c&H%s&}", 
                       opts.info_size, opts.info_color))
            ass:append(line)
        end
    end
    
    if opts.mode == 'minimal' and time_pos then
        local tc = format_timecode(time_pos, fps)
        ass:new_event()
        ass:an(7)
        ass:pos(20, 20)
        ass:append(string.format("{\\fs%d\\bord2\\c&HFFFFFF&}", opts.info_size))
        ass:append(tc)
    end
    
    return ass.text
end

local function update_display()
    if opts.mode == 'off' then
        mp.set_osd_ass(screen_w, screen_h, "")
        return
    end
    
    local overlay = build_overlay()
    mp.set_osd_ass(screen_w, screen_h, overlay)
end

local function start_timer()
    if timer then timer:kill() end
    timer = mp.add_periodic_timer(opts.refresh, update_display)
    update_display()
end

local function stop_timer()
    if timer then 
        timer:kill() 
        timer = nil 
    end
    mp.set_osd_ass(screen_w, screen_h, "")
end

local function cycle_mode()
    local modes = {'full', 'tc_only', 'minimal', 'off'}
    local current_idx = 1
    for i, m in ipairs(modes) do
        if m == opts.mode then current_idx = i; break end
    end
    
    local next_idx = (current_idx % #modes) + 1
    opts.mode = modes[next_idx]
    
    mp.osd_message("TC Display: " .. opts.mode:upper(), 1.5)
    
    if opts.mode == 'off' then
        stop_timer()
    else
        if not timer then start_timer() end
        update_display()
    end
end

local function toggle_countdown()
    opts.show_countdown = not opts.show_countdown
    mp.osd_message("Countdown: " .. (opts.show_countdown and "ON" or "OFF"), 1)
    update_display()
end

mp.observe_property("time-pos", "number", function()
    if opts.mode ~= 'off' then update_display() end
end)

mp.register_event("file-loaded", function()
    if opts.mode ~= 'off' then start_timer() end
end)

mp.register_event("end-file", function()
    stop_timer()
end)

mp.register_script_message("cycle_mode", cycle_mode)
mp.register_script_message("toggle_countdown", toggle_countdown)

if opts.mode ~= 'off' then
    start_timer()
end

mp.msg.info("EVS-style timecode display loaded. Press 't' to cycle modes.")

