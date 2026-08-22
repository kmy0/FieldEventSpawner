---@class (exact) MonsterSpawnEventArgs
---@field id app.EnemyDef.ID
---@field area integer?
---@field is_spoffer_village_boost boolean?
---@field unique_index integer?
---@field spoffer_unique_index integer?
---@field spoffer_rewards EditedRewardData?
---@field size integer?
---@field spoffer_swarm boolean?
---@field is_battlefield_slay boolean?
---@field option_tag integer?
---@field swarm_indexes integer[]?
---@field swarm_spoofed_id app.EnemyDef.ID?
---@field swarm_spoofed_stage app.FieldDef.STAGE?

---@class (exact) ScheduledEvent
---@field event_data app.cExFieldScheduleExportData.cEventData

---@class (exact) SpawnEvent : ScheduledEvent
---@field cache_base CachedEventParent
---@field sub_events ScheduledEvent[]?

---@class (exact) MonsterSpawnEvent : SpawnEvent
---@field args MonsterSpawnEventArgs

---@class (exact) SpawnEventOptionalArgs
---@field collision_flag EventCollisionFlag?
---@field children CachedEventChild[]?
---@field sub_events ScheduledEvent[]?

---@class (exact) SpawnMonsterEventOptionalArgs : SpawnEventOptionalArgs
---@field area integer?
---@field is_spoffer_village_boost boolean?
---@field spoffer_unique_index integer?
---@field spoffer_rewards EditedRewardData?
---@field size integer?
---@field is_battlefield_slay boolean?
---@field option_tag integer?

---@class (exact) SpawnChildEventOptionalArgs
---@field area integer?
---@field collision_flag EventCollisionFlag?
---@field event_data app.cExFieldScheduleExportData.cEventData?

local ace = require("FieldEventSpawner.data.ace.init")
local e = require("FieldEventSpawner.util.game.enum")
local mod = require("FieldEventSpawner.data.mod")

local this = {}

---@param event_data app.cExFieldScheduleExportData.cEventData
---@param name string
---@param area integer
---@param opts SpawnEventOptionalArgs?
---@return SpawnEvent
function this.make_event(event_data, name, area, opts)
    opts = opts or {}
    ---@type SpawnEvent
    return {
        event_data = event_data,
        cache_base = {
            type = mod.enum.cached_event_type.PARENT,
            name = name,
            area = area,
            event_type = event_data._EventType,
            id = event_data:get_field(
                ace.map.ex_event_to_id_field[e.get("app.EX_FIELD_EVENT_TYPE")[event_data._EventType]]
            ),
            collision_flag = opts.collision_flag and opts.collision_flag or 0,
            children = opts.children,
            timestamp = os.time(),
        },
        sub_events = opts.sub_events,
    }
end

---@param event_data app.cExFieldScheduleExportData.cEventData
---@param name string
---@param area integer
---@param id app.EnemyDef.ID
---@param opts SpawnMonsterEventOptionalArgs?
---@return MonsterSpawnEvent
function this.make_monster(event_data, name, area, id, opts)
    opts = opts or {}
    local ret = this.make_event(event_data, name, area, opts)
    ---@cast ret MonsterSpawnEvent
    ret.args = {
        id = id,
        area = opts.area,
        spoffer_unique_index = opts.spoffer_unique_index,
        is_spoffer_village_boost = opts.is_spoffer_village_boost,
        spoffer_rewards = opts.spoffer_rewards,
        size = opts.size,
        is_battlefield_slay = opts.is_battlefield_slay,
        option_tag = opts.option_tag,
    }
    return ret
end

---@param event_data app.cExFieldScheduleExportData.cEventData | app.cExFieldScheduleExportData.cEventData[]
---@return ScheduledEvent[]
function this.make_subevent(event_data)
    local t
    if type(event_data) == "table" then
        t = event_data
    else
        t = { event_data }
    end

    ---@type ScheduledEvent[]
    local ret = {}
    for i = 1, #t do
        local e = t[i]
        table.insert(ret, {
            event_data = e,
        })
    end
    return ret
end

---@param unique_index integer
---@param opts SpawnChildEventOptionalArgs?
---@return CachedEventChild
function this.make_child(unique_index, opts)
    opts = opts or {}
    ---@type CachedEventChild
    local ret = {
        type = mod.enum.cached_event_type.CHILD,
        unique_index = unique_index,
    }
    if opts.event_data then
        ret.base = {
            id = opts.event_data:get_field(
                ace.map.ex_event_to_id_field[e.get("app.EX_FIELD_EVENT_TYPE")[opts.event_data._EventType]]
            ),
            event_type = opts.event_data._EventType,
            area = opts.area and opts.area or 0,
            collision_flag = opts.collision_flag and opts.collision_flag or 0,
            timestamp = os.time(),
        }
    end
    return ret
end

return this
