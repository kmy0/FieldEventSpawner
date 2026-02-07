---@class (exact) SwitchData
---@field event_type string
---@field event string
---@field stage app.FieldDef.STAGE
---@field em_param string
---@field em_param_mod string
---@field ignore_environ boolean
---@field em_difficulty table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>
---@field environ app.EnvironmentType.ENVIRONMENT

---@class (exact) CurrentData : SwitchData
---@field reward_filter string
---@field em_param_struct MonsterParam
---@field lang string

---@class RuntimeGuiData
---@field ref GuiItems?
---@field event_table table<string, AreaEventData>
---@field reward FilterGuiItemData
---@field event GuiItemData
---@field area GuiItemData
---@field event_type GuiItemData
---@field em_param GuiItemData
---@field em_param_mod GuiItemData
---@field em_difficulty GuiItemData
---@field em_difficulty_rank GuiItemData
---@field spoffer GuiItemData
---@field current CurrentData

---@class (exact) SortStruct
---@field key any
---@field text string

local config = require("FieldEventSpawner.config.init")
local data_ace = require("FieldEventSpawner.data.ace.init")
local data_gui = require("FieldEventSpawner.data.gui")
local data_rt = require("FieldEventSpawner.data.runtime")
local filter_item_data = require("FieldEventSpawner.util.imgui.item_def.filter_item_data")
local item_data = require("FieldEventSpawner.util.imgui.item_def.item_data")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class RuntimeGuiData
local this = {
    event_table = {},
    reward = filter_item_data:new(),
    event = item_data:new(),
    area = item_data:new(),
    event_type = item_data:new(),
    em_param = item_data:new(),
    em_param_mod = item_data:new(),
    em_difficulty = item_data:new(),
    em_difficulty_rank = item_data:new(),
    spoffer = item_data:new(),
    ---@diagnostic disable-next-line: missing-fields
    current = {
        ---@diagnostic disable-next-line: missing-fields
        em_param_struct = {},
    },
}

---@return boolean
local function is_monster_event()
    return this.event_type.map[config.current.mod.event_type] == "monster"
end

---@return AreaEventData
local function get_current_event()
    return this.event_table[this.event.map[config.current.mod.event]]
end

---@param new_values SwitchData
---@param fields string[]
local function is_state_changed(new_values, fields)
    return util_table.any(fields, function(_, value)
        return this.current[value] ~= new_values[value]
    end)
end

---@param a SortStruct
---@param b SortStruct
---@return boolean
local function default_sort_fn(a, b)
    return a.text < b.text
end

---@param a SortStruct
---@param b SortStruct
---@return boolean
local function numeric_sort_fn(a, b)
    local a_num = tonumber(util_misc.split_string(a.text, "##")[1])
    local b_num = tonumber(util_misc.split_string(b.text, "##")[1])
    return a_num < b_num
end

---@param config_key string
---@param array string[]
---@param value string?
local function restore_index(config_key, array, value)
    if value == nil then
        return
    end

    local index = util_table.index(array, value)
    if index then
        config:set(config_key, index)
    else
        config:set(config_key, 1)
    end
end

---@generic K, V
---@param key string
---@param map table<K, V>
---@param sort_struct_fn fun(key: string, map_key: K, map_value: V): SortStruct
---@param sort_fn (fun(a: SortStruct, b: SortStruct): boolean)?
---@param predicate (fun(map_key: K, map_value: V): boolean)?
local function update_combo_values(key, map, sort_struct_fn, sort_fn, predicate)
    local gui_item = this[key]
    ---@cast gui_item GuiItemData
    gui_item:clear()

    local sorted = {}
    for k, v in pairs(map) do
        if predicate and predicate(k, v) or not predicate then
            table.insert(sorted, sort_struct_fn(key, k, v))
        end
    end

    table.sort(sorted, sort_fn and sort_fn or default_sort_fn)
    for i = 1, #sorted do
        local sort_struct = sorted[i]
        table.insert(gui_item.array, sort_struct.text)
        table.insert(gui_item.map, sort_struct.key)
    end
