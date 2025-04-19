---@class (exact) GimmickEventFactory : AreaEventFactory
---@field event_data GimmickData
---@field protected __index AreaEventFactory

--[[
    _FreeValue0 = app.FieldDef.STAGE_Fixed
    _FreeValue1 = app.ExDef.GIMMICK_EVENT_Fixed
    _FreeValue2 = app.FieldDef.AREAD_ID_Fixed
    _FreeValue3 = app.user_data.ExFieldParam.cAssistNpcParam Guid hash when ASSIST_NPC, otherwise unused
    _FreeValue4 = unused
    _FreeValue5 = unused
    _FreeMiniValue0 = AreaNo
    _FreeMiniValue1 = Countdown starting point in minutes
    _FreeMiniValue2 = app.EnvironmentType.ENVIRONMENT, 255 when ASSIST_NPC
    _FreeMiniValue3 = unused
    _FreeMiniValue4 = unused
    _FreeMiniValue5 = unused
    _FreeMiniValue6 =
        evt_t = app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE
        _FreeMiniValue6 = 0
        if evt_t == ASSIST_NPC then
            _FreeMiniValue6 |= 2
        elseif evt_t == RARE_TOKUSAN then
            _FreeMiniValue6 |= 1
        elseif evt_t == NONE then
            _FreeMiniValue6 |= 0
        elseif evt_t == ANCIENT_COIN then
            _FreeMiniValue6 |= 4
        end
]]

local data = require("FieldEventSpawner.data")
local factory = require("FieldEventSpawner.events.area_event_factory")
local sched = require("FieldEventSpawner.schedule")
local util = require("FieldEventSpawner.util")

local rl = data.util.reverse_lookup
local rt = data.runtime
local ace = data.ace

---@class GimmickEventFactory
local this = {}
this.__index = this
setmetatable(this, { __index = factory })

---@param gimmick_data GimmickData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param ignore_environ_type boolean
---@param area integer?
---@return GimmickEventFactory
function this:new(gimmick_data, stage, time, ignore_environ_type, area)
    local o = factory.new(self, gimmick_data, stage, time, ignore_environ_type, area)
    setmetatable(o, self)
    o._area_array = gimmick_data:get_area_array(stage, not ignore_environ_type and rt.get_environ(stage) or nil)
    ---@cast o GimmickEventFactory
    return o
end

---@return SpawnResult, SpawnEvent[]?
function this:build()
    local environ_type = rt.get_environ(self.stage)
    local event_ex_name = ace.enum.ex_gimmick[self.event_data.ex_id]
    local event_type = rl(ace.enum.ex_event, "GIMMICK_EVENT")
    local event_flag = ace.map.ex_gimmick_to_flag[event_ex_name]
    local guid_hash = 0

    ---@param event app.cExFieldEventBase
    ---@return boolean
    local function predicate(event)
        return event:get_ExFieldEventType() == event_type and event._FreeMiniValue6 >> 0 == event_flag
    end

    local other_events = self:_get_other_events(predicate)
    local area = self.area and self.area or self:_get_area(other_events, self._area_array)

    if not area then
        return rt.enum.spawn_result.NO_AREA
    end

    if event_ex_name == "ASSIST_NPC" then
        local gimmick_data = self.event_data
        ---@cast gimmick_data NpcData
        guid_hash = util.hash_guid(gimmick_data.guid)
    end

    local event_data = sched.util.create_event_data()
    event_data._EventType = event_type
    event_data._FreeValue0 = util.get_stage_id_fixed(self.stage)
    event_data._FreeValue1 = self.event_data.id
    event_data._FreeValue2 = self.event_data:get_area_fixed(self.stage, area)
    event_data._FreeValue3 = guid_hash
    event_data._FreeMiniValue0 = area
    event_data._FreeMiniValue1 = self.time
    event_data._FreeMiniValue2 = event_ex_name == "ASSIST_NPC" and 255 or environ_type
    event_data._FreeMiniValue6 = event_flag

    local collision_flag = rt.enum.event_collision_flag.ID
        | (event_ex_name == "ASSIST_NPC" and 0 or rt.enum.event_collision_flag.AREA)
        | rt.enum.event_collision_flag.TIME
    return rt.enum.spawn_result.OK, sched.spawn_event.ctor(event_data, self.event_data.name_local, area, collision_flag)
end

return this
