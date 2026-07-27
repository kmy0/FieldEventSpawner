---@class AnimalGimmickData : AreaEventData
---@field map table<app.FieldDef.STAGE, AnimalGimmickMapData>

---@class (exact) AnimalGimmickMapData : MapData
---@field area_to_area_fixed table<integer, integer>

local area_event_base = require("FieldEventSpawner.data.def.area_event_base")

---@class AnimalGimmickData
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = area_event_base })

---@param name_english string
---@param name_local string
---@param type app.EX_FIELD_EVENT_TYPE
---@return AnimalGimmickData
function this:new(name_english, name_local, type)
    local o = area_event_base.new(self, name_english, name_local, type)
    setmetatable(o, self)
    ---@cast o AnimalGimmickData
    o.__type = "__AnimalGimmickData"

    return o
end

---@param stage app.FieldDef.STAGE
---@param area integer
---@return integer
function this:get_area_fixed(stage, area)
    return self.map[stage].area_to_area_fixed[area]
end

---@param stage app.FieldDef.STAGE
---@param args {
--- area_by_env: table<app.EnvironmentType.ENVIRONMENT, integer[]>?,
--- area: integer[]?,
--- area_to_area_fixed: table<integer, integer>?,
--- }?
---@return AnimalGimmickMapData
function this:add_map(stage, args)
    if self.map[stage] then
        return self.map[stage]
    end

    args = args or {}
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.map[stage] = area_event_base.add_map(self, stage, args)
    self.map[stage].area_to_area_fixed = args.area_to_area_fixed or {}

    return self.map[stage]
end

return this
