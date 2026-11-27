assert(#mock.timers > 0, 'initial render must be scheduled')
local function expect(seconds, fps, expected, expected_mode)
    local actual, mode = format_timecode(seconds, fps)
    assert(actual == expected, 'expected ' .. expected .. ', got ' .. actual)
    assert(mode == expected_mode)
end
expect(3598 / mock.fps, mock.fps, '--:--:--:--', nil)
render_overlay()
assert(mock.overlay.data:find('TC MODE?', 1, true), 'unknown mode must be visible')
mock.tags = { timecode = '01:00:00;00' }
expect(3598 / mock.fps, mock.fps, '00:02:00;02', true)
mock.tags = { TIMECODE = '01:00:00:00' }
expect(3598 / mock.fps, mock.fps, '00:01:59:28', false)
mock.tags = { timecode = '00:01:00;00' }
expect(0, mock.fps, '--:--:--:--', nil)
mock.tags = { timecode = '01:00:00;00' }
expect(0, 30, '--:--:--:--', nil)
mock.tags = {}
mock.messages.cycle_timecode_standard()
expect(3598 / mock.fps, mock.fps, '00:02:00;02', true)
mock.messages.cycle_timecode_standard()
expect(3598 / mock.fps, mock.fps, '00:01:59:28', false)
mock.events['file-loaded']()
expect(0, mock.fps, '--:--:--:--', nil)
mock.tags = { timecode = '00:00:00:00', TIMECODE = '00:00:00;00' }
expect(0, mock.fps, '--:--:--:--', nil)
print('Overlay mode tests passed')