end

---@param key string
---@param map_key any
---@param map_value string
local function sort_struct_fn(key, map_key, map_value)
    local t = type(map_key)
    return {
        key = map_key,
        text = util_imgui.id(map_value, key, (t == "string" or t == "number") and map_key or nil),
    }
end

---@param key string
---@param map_key any
---@param map_value string
---@diagnostic disable-next-line: unused-local
local function sort_struct_translated_fn(key, map_key, map_value)
    return {
        key = map_value,
        text = util_imgui.id(
            config.lang:tr(string.format("mod.combo_%s_values.%s", key, map_value)),
            key,
            map_value
        ),
    }
end

local function translate_em_param_combo()
    if not this.current.em_param_struct then
        return
    end

    local key = "em_param"
    update_combo_values(
        key,
        data_gui.combo[key],
        sort_struct_translated_fn,
        nil,
        function(_, map_value)
            return this.current.em_param_struct[map_value]
        end
    )
end

local function translate_em_param_mod_combo()
    if not this.current.em_param_struct then
        return
    end

    local key = "em_param_mod"
    update_combo_values(
        key,
        data_gui.combo[key],
        sort_struct_translated_fn,
        nil,
        function(_, map_value)
            local t = this.current.em_param_struct[this.em_param.map[config.current.mod.em_param]]
            if t then
                return t[map_value]
            end
            return false
        end
    )
end

local function translate_event_type_combo()
    local key = "event_type"
    update_combo_values(key, data_gui.combo[key], sort_struct_translated_fn)
end

---@param params SwitchData
local function switch_event_type(params)
    if not is_state_changed(params, { "stage", "event_type" }) then
        return
    end

    this.event_table = data_ace.event.by_stage[params.stage][params.event_type] or {}
    if util_table.empty(this.event_table) then
        return
    end

    local current_value = this.event.map[config.current.mod.event] or nil
    update_combo_values(
        "event",
        util_table.map_table(this.event_table, nil, function(o)
            return o.name_local
        end),
        sort_struct_fn
    )
    restore_index("mod.event", this.event.map, current_value)
end

---@param params SwitchData
local function switch_area_array(params)
    local fields = {
        "event",
        "stage",
        "environ",
        "ignore_environ",
    }

    if is_monster_event() then
        table.insert(fields, "em_param")
    end

    if not is_state_changed(params, fields) then
        return
    end

    local current_value = this.area.map and this.area.map[config.current.mod.area] or nil
    local event = get_current_event()

    if not event then
        return
    end
    ---@cast event AreaEventData | MonsterData

    local areas = event:get_area_array(
        params.stage,
        not params.ignore_environ and params.environ or nil,
        params.em_param
    ) or {}
    update_combo_values(
        "area",
        util_table.map_array(areas, function(o)
            return o
        end, function(o)
            return tostring(o)
        end),
        sort_struct_fn,
        numeric_sort_fn
    )
    restore_index("mod.area", this.area.map, current_value)
end

---@param params SwitchData
local function switch_em_param_array(params)
    if
        not is_monster_event()
        or not is_state_changed(params, { "event", "stage", "environ", "ignore_environ" })
    then
        return
    end

    local current_value = this.em_param.array and this.em_param.array[config.current.mod.em_param]
        or nil
    local event = get_current_event()
    ---@cast event MonsterData

    if not event then
        return
    end

    this.current.em_param_struct = event:get_param_struct(
        params.stage,
        not params.ignore_environ and params.environ or nil
    ) or {}
    translate_em_param_combo()

    local config_key = "mod.em_param"
    restore_index(config_key, this.em_param.array, current_value)
    params.em_param = this.em_param.map[config:get(config_key)]
end

