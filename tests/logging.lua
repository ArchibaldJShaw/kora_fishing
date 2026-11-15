-- Run from kora_fishing: lua tests/logging.lua
-- A failed purchase refund must reach Kora.logging.error (event + error in fields), never print.
local calls, handlers = {}, {}
local env = setmetatable({}, { __index = _G })
env._G = env
env.source = 1
env.print = function() error('shops.lua must log through Kora.logging, not print') end
env.RegisterNetEvent = function(name, fn) handlers[name] = fn end
env.Config = { Shop = {
    locations = { { coords = { x = 0, y = 0, z = 0 } } },
    items = { { name = 'fishing_rod', price = 100 } },
} }
env.Kora = {
    callback = { register = function() end },
    distance = { player = function() return true end },
    logging = { error = function(event, message, fields)
        calls[#calls + 1] = { level = 'error', event = event, message = message, fields = fields }
        return true
    end },
}
env.exports = {
    kora_core = {
        removeMoney = function() return true end,
        addMoney = function() return false, 'refund unavailable' end,
    },
    kora_inventory = { addItem = function() return false, 'no free slot' end },
}
assert(loadfile('server/shops.lua', 't', env))()
handlers['kora_fishing:server:purchaseItem'](1, 1, 1)
local call = assert(calls[1], 'a logger call was made')
assert(call.level == 'error' and call.event == 'shop.refund_failed', 'stable error event name')
assert(tostring(call.fields.error):find('refund unavailable', 1, true), 'logger fields carry the error')
print('kora_fishing: refund failure is logged through Kora.logging')
