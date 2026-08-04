---@class (exact) AreaEventData : EventData, SerialClass
---@field map table<app.FieldDef.STAGE, MapData>
---@field type app.EX_FIELD_EVENT_TYPE

---@class (exact) EventData
---@field id any
---@field name_english string
---@field name_local string

---@class SerialClass
---@field __type string

---@class (exact) MapData
---@field stage app.FieldDef.STAGE
---@field area_by_env table<app.EnvironmentType.ENVIRONMENT, integer[]>
---@field area integer[]

local e = require("FieldEventSpawner.util.game.enum")

---@class AreaEventData
local this = {}
---@diagnostic disable-next-line: inject-field
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
        __type = "__AreaEventData",
    }
    setmetatable(o, self)
    ---@cast o AreaEventData
    return o
end

---@param serialized_class table
---@return AreaEventData
function this:new_from_serial(serialized_class)
    local o = setmetatable(serialized_class, self)
    ---@cast o AreaEventData
    return o
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
---@param args {
--- area_by_env: table<app.EnvironmentType.ENVIRONMENT, integer[]>?,
--- area: integer[]?,
--- }?
---@return MapData
function this:add_map(stage, args)
    if self.map[stage] then
        return self.map[stage]
    end

    args = args or {}
    self.map[stage] = {
        area_by_env = args.area_by_env or {},
        area = args.area or {},
        stage = stage,
    }

    return self.map[stage]
end

---@return boolean
function this:is_monster_event()
    return self.type == e.get("app.EX_FIELD_EVENT_TYPE").POP_EM
end

---@return boolean
function this:is_animal_event()
    return self.type == e.get("app.EX_FIELD_EVENT_TYPE").ANIMAL_EVENT
end

---@return boolean
function this:is_gimmick_event()
    return self.type == e.get("app.EX_FIELD_EVENT_TYPE").GIMMICK_EVENT
end

return this
