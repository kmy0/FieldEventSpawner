---@class Timer
---@field key string
---@field start_time integer
---@field limit integer
---@field now integer
---@field protected _finished boolean
---@field protected _instances table<string, Timer>

local util = require("FieldEventSpawner.util")

---@class Timer
local this = {}
this.__index = this
this._instances = {}

---@param key string
---@param limit integer
function this.new(key, limit)
    local now = util.getUTCTime:call(nil)
    local o = {
        key = key,
        start_time = now,
        now = now,
        limit = limit,
    }
    setmetatable(o, this)
    ---@cast o Timer
    this._instances[key] = o
    return o
end

---@param key string
---@return integer
function this.remaining_key(key)
    local timer = this._instances[key]
    if not timer or timer:finished() then
        return 0
    end
    return timer:remaining()
end

function this:update()
    self.now = util.getUTCTime:call(nil)
    return self.now
end

---@return integer
function this:elapsed()
    return self:update() - self.start_time
end

function this:remaining()
    return self.limit - self:elapsed()
end

---@return boolean
function this:finished()
    if self._finished then
        return self._finished
    end
    self._finished = self:elapsed() >= self.limit
    return self._finished
end

function this:stop()
    self._finished = true
end

---@param key string
function this.stop_key(key)
    local timer = this._instances[key]
    if timer then
        timer:stop()
    end
end

return this