---@param params SwitchData
local function switch_em_param_mod_array(params)
    if
        not is_monster_event()
        or not is_state_changed(
            params,
            { "event", "stage", "environ", "ignore_environ", "em_param" }
        )
    then
        return
    end

    local current_value = this.em_param_mod.array
            and this.em_param_mod.array[config.current.mod.em_param_mod]
        or nil
    translate_em_param_mod_combo()

    local config_key = "mod.em_param_mod"
    restore_index(config_key, this.em_param_mod.array, current_value)
    params.em_param_mod = this.em_param_mod.map[config:get(config_key)]
end

---@param params SwitchData
local function switch_em_difficulty_array(params)
    if
        not is_monster_event()
        or not params.em_param_mod
        or not is_state_changed(
            params,
            { "event", "stage", "environ", "ignore_environ", "em_param", "em_param_mod" }
        )
    then
        return
    end

    local current_value = this.em_difficulty.array
            and this.em_difficulty.array[config.current.mod.em_difficulty]
        or nil
    local event = get_current_event()

    if not event then
        return
    end
    ---@cast event MonsterData

    local diff_table = event:get_difficulty_table(
        params.stage,
        not params.ignore_environ and params.environ or nil,
        params.em_param,
        params.em_param_mod
    ) or {}
    update_combo_values(
        "em_difficulty",
        util_table.map_array(util_table.keys(diff_table), function(o)
            return diff_table[o]
        end, function(o)
            return tostring(o)
        end),
        sort_struct_fn,
        numeric_sort_fn
    )

    local config_key = "mod.em_difficulty"
    restore_index(config_key, this.em_difficulty.array, current_value)
end

---@param params SwitchData
local function switch_em_difficulty_rank_array(params)
    if
        not is_monster_event()
        or not params.em_param_mod
        or not is_state_changed(params, {
            "event",
            "stage",
            "environ",
            "ignore_environ",
            "em_param",
            "em_param_mod",
            "em_difficulty",
        })
    then
        return
    end

    local current_value = this.em_difficulty_rank.array
            and this.em_difficulty_rank.array[config.current.mod.em_difficulty_rank]
        or nil
    local event = get_current_event()

    if not event then
        return
    end
    ---@cast event MonsterData

    -- params.em_difficulty is nil when force_difficulty is not enabled,
    -- which means that, array would be always empty when disabled, and it looks ass
    local diff_rank_table = this.em_difficulty.map[config.current.mod.em_difficulty] or {} --[[@as table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>]]
    update_combo_values(
        "em_difficulty_rank",
        util_table.map_array(util_table.keys(diff_rank_table), function(o)
            return diff_rank_table[o]
        end, function(o)
            return tostring(o)
        end),
        sort_struct_fn,
        numeric_sort_fn
    )
    restore_index("mod.em_difficulty_rank", this.em_difficulty_rank.array, current_value)
end

local function switch_spoffer_array()
    if this.current.event_type ~= "monster" then
        return
    end

    local current_value = this.spoffer.array and this.spoffer.array[config.current.mod.spoffer]
        or nil
    update_combo_values(
        "spoffer",
        util_table.map_array(util_table.values(data_rt.state.spoffer), function(o)
            return o.unique_index
        end, function(o)
            return o.name
        end),
        sort_struct_fn,
        function(a, b)
            return data_rt.state.spoffer[a.key].exec_min < data_rt.state.spoffer[b.key].exec_min
        end
    )
    restore_index("mod.spoffer", this.spoffer.array, current_value)
end

