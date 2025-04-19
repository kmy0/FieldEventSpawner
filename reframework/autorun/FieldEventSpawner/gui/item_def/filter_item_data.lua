---@class FilterGuiItemData : GuiItemData
---@field filtered_array string[]
---@field filtered_map string[]
---@field protected __index FilterGuiItemData

local item_data = require("FieldEventSpawner.gui.item_def.item_data")
local table_util = require("FieldEventSpawner.table_util")

---@class FilterGuiItemData
local this = {}
this.__index = this
setmetatable(this, { __index = item_data })

---@return FilterGuiItemData
function this:new()
    local o = item_data:new()
    o.filtered_array = {}
    o.filtered_map = {}
    setmetatable(o, self)
    return o
end

---@param predicate fun(map_value: string): boolean
function this:filter(predicate)
    table_util.clear(self.filtered_array)
    table_util.clear(self.filtered_map)

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
    table_util.clear(self.filtered_array)
    table_util.clear(self.filtered_map)
    table_util.clear(self.array)
    table_util.clear(self.map)
end

return this
