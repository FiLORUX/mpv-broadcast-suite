-- These label values cover boundaries independently of the overlay renderer.
local cases = {
    { 30, 1800, '00:01:00;02' },
    { 30, 3598, '00:02:00;02' },
    { 30, 17982, '00:10:00;00' },
    { 30, 107892, '01:00:00;00' },
    { 60, 3600, '00:01:00;04' },
    { 60, 7196, '00:02:00;04' },
    { 60, 35964, '00:10:00;00' },
    { 60, 215784, '01:00:00;00' },
}
for _, case in ipairs(cases) do
    local fps, frame, expected = case[1], case[2], case[3]
    local count = calc_dropframe(frame, fps, true)
    local hours = math.floor(count / (fps * 3600))
    local minutes = math.floor(count / (fps * 60)) % 60
    local seconds = math.floor(count / fps) % 60
    local frames = count % fps
    local actual = string.format('%02d:%02d:%02d;%02d', hours, minutes, seconds, frames)
    assert(actual == expected, string.format('%d fps frame %d: expected %s, got %s', fps, frame, expected, actual))
end
assert(calc_dropframe(3598, 30, false) == 3598)
print('Drop-frame boundary tests passed')
