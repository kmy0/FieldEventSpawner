---@class (exact) AnimalEventFactory : AreaEventFactory
---@field event_data AnimalData
---@field protected __index AnimalEventFactory

--[[
    _FreeValue0 = app.FieldDef.STAGE_Fixed
    _FreeValue1 = app.ExDef.ANIMAL_EVENT_Fixed
    _FreeValue2 = app.FieldDef.AREAD_ID_Fixed
    _FreeValue3 = unused
    _FreeValue4 = unused
    _FreeValue5 = unused
    _FreeMiniValue0 = AreaNo
    _FreeMiniValue1 = Countdown starting point in minutes
    _FreeMiniValue2 = app.EnvironmentType.ENVIRONMENT
    _FreeMiniValue3 = unused
    _FreeMiniValue4 = unused
    _FreeMiniValue5 = unused
    _FreeMiniValue6 = unused
]]

local data = require("FieldEventSpawner.data")
local factory = require("FieldEventSpawner.events.area_event_factory")
local sched = require("FieldEventSpawner.schedule")
local util = require("FieldEventSpawner.util")

local rl = data.util.reverse_lookup
local rt = data.runtime
local ace = data.ace

---@class AnimalEventFactory
local this = {}
this.__index = this
setmetatable(this, { __index = factory })

---@param animal_data AnimalData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param ignore_environ_type boolean
---@param area integer?
---@return AnimalEventFactory
function this:new(animal_data, stage, time, ignore_environ_type, area)
    local o = factory.new(self, animal_data, stage, time, ignore_environ_type, area)
    setmetatable(o, self)
    o._area_array = animal_data:get_area_array(stage, not ignore_environ_type and rt.get_environ(stage) or nil)
    ---@cast o AnimalEventFactory
    return o
end

---@return SpawnResult, SpawnEvent?
function this:build()
    local environ_type = rt.get_environ(self.stage)
    local event_type = rl(ace.enum.ex_event, "ANIMAL_EVENT")

    ---@param event app.cExFieldEventBase
    ---@return boolean
    local function predicate(event)
        return event:get_ExFieldEventType() == event_type
    end

    local other_events = self:_get_other_events(predicate)
    local area = self.area and self.area or self:_get_area(other_events, self._area_array)

    if not area then
        return rt.enum.spawn_result.NO_AREA
    end

    local event_data = sched.util.create_event_data()
    event_data._EventType = event_type
    event_data._FreeValue0 = util.get_stage_id_fixed(self.stage)
    event_data._FreeValue1 = self.event_data.id
    event_data._FreeValue2 = self.event_data:get_area_fixed(self.stage, area)
    event_data._FreeMiniValue0 = area
    event_data._FreeMiniValue1 = self.time
    event_data._FreeMiniValue2 = environ_type
    local collision_flag = rt.enum.event_collision_flag.ID
        | rt.enum.event_collision_flag.AREA
        | rt.enum.event_collision_flag.TIME
    return rt.enum.spawn_result.OK, sched.spawn_event.ctor(event_data, self.event_data.name_local, area, collision_flag)
end

return this
