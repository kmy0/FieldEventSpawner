---@class (exact) AnimalEventFactory : AreaEventFactory
---@field event_data AnimalData

---@class (exact) AnimalEventFactoryOptionalArgs : AreaEventFactoryOptionalArgs
---@field ignore_environ_type boolean?

--[[ app.cExFieldEvent_AnimalEvent
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
    _FreeMiniValue6 = 1 if visible for summary
]]

local e = require("FieldEventSpawner.util.game.enum")
local factory = require("FieldEventSpawner.events.area_event_factory")
local mod = require("FieldEventSpawner.data.mod")

local sched = require("FieldEventSpawner.schedule.init")

---@class AnimalEventFactory
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = factory })

---@param animal_data AnimalData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param opts AnimalEventFactoryOptionalArgs?
---@return AnimalEventFactory
function this:new(animal_data, stage, time, opts)
    opts = opts or {}
    local o = factory.new(self, animal_data, stage, time, opts)
    setmetatable(o, self)
    o._area_array = animal_data:get_area_array(
        stage,
        not opts.ignore_environ_type and mod.get_environ(stage) or nil
    )
    ---@cast o AnimalEventFactory
    return o
end

---@return SpawnResult, SpawnEvent?
function this:build()
    local environ_type = mod.get_environ(self.stage)
    local event_type = e.get("app.EX_FIELD_EVENT_TYPE").ANIMAL_EVENT

    ---@param event app.cExFieldEventBase
    ---@return boolean
    local function predicate(event)
        return event:get_ExFieldEventType() == event_type
    end

    local other_events = self:_get_other_events(predicate)
    local area = self.area and self.area or self:_get_area(other_events, self._area_array)

    if not area then
        return mod.enum.spawn_result.NO_AREA
    end

    local event_data = sched.util.create_event_data()
    event_data._EventType = event_type
    event_data._FreeValue0 = e.to_fixed("app.FieldDef.STAGE_Fixed", self.stage)
    event_data._FreeValue1 = self.event_data.id
    event_data._FreeValue2 = self.event_data:get_area_fixed(self.stage, area)
    event_data._FreeMiniValue0 = area
    event_data._FreeMiniValue1 = self.time
    event_data._FreeMiniValue2 = environ_type
    event_data._FreeMiniValue6 = 1
    event_data._ExecMinute = self._schedule_timeline:get_AdvancedGameMinute() + self.spawn_delay

    local collision_flag = mod.enum.event_collision_flag.ID
        | mod.enum.event_collision_flag.AREA
        | mod.enum.event_collision_flag.TIME
    return mod.enum.spawn_result.OK,
        sched.spawn_event.make_event(
            event_data,
            self.event_data.name_local,
            area,
            { collision_flag = collision_flag }
        )
end

return this
