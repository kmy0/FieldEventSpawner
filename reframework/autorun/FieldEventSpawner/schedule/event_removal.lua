local data_ace = require("FieldEventSpawner.data.ace.init")
local data_rt = require("FieldEventSpawner.data.runtime")
local event_cache = require("FieldEventSpawner.schedule.event_cache")
local util_game = require("FieldEventSpawner.util.game.init")

local this = {}

---@param event app.cExFieldEvent_PopEnemy
local function remove_pop_em(event)
    event:set_StayMinute_Real(0)
end

---@param event app.cExFieldEvent_Battlefield
local function remove_battlefield(event)
    local em_index = event:get_TargetEnemyExUniqueIndex()
    local _, schedule_timeline = data_rt.get_field_director()
    local em_event = schedule_timeline:findKeyFromUniqueIndex(em_index)
    event:endProc()
    if em_event then
        ---@cast em_event app.cExFieldEvent_PopEnemy
        remove_pop_em(em_event)
        em_event:endProc()
    end
end

---@param event app.cExFieldEvent_AnimalEvent
local function remove_animal(event)
    event:set_DurationMinute_Real(0)
    event:endProc()
end

---@param event app.cExFieldEvent_GimmickEvent
local function remove_gimmick(event)
    event:set_DurationMinute_Real(0)
    if event:get_IsAssistNpc() then
        event:endProc()
    end
end

---@param event app.cExFieldEvent_Battlefield
local function remove_my_battlefield(event)
    remove_battlefield(event)
end

---@param event app.cExFieldEvent_AnimalEvent
local function remove_my_animal(event)
    event:set_DurationMinute_Real(0)
end

---@param event app.cExFieldEvent_GimmickEvent
local function remove_my_gimmick(event)
    remove_gimmick(event)
end

---@param event app.cExFieldEvent_PopEnemy
local function remove_my_pop_em(event)
    remove_pop_em(event)
end

---@param cache_base CachedEventBase
---@param event app.cExFieldScheduleExportData.cEventData
function this.is_my_event(cache_base, event)
    --FIXME: its not fail proof, but should be enough :)), it would be nice if exec time did not change when game overrides schedule
    local base_event_type = data_ace.enum.ex_event[cache_base.event_type]
    local event_type = data_ace.enum.ex_event[event:get_EventType()]
    local id_field_name = data_ace.map.ex_event_to_id_field[base_event_type]
    return base_event_type == event_type and cache_base.id == event:get_field(id_field_name)
end

