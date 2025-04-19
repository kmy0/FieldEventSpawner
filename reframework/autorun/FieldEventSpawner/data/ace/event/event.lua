---@class (exact) MapData
---@field stage app.FieldDef.STAGE
---@field area_by_env table<app.EnvironmentType.ENVIRONMENT, integer[]>
---@field area integer[]
---@field area_to_area_fixed table<integer, integer>

---@class (exact) EventData
---@field id any
---@field name_english string
---@field name_local string

---@class (exact) AreaEventData : EventData
---@field map table<app.FieldDef.STAGE, MapData>
---@field type app.EX_FIELD_EVENT_TYPE
---@field protected __index AreaEventData
---@field map_data_ctor fun(stage: app.FieldDef.STAGE): MapData

---@class AreaEventData
local this = {}
this.__index = this

---@param name_english string
---@param name_local string
---@param type app.EX_FIELD_EVENT_TYPE
---@return AreaEventData
function this:new(name_english, name_local, type)
    local o = {
        name_english = name_english,
        name_local = name_local,
        map = {},
        type = type,
    }
    setmetatable(o, self)
    return o
end

---@param stage app.FieldDef.STAGE
---@param area integer
---@return integer
function this:get_area_fixed(stage, area)
    return self.map[stage].area_to_area_fixed[area]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@return integer[]?
function this:get_area_array(stage, environ)
    local map = self.map[stage]
    if not map then
        return
    end

    if environ then
        return map.area_by_env[environ]
    end
    return map.area
end

---@param stage app.FieldDef.STAGE
---@return MapData
function this.map_data_ctor(stage)
    ---@type MapData
    return {
        stage = stage,
        area_by_env = {},
        area = {},
        area_to_area_fixed = {},
    }
end

return this
