local data = require("FieldEventSpawner.data")
local removal = require("FieldEventSpawner.schedule.removal")
local table_util = require("FieldEventSpawner.table_util")

local ace = data.ace
local rt = data.runtime

local this = {
    util = require("FieldEventSpawner.schedule.util"),
    spawn_event = require("FieldEventSpawner.schedule.spawn_event"),
    hook = require("FieldEventSpawner.schedule.hook"),
    cache = require("FieldEventSpawner.schedule.cache"),
}

---@param stage app.FieldDef.STAGE
---@param event SpawnEvent
function this.add(stage, event)
    this.hook.state.force_spawn_flag = true

    local field_director, schedule_timeline = rt.get_field_director()
    local now = schedule_timeline:get_AdvancedGameMinute()
    local schedule = rt.get_envman():exportExFieldSchedule_Field(stage)

    local function fill_missing_fields(event_data)
        if event_data._UniqueIndex == -1 then
            event_data._UniqueIndex = schedule_timeline:newEventUniqueIndex(stage)
        end
        if event_data._ExecMinute == 0 then
            event_data._ExecMinute = now
        end
    end

    fill_missing_fields(event.event_data)
    ---@type CachedEvent
    local cached_event = table_util.table_deep_copy(event.cache_base)
    cached_event.exec_time = event.event_data._ExecMinute
    cached_event.unique_index = event.event_data._UniqueIndex
    this.cache.add(stage, cached_event)

    if cached_event.collision_flag ~= rt.enum.event_collision_flag.NONE then
        removal.remove_colliding_events(event, schedule._EventList, schedule_timeline)
    end

    if ace.enum.ex_event[cached_event.event_type] == "GIMMICK_EVENT" then
        this.hook.state.repop_gm = cached_event
    elseif ace.enum.ex_event[cached_event.event_type] == "POP_EM" then
        ---@cast event MonsterSpawnEvent
        event.args.unique_index = event.event_data._UniqueIndex
        this.hook.state.em_args = event.args
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
    local stage = rt.update_stage()

    if not rt.is_ok() or not data.init() or not ace.event.by_stage[stage] then
        rt.state.schedule = rt.enum.schedule_state["NO_STAGE"]
        return
    end

    local _, schedule_timeline = rt.get_field_director()
    local is_background, changed = rt.update_background()
    this.cache.is_background = is_background
    rt.update_environ()
    rt.update_spoffer()

    if changed then
        this.cache.clear_background()
    end

    for unique_index, cached_event in pairs(this.cache.get_stage_table(stage)) do
        local event = schedule_timeline:findKeyFromUniqueIndex(unique_index)
        if not event then
            removal.remove_my_event(stage, cached_event)
        else
            if
                not event:get_IsWorking()
                or not event:get_IsActive()
                or not removal.is_my_event(cached_event, event)
            then
                removal.remove_my_event(stage, cached_event)
            end
        end
    end
    rt.state.schedule = rt.enum.schedule_state["OK"]
end

---@param stage app.FieldDef.STAGE
---@param unique_index integer
function this.remove(stage, unique_index)
    removal.remove_my_event(stage, unique_index)
end

function this.clear()
    this.hook.state.clear_flag = true
end

function this.rebuild()
    this.hook.state.rebuild_flag = true
end

function this.init()
    this.cache.load()
end

return this