---@param params SwitchData
local function switch_em_size_range(params)
    if
        not this.ref
        or not is_monster_event()
        or not params.em_param_mod
        or not is_state_changed(
            params,
            { "event", "em_param", "em_param_mod", "em_difficulty", "em_difficulty_rank" }
        )
    then
        return
    end

    local current_value = config.current.mod.em_size
    local event = get_current_event()

    if not event then
        return
    end
    ---@cast event MonsterData

    local em_param_mod = this.em_param_mod.map
            and this.em_param_mod.map[config.current.mod.em_param_mod]
        or nil
    if not em_param_mod then
        return
    end

    local em_difficulty_rank = this.em_difficulty_rank.array
            and this.em_difficulty_rank.array[config.current.mod.em_difficulty_rank]
        or nil
    if not em_difficulty_rank then
        return
    end

    local size = event.map[params.stage].size_by_param_mod[em_param_mod] --[[@as table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>]]
    local size_data = size[tonumber(util_misc.split_string(em_difficulty_rank, "##")[1])] --[[@as MonsterSizeData]]
    local min = size_data.min
    local max = size_data.max

    if config.em_size_min ~= -1 then
        min = config.em_size_min
    end

    if config.em_size_max ~= -1 then
        max = config.em_size_max
    end

    this.ref.em_size:update_draw_args({ min, max })
    if current_value < min or current_value > max then
        local min_abs = math.abs(current_value - min)
        local max_abs = math.abs(current_value - max)

        if min_abs < max_abs then
            current_value = min
        elseif max_abs < min_abs then
            current_value = max
        else
            current_value = math.floor(math.abs(min - max) / 2)
        end

        config.current.mod.em_size = current_value ~= 0 and current_value or min
    end
end

---@param query string
function this.switch_reward_array(query)
    if this.current.reward_filter == query then
        return
    end

    this.current.reward_filter = query

    local current_value = this.reward.filtered_array[config.current.mod.reward_config.reward]
    if this.reward:empty() then
        update_combo_values("reward", data_ace.item.by_key, function(_, map_key, map_value)
            return { key = map_key, text = map_value.name_local }
        end)
    end

    this.reward:filter(function(map_value)
        if query == "" then
            return true
        end

        local number = tonumber(query)
        if number then
            return data_ace.item.by_key[map_value].id_not_fixed == number
        end

        local query_lower = query:lower()
        local name_lower = data_ace.item.by_key[map_value].name_local:lower()
        return name_lower:find(query_lower) ~= nil
    end)
    restore_index("mod.reward_config.reward", this.reward.filtered_array, current_value)
end

---@param language string
function this.switch_lang(language)
    if language == this.current.lang then
        return
    end

    this.current.event_type = nil
    this.current.lang = language

    translate_event_type_combo()
    translate_em_param_combo()
    translate_em_param_mod_combo()
end

---@param item_ref GuiItems
---@param event_type string
---@param event string
---@param em_param string
---@param em_param_mod string
---@param em_difficulty table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>
---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT
---@param ignore_environ boolean
function this.switch_event_arrays(
    item_ref,
    event_type,
    event,
    em_param,
    em_param_mod,
    em_difficulty,
    stage,
    environ,
    ignore_environ
)
    this.ref = item_ref

    ---@type SwitchData
    local params = {
        stage = stage,
        event_type = event_type,
        event = event,
        environ = environ,
        ignore_environ = ignore_environ,
        em_param = em_param,
        em_param_mod = em_param_mod,
        em_difficulty = em_difficulty,
    }

    switch_event_type(params)

    if util_table.empty(this.event_table) then
        for _, key in pairs({
            "event",
            "area",
            "em_param",
            "em_param_mod",
            "em_difficulty",
            "em_difficulty_rank",
            "spoffer",
        }) do
            this[key]:clear()
        end
    else
        switch_em_param_array(params)
        switch_em_param_mod_array(params)
        switch_em_difficulty_array(params)
        switch_em_difficulty_rank_array(params)
        switch_area_array(params)
        switch_spoffer_array()
        switch_em_size_range(params)
    end

    this.current = util_table.merge_t(this.current, params)
end

---@param key string
---@return AreaEventData
function this.get_event(key)
    return this.event_table[key]
end

return this
