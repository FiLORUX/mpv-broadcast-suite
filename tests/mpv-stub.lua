local mock = { tags = {}, fps = 30000 / 1001, events = {}, messages = {}, timers = {} }
local mp_stub = { msg = { info = function() end, warn = function() end } }
function mp_stub.get_property_native(name)
    if name == 'metadata' then return mock.tags end
    if name == 'osd-dimensions' then return { w = 1920, h = 1080, ml = 0, mr = 0, mt = 0, mb = 0 } end
end
function mp_stub.get_property_number(name)
    if name == 'container-fps' then return mock.fps end
    if name == 'time-pos' then return 3598 / (30000 / 1001) end
    if name == 'duration' then return 300 end
    return 0
end
function mp_stub.get_property() return '' end
function mp_stub.observe_property() end
function mp_stub.register_event(name, fn) mock.events[name] = fn end
function mp_stub.register_script_message(name, fn) mock.messages[name] = fn end
function mp_stub.add_key_binding() end
function mp_stub.add_timeout(_, fn) table.insert(mock.timers, fn) end
function mp_stub.osd_message() end
function mp_stub.create_osd_overlay()
    local overlay = { update = function() end, remove = function() end }
    mock.overlay = overlay
    return overlay
end
local assdraw_stub = {}
function assdraw_stub.ass_new()
    local ass = { text = '' }
    function ass:append(text) self.text = self.text .. text end
    for _, name in ipairs({ 'new_event', 'pos', 'draw_start', 'rect_cw', 'draw_stop', 'an' }) do
        ass[name] = function() end
    end
    return ass
end
package.preload['mp'] = function() return mp_stub end
package.preload['mp.assdraw'] = function() return assdraw_stub end
