---@class (exact) GuiItemData
---@field array string[]
---@field map string[]
---@field protected __index GuiItemData

local table_util = require("FieldEventSpawner.table_util")

---@class GuiItemData
local this = {}
this.__index = this

function this:new()
    local o = {
        array = {},
        map = {},
    }
    setmetatable(o, self)
    return o
end

function this:clear()
    table_util.clear(self.array)
    table_util.clear(self.map)
end

function this:empty()
    return table_util.empty(self.array)
end

return this
