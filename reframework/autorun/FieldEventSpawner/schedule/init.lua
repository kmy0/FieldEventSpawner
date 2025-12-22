local data_ace = require("FieldEventSpawner.data.ace.init")
local data_rt = require("FieldEventSpawner.data.runtime")
local event_removal = require("FieldEventSpawner.schedule.event_removal")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {
    util = require("FieldEventSpawner.schedule.util"),
    spawn_event = require("FieldEventSpawner.schedule.spawn_event"),
    hook = require("FieldEventSpawner.schedule.hook"),
    event_cache = require("FieldEventSpawner.schedule.event_cache"),
}

---@param stage app.FieldDef.STAGE
---@param event SpawnEvent
function this.add(stage, event)
    this.hook.set_spawn_flag(true)

    local field_director, schedule_timeline = data_rt.get_field_director()
    local now = schedule_timeline:get_AdvancedGameMinute()
    local schedule = s.get("app.EnvironmentManager"):exportExFieldSchedule_Field(stage)

    local function fill_missing_fields(event_data)
        if event_data._UniqueIndex == -1 then
            event_data._UniqueIndex = schedule_timeline:newEventUniqueIndex(stage)
        end
        if event_data._ExecMinute == 0 then
            event_data._ExecMinute = now
        end
    end

    fill_missing_fields(event.event_data)
    local cached_event = util_table.deep_copy(event.cache_base)
    ---@cast cached_event CachedEvent
    cached_event.exec_time = event.event_data._ExecMinute
    cached_event.unique_index = event.event_data._UniqueIndex
    this.event_cache.add(stage, cached_event)

    if cached_event.collision_flag ~= data_rt.enum.event_collision_flag.NONE then
        event_removal.remove_colliding_events(event, schedule._EventList, schedule_timeline)
    end

    if data_ace.enum.ex_event[cached_event.event_type] == "GIMMICK_EVENT" then
        this.hook.repop_gimmick(cached_event)
    elseif data_ace.enum.ex_event[cached_event.event_type] == "POP_EM" then
        ---@cast event MonsterSpawnEvent
        event.args.unique_index = event.event_data._UniqueIndex
        this.hook.set_em_args(event.args)
    end

    schedule._EventList:AddWithResize(event.event_data)
    if event.sub_events then
        for i = 1, #event.sub_events do
            local e = event.sub_events[i]
            fill_missing_fields(e.event_data)
            schedule._EventList:AddWithResize(e.event_data)
        end
    end

    schedule_timeline:importSchedule(schedule, false)
    field_director:requestSortKeyList(stage, true)
end

function this.update()
    local stage = data_rt.update_stage()

    if not data_rt.is_ok() or not data_ace.event.by_stage[stage] then
        data_rt.state.schedule = data_rt.enum.schedule_state["NO_STAGE"]
        return
    end

    local _, schedule_timeline = data_rt.get_field_director()
    local is_background, changed = data_rt.update_background()
    this.event_cache.is_background = is_background
    data_rt.update_environ()
    data_rt.update_spoffer()

    if changed then
        this.event_cache.clear_background()
    end

    for unique_index, cached_event in pairs(this.event_cache.get_stage_table(stage)) do
        local event = schedule_timeline:findKeyFromUniqueIndex(unique_index)

        if not event then
            event_removal.remove_my_event(stage, cached_event)
        else
            if
                not event:get_IsWorking()
                or not event:get_IsActive()
                or not event_removal.is_my_event(cached_event, event:exportData())
            then
                event_removal.remove_my_event(stage, cached_event)
            end
        end
    end
    data_rt.state.schedule = data_rt.enum.schedule_state["OK"]
end

---@param stage app.FieldDef.STAGE
---@param unique_index integer
function this.remove(stage, unique_index)
    event_removal.remove_my_event(stage, unique_index)
end

function this.clear()
    this.hook.set_clear_flag(true)
end

function this.rebuild()
    this.hook.set_rebuild_flag(true)
end

---@return boolean
function this.init()
    this.event_cache.load()
    return true
end

return this
