---@class (exact) FilterGuiItemData : GuiItemData
---@field filtered_array string[]
---@field filtered_map string[]

local item_data = require("FieldEventSpawner.util.imgui.item_def.item_data")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class FilterGuiItemData
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = item_data })

---@return FilterGuiItemData
function this:new()
    local o = item_data:new()
    o.filtered_array = {}
    o.filtered_map = {}
    setmetatable(o, self)
    ---@cast o FilterGuiItemData
    return o
end

---@param predicate fun(map_value: string): boolean
function this:filter(predicate)
    util_table.clear(self.filtered_array)
    util_table.clear(self.filtered_map)

    for i = 1, #self.map do
        local key = self.map[i]
        local value = self.array[i]
        if predicate(key) then
            table.insert(self.filtered_array, value)
            table.insert(self.filtered_map, key)
        end
    end
end

function this:clear()
    util_table.clear(self.filtered_array)
    util_table.clear(self.filtered_map)
    util_table.clear(self.array)
    util_table.clear(self.map)
end

return this
