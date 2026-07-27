---@class GuiValues
---@field old_data GuiValuesData
---@field initialized boolean

---@class (exact) GuiValuesData
---@field event_type string
---@field event string
---@field stage app.FieldDef.STAGE
---@field em_param string
---@field em_param_mod string
---@field ignore_environ boolean
---@field em_difficulty integer
---@field em_difficulty_rank app.QuestDef.EM_REWARD_RANK
---@field environ app.EnvironmentType.ENVIRONMENT
---@field area integer

---@class (exact) ChangedData
---@field event boolean
---@field event_type boolean
---@field stage boolean
---@field em_param boolean
---@field em_param_mod boolean
---@field ignore_environ boolean
---@field em_difficulty boolean
---@field em_difficulty_rank boolean
---@field environ boolean
---@field area boolean

local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
local helpers = require("FieldEventSpawner.gui.helpers")
local m = require("FieldEventSpawner.util.ref.methods")
local mod = require("FieldEventSpawner.data.mod")
local state = require("FieldEventSpawner.gui.state")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class GuiValues
local this = {
    old_data = {
        event_type = "",
        event = "",
        stage = -1,
        em_param = "",
        em_param_mod = "",
        ignore_environ = false,
        em_difficulty = -1,
        em_difficulty_rank = -1,
        environ = -1,
        area = -1,
    },
    initialized = false,
}

---@param dirty boolean
---@param combo Combo
---@param key_to_value table
---@param field string
---@param current_data GuiValuesData
---@param changed ChangedData
---@param config_mod ModSettings
---@return boolean dirty
local function sync_combo(dirty, combo, key_to_value, field, current_data, changed, config_mod)
    if dirty then
        if this.initialized then
            config_mod[field] = combo:swap(key_to_value, config_mod[field])
        else
            config_mod[field] = combo:swap_init(key_to_value, config_mod[field])
        end
        current_data[field] = combo:get()
        changed[field] = true
    end
    return dirty or changed[field]
end

---@param dirty boolean
---@param combo Combo
---@param key_to_value table
---@param field string
---@param current_data GuiValuesData
---@param changed ChangedData
---@param config_mod ModSettings
---@param disabled_keys any[]?
---@return boolean dirty
local function sync_combo_with_disabled(
    dirty,
    combo,
    key_to_value,
    field,
    current_data,
    changed,
    config_mod,
    disabled_keys
)
    if dirty then
        config_mod[field] = helpers.swap_with_disabled(
            combo,
            key_to_value,
            config_mod[field],
            disabled_keys,
            not this.initialized
        )
        current_data[field] = combo:get()
        changed[field] = true
    end
    return dirty or changed[field]
end

---@param event AreaEventData | MonsterData?
---@param current_data GuiValuesData
---@param changed ChangedData
---@param environ app.EnvironmentType.ENVIRONMENT?
local function swap_area_array(event, current_data, changed, environ)
    local combo = state.combo
    local config_mod = config.current.mod

    local areas = event and event:get_area_array(current_data.stage, environ, current_data.em_param)
        or {}
    config_mod.area =
        helpers.swap_with_disabled(combo.area, util_table.array_to_map2(areas), config_mod.area) --[[@as integer]]
    current_data.area = combo.area:get()
    changed.area = true
end

