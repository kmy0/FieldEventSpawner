---@class (exact) EventCache
---@field current table<app.FieldDef.STAGE, table<integer, CachedEvent>>
---@field saved table<app.FieldDef.STAGE, table<integer, CachedEvent>>
---@field background table<app.FieldDef.STAGE, table<integer, CachedEvent>>

---@class (exact) CachedEventBase
---@field area integer
---@field id integer
---@field event_type app.EX_FIELD_EVENT_TYPE
---@field collision_flag EventCollisionFlag

---@class (exact) CachedEventChild
---@field type CachedEventType
---@field base CachedEventBase?
---@field unique_index integer

---@class (exact) CachedEventParent : CachedEventBase
---@field type CachedEventType
---@field name string
---@field children CachedEventChild[]?

---@class (exact) CachedEvent : CachedEventParent
---@field unique_index integer
---@field exec_time integer

local config = require("FieldEventSpawner.config")
local table_util = require("FieldEventSpawner.table_util")

local this = {
    ---@class EventCache
    event_cache = {
        current = {},
        saved = {},
        background = {},
    },
    is_background = false,
}

---@param stage app.FieldDef.STAGE
---@param cached_event CachedEvent
function this.add(stage, cached_event)
    local t = this.get_stage_table(stage)
    t[cached_event.unique_index] = cached_event
    this.save()
end

---@param stage app.FieldDef.STAGE
---@param unique_index integer
function this.remove(stage, unique_index)
    local t = this.get_stage_table(stage)
    t[unique_index] = nil
    this.save()
end

---@param stage app.FieldDef.STAGE
function this.clear(stage)
    local t = this.get_stage_table(stage)
    t = {}
    this.save()
end

function this.clear_background()
    this.event_cache.background = {}
end

---@param stage app.FieldDef.STAGE
---@return table<integer, CachedEvent>
function this.get_stage_table(stage)
    local t
    if this.is_background then
        t = this.event_cache.background
    else
        t = this.event_cache.current
    end

    if not t[stage] then
        t[stage] = {}
    end
    return t[stage]
end

---@param stage app.FieldDef.STAGE
---@param unique_index integer
---@return CachedEvent?
function this.get_event(stage, unique_index)
    local t = this.get_stage_table(stage)
    return t[unique_index]
end

function this.overwrite_saved()
    this.event_cache.saved = table_util.deep_copy(this.event_cache.current)
    this.save()
end

function this.overwrite_current()
    this.event_cache.current = table_util.deep_copy(this.event_cache.saved)
    this.save()
end

function this.save()
    local t = {}
    for k, v in pairs(this.event_cache) do
        t[k] = {}
        for stage, evts in pairs(v) do
            local stage_tbl = {}
            t[k][tostring(stage)] = stage_tbl
            for unique_index, cached_event in pairs(evts) do
                stage_tbl[tostring(unique_index)] = cached_event
            end
        end
    end
    json.dump_file(config.cache_path, t)
end

function this.load()
    local loaded = json.load_file(config.cache_path)
    if loaded then
        for k, v in pairs(this.event_cache) do
            if not loaded[k] then
                goto continue
            end

            for stage, evts in pairs(loaded[k]) do
                local stage_tbl = {}
                v[tonumber(stage)] = stage_tbl
                for unique_index, cached_event in pairs(evts) do
                    stage_tbl[tonumber(unique_index)] = cached_event
                end
            end
            ::continue::
        end
    end
end

return this
