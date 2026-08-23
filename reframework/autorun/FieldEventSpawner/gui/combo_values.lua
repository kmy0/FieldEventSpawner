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
---@field em_role app.EnemyDef.ROLE_ID
---@field em_option_tag integer
---@field spoffer_swarm boolean
---@field add_invalid_rewards boolean

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
---@field em_role boolean
---@field spoffer_swarm boolean
---@field add_invalid_rewards boolean

local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
local e = require("FieldEventSpawner.util.game.enum")
local gui = require("FieldEventSpawner.data.gui")
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
        em_role = -1,
        em_option_tag = -1,
        spoffer_swarm = false,
        add_invalid_rewards = false,
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
---@param insert_dummy boolean? by default, true
---@return boolean dirty
local function sync_combo_with_disabled(
    dirty,
    combo,
    key_to_value,
    field,
    current_data,
    changed,
    config_mod,
    disabled_keys,
    insert_dummy
)
    if dirty then
        config_mod[field] = helpers.swap_with_disabled(
            combo,
            key_to_value,
            config_mod[field],
            disabled_keys,
            not this.initialized,
            insert_dummy
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
local function swap_em_role_array(event, current_data, changed)
    local combo = state.combo
    local config_mod = config.current.mod
    local role_ids = event and event:get_role_array(current_data.stage, current_data.em_param) or {}
    local t = util_table.map_table(role_ids, function(o)
        return role_ids[o]
    end, function(o)
        return e.get("app.EnemyDef.ROLE_ID")[o]
    end)
    config_mod.em_role = state.combo.em_role:swap(t, config_mod.em_role) --[[@as integer]]
    current_data.em_role = combo.em_role:get()
    changed.em_role = true
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

    if this.initialized and event and event.id ~= config_mod.em_option_em then
        config_mod.em_option_tags = {}
        config_mod.em_option_em = event.id
        config:save()
    end

    dirty = sync_combo_with_disabled(
        dirty,
        combo.em_option_tag,
        event
                and util_table.map_table(event.option_tag, function(o)
                    return tostring(o)
                end)
            or {},
        "em_option_tag",
        current_data,
        changed,
        config_mod,
        event and util_table.keys(config_mod.em_option_tags) or {},
        false
    )
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
        swap_em_role_array(event, current_data, changed)
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

    if dirty or changed.em_role then
        local current_value = state.swarm_count_array[config_mod.swarm_count]

        if
            current_data.em_param == "swarm"
            or current_data.em_param == "boss"
            or current_data.em_role == e.get_noexact("app.EnemyDef.ROLE_ID").INVALID_SWARM
        then
            state.swarm_count_array = {}
            local swarm_pack = event and event.map[current_data.stage].swarm_pack

            if swarm_pack then
                local min = current_data.spoffer_swarm and swarm_pack.min_spoffer or swarm_pack.min
                local max = current_data.spoffer_swarm and swarm_pack.max_spoffer or swarm_pack.max

                for i = min, max do
                    table.insert(state.swarm_count_array, i)
                end
            end

            if
                (current_data.em_param == "boss" and not current_data.spoffer_swarm)
                or not swarm_pack
            then
                table.insert(state.swarm_count_array, 1, -1)
            end
        else
            state.swarm_count_array = { -1 }
        end

        if this.initialized or #state.swarm_count_array == 1 then
            local index = util_table.index(state.swarm_count_array, current_value) or 1
            config_mod.swarm_count = index
        end
    end

    if dirty or changed.add_invalid_rewards then
        local items = util_table.deep_copy(gui.combo.rewards)
        if current_data.add_invalid_rewards then
            table.insert(items, gui.combo.invalid_rewards)
        end

        dirty = sync_combo(
            dirty,
            combo.quest_rewards,
            util_table.map_array(items),
            "rewards",
            current_data,
            changed,
            config_mod
        )
    end

    if dirty then
        dirty = sync_combo(
            dirty,
            combo.em_invalid_reward,
            util_table.map_table(event and event.invalid_rewards or {}, nil, function(o)
                return string.format("%s%s %s", o.rank, config.lang:tr("misc.text_star"), o.title)
            end),
            "em_invalid_reward",
            current_data,
            changed,
            config_mod
        )
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
        em_role = combo.em_role:get() or -1,
        em_option_tag = combo.em_option_tag:get() or -1,
        spoffer_swarm = config_mod.is_spoffer_swarm,
        add_invalid_rewards = config_mod.add_invalid_rewards,
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

    if dirty then
        config:save()
    end
end

return this