---@param event MonsterData?
---@param current_data GuiValuesData
---@param changed ChangedData
---@param dirty boolean
---@param environ app.EnvironmentType.ENVIRONMENT?
local function update_monster_fields(event, current_data, changed, dirty, environ)
    local combo = state.combo
    local config_mod = config.current.mod

    local em_param_struct = event and event:get_param_struct(current_data.stage, environ) or {}

    dirty = sync_combo(
        dirty,
        combo.em_param,
        util_table.array_to_map2(util_table.keys(em_param_struct)),
        "em_param",
        current_data,
        changed,
        config_mod
    )

    if dirty then
        swap_area_array(event, current_data, changed, environ)
    end

    dirty = sync_combo(
        dirty,
        combo.em_param_mod,
        util_table.array_to_map2(
            util_table.keys(
                util_table.filter(em_param_struct[current_data.em_param] or {}, function(_, value)
                    return value
                end)
            )
        ),
        "em_param_mod",
        current_data,
        changed,
        config_mod
    )

    local diff_table = event
            and event:get_difficulty_table(
                current_data.stage,
                environ,
                current_data.em_param,
                current_data.em_param_mod
            )
        or {}

    if current_data.em_param ~= "invalid" then
        dirty = sync_combo_with_disabled(
            dirty,
            combo.em_difficulty,
            util_table.array_to_map2(util_table.keys(diff_table)),
            "em_difficulty",
            current_data,
            changed,
            config_mod
        )
    else
        dirty = sync_combo(
            dirty,
            combo.em_difficulty,
            util_table.array_to_map2(util_table.keys(diff_table)),
            "em_difficulty",
            current_data,
            changed,
            config_mod
        )
    end

    if dirty then
        local values = {}
        for _, guids in pairs(diff_table[current_data.em_difficulty] or {}) do
            values = util_table.array_merge(values, guids)
        end

        local key_to_value = util_table.array_to_map2(values)
        if util_table.empty(key_to_value) then
            config_mod.em_difficulty_rank = helpers.swap_with_disabled(
                combo.em_difficulty_rank,
                key_to_value,
                config_mod.em_difficulty_rank
            ) --[[@as integer]]
        else
            config_mod.em_difficulty_rank =
                combo.em_difficulty_rank:swap(key_to_value, config_mod.em_difficulty_rank) --[[@as integer]]
        end

        local em_difficulty_rank = combo.em_difficulty_rank:get()
        current_data.em_difficulty_rank = em_difficulty_rank
            and m.getRewardRankFromDifficulty(em_difficulty_rank)
        changed.em_difficulty_rank = true
    end

    dirty = dirty or changed.em_difficulty_rank

    if dirty then
        local current_value = config.current.mod.em_size
        local size_by_param_mod = event
                and event.map[current_data.stage].size_by_param_mod[current_data.em_param_mod]
            or {}
        local size = size_by_param_mod[current_data.em_difficulty_rank] or {}

        local min = size.min or ace.map.em_size_min
        local max = size.max or ace.map.em_size_max

        if config.em_size_min ~= -1 then
            min = config.em_size_min
        end
        if config.em_size_max ~= -1 then
            max = config.em_size_max
        end

        state.em_size_min = min
        state.em_size_max = max

        local range = max - min
        if current_value ~= -1 and current_value > range then
            config.current.mod.em_size = range
        end
    end

    config_mod.spoffer = helpers.swap_with_disabled(
        combo.spoffer,
        util_table.map_array(util_table.values(mod.state.spoffer), function(o)
            return o.unique_index
        end, function(o)
            return o.name
        end),
        config_mod.spoffer,
        helpers.get_spoffer_disabled_keys()
    ) --[[@as integer]]
end

function this.update()
    local combo = state.combo
    local config_mod = config.current.mod
    local em_difficulty = combo.em_difficulty_rank:get()
    ---@type GuiValuesData
    local current_data = {
        event_type = combo.event_type:get() or -1,
        event = combo.event:get() or -1,
        stage = mod.state.stage or -1,
        em_param = combo.em_param:get() or -1,
        em_param_mod = combo.em_param_mod:get() or -1,
        ignore_environ = config_mod.is_ignore_environ,
        em_difficulty = combo.em_difficulty:get() or -1,
        em_difficulty_rank = em_difficulty and m.getRewardRankFromDifficulty(em_difficulty) or -1,
        environ = mod.state.environ or -1,
        area = combo.area:get() or -1,
    }
    ---@type ChangedData
    ---@diagnostic disable-next-line: missing-fields
    local changed = {}

    for k, v in pairs(current_data) do
        changed[k] = v ~= this.old_data[k]
    end

    local environ = not current_data.ignore_environ and current_data.environ or nil
    local stage_table = ace.event.by_stage[current_data.stage] or {}
    local event_table = stage_table[current_data.event_type] or {}
    local dirty = changed.stage or changed.environ or changed.event_type or changed.ignore_environ

    dirty = sync_combo(
        dirty,
        combo.event,
        util_table.map_table(event_table, nil, function(o)
            return o.name_local
        end),
        "event",
        current_data,
        changed,
        config_mod
    )

    local event = event_table[current_data.event]
    dirty = dirty or changed.event

    if dirty and current_data.event_type ~= "monster" then
        swap_area_array(event, current_data, changed, environ)
    end

    if current_data.event_type == "monster" then
        ---@cast event MonsterData
        update_monster_fields(event, current_data, changed, dirty, environ)
    end

    this.old_data = current_data
    this.initialized = true
end

return this
