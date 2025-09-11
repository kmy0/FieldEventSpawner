---@class (exact) GuiItemData
---@field array string[]
---@field map string[]

local util_table = require("FieldEventSpawner.util.misc.table")

---@class GuiItemData
local this = {}
---@diagnostic disable-next-line: inject-field
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
    util_table.clear(self.array)
    util_table.clear(self.map)
end

function this:empty()
    return util_table.empty(self.array)
end

return this
