---@class (exact) MonsterSpawnEventArgs
---@field id app.EnemyDef.ID
---@field force_area boolean
---@field village_boost boolean?
---@field unique_index integer?
---@field spoffer integer?
---@field spoffer_rewards EditedRewardData?

---@class (exact) ScheduledEvent
---@field event_data app.cExFieldScheduleExportData.cEventData

---@class (exact) SpawnEvent : ScheduledEvent
---@field cache_base CachedEventParent
---@field sub_events ScheduledEvent[]?

---@class (exact)MonsterSpawnEvent : SpawnEvent
---@field args MonsterSpawnEventArgs

local data = require("FieldEventSpawner.data")

local ace = data.ace
local rt = data.runtime

local this = {}

---@param event_data app.cExFieldScheduleExportData.cEventData
---@param name string
---@param area integer
---@param collision_flag EventCollisionFlag?
---@param children CachedEventChild[]?
---@param sub_events ScheduledEvent[]?
---@return SpawnEvent
function this.ctor(event_data, name, area, collision_flag, children, sub_events)
    ---@type SpawnEvent
    return {
        event_data = event_data,
        cache_base = {
            type = rt.enum.cached_event_type.PARENT,
            name = name,
            area = area,
            event_type = event_data._EventType,
            id = event_data:get_field(ace.map.ex_event_to_id_field[ace.enum.ex_event[event_data._EventType]]),
            collision_flag = collision_flag and collision_flag or 0,
            children = children,
        },
        sub_events = sub_events,
    }
end

---@param event_data app.cExFieldScheduleExportData.cEventData
---@param name string
---@param area integer
---@param id app.EnemyDef.ID
---@param force_area boolean
---@param village_boost boolean?
---@param spoffer integer?
---@param collision_flag EventCollisionFlag?
---@param children CachedEventChild[]?
---@param sub_events ScheduledEvent[]?
---@param spoffer_rewards EditedRewardData?
---@return MonsterSpawnEvent
function this.monster_ctor(
    event_data,
    name,
    area,
    id,
    force_area,
    village_boost,
    spoffer,
    collision_flag,
    children,
    sub_events,
    spoffer_rewards
)
    local ret = this.ctor(event_data, name, area, collision_flag, children, sub_events)
    ---@cast ret MonsterSpawnEvent
    ret.args = {
        id = id,
        force_area = force_area,
        spoffer = spoffer,
        village_boost = village_boost,
        spoffer_rewards = spoffer_rewards,
    }
    return ret
end

---@param event_data app.cExFieldScheduleExportData.cEventData | app.cExFieldScheduleExportData.cEventData[]
---@return ScheduledEvent[]
function this.subevent_ctor(event_data)
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
---@param event_data app.cExFieldScheduleExportData.cEventData?
---@param area integer?
---@param collision_flag EventCollisionFlag?
---@return CachedEventChild
function this.child_ctor(unique_index, event_data, area, collision_flag)
    ---@type CachedEventChild
    local ret = {
        type = rt.enum.cached_event_type.CHILD,
        unique_index = unique_index,
    }
    if event_data then
        ret.base = {
            id = event_data:get_field(ace.map.ex_event_to_id_field[ace.enum.ex_event[event_data._EventType]]),
            event_type = event_data._EventType,
            area = area and area or 0,
            collision_flag = collision_flag and collision_flag or 0,
        }
    end
    return ret
end

return this