---@param spawn_event SpawnEvent
---@param exported_schedule System.Array<app.cExFieldScheduleExportData.cEventData>
---@param schedule_timeline app.cExFieldDirector.cScheduleTimeline
function this.remove_colliding_events(spawn_event, exported_schedule, schedule_timeline)
    ---@type app.cExFieldScheduleExportData.cEventData[]
    local res = {}
    local ok_time = spawn_event.event_data._ExecMinute
        + (
            spawn_event.event_data:get_field(
                data_ace.map.ex_event_to_time_field[data_ace.enum.ex_event[spawn_event.cache_base.event_type]][1]
            ) * 60
        )

    ---@param cache_base CachedEventBase
    local function iter(cache_base)
        local event_type = data_ace.enum.ex_event[cache_base.event_type]
        local time_field_name = data_ace.map.ex_event_to_time_field[event_type][1]
        local area_field_name = data_ace.map.ex_event_to_area_field[event_type]
        local id_field_name = data_ace.map.ex_event_to_id_field[event_type]
        local flags = cache_base.collision_flag
        local enum = util_game.get_array_enum(exported_schedule)

        while enum:MoveNext() do
            local e = enum:get_Current()
            if e._EventType ~= cache_base.event_type then
                goto continue
            end

            if
                flags & data_rt.enum.event_collision_flag.EVENT_TYPE
                == data_rt.enum.event_collision_flag.EVENT_TYPE
            then
                goto remove
            end

            if
                flags & data_rt.enum.event_collision_flag.ID
                    == data_rt.enum.event_collision_flag.ID
                and e:get_field(id_field_name) ~= cache_base.id
            then
                goto continue
            end

            if
                flags & data_rt.enum.event_collision_flag.AREA
                    == data_rt.enum.event_collision_flag.AREA
                and e:get_field(area_field_name) ~= cache_base.area
            then
                goto continue
            end

            if
                flags & data_rt.enum.event_collision_flag.TIME
                    == data_rt.enum.event_collision_flag.TIME
                and e:get_field(time_field_name) > ok_time
            then
                goto continue
            end
            ::remove::
            table.insert(res, e)
            ::continue::
        end
    end

    iter(spawn_event.cache_base)
    if spawn_event.cache_base.children then
        local t = spawn_event.cache_base.children
        ---@cast t CachedEventChild[]
        for _, e in pairs(t) do
            if not e.base then
                goto continue
            end
            iter(e.base)
            ::continue::
        end
    end

    for _, e in pairs(res) do
        local event_type = data_ace.enum.ex_event[e._EventType]
        local event = schedule_timeline:findKeyFromUniqueIndex(e._UniqueIndex)

        if event then
            if event_type == "ANIMAL_EVENT" then
                ---@cast event app.cExFieldEvent_AnimalEvent
                remove_animal(event)
            elseif event_type == "GIMMICK_EVENT" then
                ---@cast event app.cExFieldEvent_GimmickEvent
                remove_gimmick(event)
            elseif event_type == "POP_EM" then
                ---@cast event app.cExFieldEvent_PopEnemy
                remove_pop_em(event)
            elseif event_type == "BATTLEFIELD" then
                ---@cast event app.cExFieldEvent_Battlefield
                remove_battlefield(event)
            end

            exported_schedule:Remove(e)
        end
    end
end

---@param stage app.FieldDef.STAGE
---@param item integer | CachedEvent | CachedEventChild | app.cExFieldEventBase
function this.remove_my_event(stage, item)
    ---@type integer
    local unique_index
    ---@type CachedEventBase?
    local cache_base
    ---@type app.cExFieldEventBase
    local event
    if type(item) == "number" then
        unique_index = item
    elseif type(item) == "table" then
        ---@cast item CachedEvent | CachedEventChild
        unique_index = item.unique_index
        if item.type == data_rt.enum.cached_event_type.PARENT then
            ---@cast item CachedEvent
            cache_base = item
        else
            cache_base = item.base
        end
    else
        ---@cast item app.cExFieldEventBase
        event = item
        unique_index = event._UniqueIndex
    end

    if not cache_base then
        cache_base = event_cache.get_event(stage, unique_index)
    end

    if
        cache_base
        and cache_base.type == data_rt.enum.cached_event_type.PARENT
        and cache_base.children
    then
        for _, child in pairs(cache_base.children) do
            this.remove_my_event(stage, child)
        end
    end

    if not event then
        local _, schedule_timeline = data_rt.get_field_director()
        event = schedule_timeline:findKeyFromUniqueIndex(unique_index)
    end

    if event and cache_base and this.is_my_event(cache_base, event:exportData()) then
        local event_type = data_ace.enum.ex_event[cache_base.event_type]
        if event_type == "ANIMAL_EVENT" then
            ---@cast event app.cExFieldEvent_AnimalEvent
            remove_my_animal(event)
        elseif event_type == "GIMMICK_EVENT" then
            ---@cast event app.cExFieldEvent_GimmickEvent
            remove_my_gimmick(event)
        elseif event_type == "POP_EM" then
            ---@cast event app.cExFieldEvent_PopEnemy
            remove_my_pop_em(event)
        elseif event_type == "BATTLEFIELD" then
            ---@cast event app.cExFieldEvent_Battlefield
            remove_my_battlefield(event)
        end
    end

    event_cache.remove(stage, unique_index)
end

return this
