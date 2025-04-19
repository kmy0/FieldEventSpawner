---@class (exact) CurrentData
---@field event_type string
---@field event string
---@field reward_filter string
---@field stage app.FieldDef.STAGE
---@field em_param string
---@field em_param_struct MonsterParam
---@field em_param_mod string
---@field lang string
---@field environ app.EnvironmentType.ENVIRONMENT
---@field ignore_environ boolean

---@class RuntimeGuiData
---@field event_table table<string, AreaEventData>
---@field reward FilterGuiItemData
---@field event GuiItemData
---@field area GuiItemData
---@field event_type GuiItemData
---@field em_param GuiItemData
---@field em_param_mod GuiItemData
---@field battlefield_state GuiItemData
---@field spoffer GuiItemData
---@field current CurrentData

---@class (exact) SortStruct
---@field key any
---@field text string

local config = require("FieldEventSpawner.config")
local data = require("FieldEventSpawner.data")
local filter_item_data = require("FieldEventSpawner.gui.item_def.filter_item_data")
local item_data = require("FieldEventSpawner.gui.item_def.item_data")
local lang = require("FieldEventSpawner.lang")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local ace = data.ace
local rt = data.runtime
local gui = data.gui
local tr = lang.tr

---@class RuntimeGuiData
local this = {
    event_table = {},
    reward = filter_item_data:new(),
    event = item_data:new(),
    area = item_data:new(),
    event_type = item_data:new(),
    em_param = item_data:new(),
    em_param_mod = item_data:new(),
    battlefield_state = item_data:new(),
    spoffer = item_data:new(),
    ---@diagnostic disable-next-line: missing-fields
    current = {
        ---@diagnostic disable-next-line: missing-fields
        em_param_struct = {},
    },
}

---@param key string
---@param predicate (fun(o: string): boolean)?
local function tr_update_combo(key, predicate)
    local gui_item = this[key]
    ---@cast gui_item GuiItemData
    gui_item:clear()

    local arr = gui.combo[key]
    ---@cast arr string[]
    ---@type SortStruct[]
    local sorted = {}
    for _, v in pairs(arr) do
        if predicate and predicate(v) or not predicate then
            table.insert(
                sorted,
                { key = v, text = tr(string.format("%s_combo.values.%s", key, v)) .. string.format("##%s_%s", key, v) }
            )
        end
    end
    table.sort(sorted, function(a, b)
        return a.text < b.text
    end)
    for i = 1, #sorted do
        local value = sorted[i]
        table.insert(gui_item.array, value.text)
        table.insert(gui_item.map, value.key)
    end
end

---@param key string
---@param t table<any, string>
---@param predicate (fun(o: string): boolean)?
---@param sort (fun(a: SortStruct, b: SortStruct): boolean)?
local function no_tr_update_combo(key, t, predicate, sort)
    local gui_item = this[key]
    ---@cast gui_item GuiItemData
    gui_item:clear()

    ---@type SortStruct[]
    local sorted = {}
    for k, v in pairs(t) do
        if predicate and predicate(v) or not predicate then
            table.insert(sorted, { key = k, text = string.format("%s##%s_%s", v, key, k) })
        end
    end
    table.sort(sorted, sort and sort or function(a, b)
        return a.text < b.text
    end)
    for i = 1, #sorted do
        local value = sorted[i]
        table.insert(gui_item.array, value.text)
        table.insert(gui_item.map, value.key)
    end
end

local function tr_em_param_array()
    if not this.current.em_param_struct then
        return
    end
    tr_update_combo("em_param", function(o)
        return this.current.em_param_struct[o]
    end)
end

local function tr_em_param_mod_array()
    if not this.current.em_param_struct then
        return
    end
    tr_update_combo("em_param_mod", function(o)
        local t = this.current.em_param_struct[this.em_param.map[config.current.mod.em_param]]
        if t then
            return t[o]
        end
        return false
    end)
end

---@param event_type string
---@param stage app.FieldDef.STAGE
local function switch_type(event_type, stage)
    if stage == this.current.stage and event_type == this.current.event_type then
        return
    end

    this.event_table = ace.event.by_stage[stage][event_type]

    if not this.event_table then
        this.event_table = {}
        this.event:clear()
        return
    end

    local current_value = this.event.map[config.current.mod.event] or nil
    no_tr_update_combo(
        "event",
        table_util.map_table(this.event_table, nil, function(o)
            return o.name_local
        end)
    )
    local index = table_util.index(this.event.map, current_value)
    if index then
        config.current.mod.event = index
    end
end

---@param event_key string
---@param em_param string
---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT
---@param ignore_environ boolean
local function switch_area_array(event_key, em_param, stage, environ, ignore_environ)
    if
        event_key == this.current.event
        and stage == this.current.stage
        and environ == this.current.environ
        and this.current.ignore_environ == ignore_environ
        and (
            (this.current.event_type == "monster" and em_param == this.current.em_param)
            or this.current.event_type ~= "monster"
        )
    then
        return
    end

    if table_util.empty(this.event_table) then
        this.area:clear()
        return
    end

    local current_value = this.area.map and this.area.map[config.current.mod.area] or nil
    local event = this.event_table[event_key]

    if not event then
        return
    end
    ---@cast event AreaEventData | MonsterData

    local areas = event:get_area_array(stage, not ignore_environ and environ or nil, em_param) or {}
    no_tr_update_combo(
        "area",
        table_util.map_array(areas, function(o)
            return o
        end, function(o)
            return tostring(o)
        end),
        nil,
        function(a, b)
            ---@diagnostic disable-next-line: undefined-field
            return tonumber(util.split_string(a.text, "##")[1]) < tonumber(util.split_string(b.text, "##")[1])
        end
    )

    local index = table_util.index(this.area.map, current_value)
    if index then
        config.current.mod.area = index
    end
end

---@param event_key string
---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT
---@param ignore_environ boolean
local function switch_em_param_array(event_key, stage, environ, ignore_environ)
    if
        this.current.event_type ~= "monster"
        or (
            event_key == this.current.event
            and stage == this.current.stage
            and environ == this.current.environ
            and ignore_environ == this.current.ignore_environ
        )
    then
        return
    end

    local current_value = this.em_param.array and this.em_param.array[config.current.mod.em_param] or nil
    local event = this.event_table[event_key]
    ---@cast event MonsterData

    if not event then
        return
    end

    this.current.em_param_struct = event:get_param_struct(stage, not ignore_environ and environ or nil) or {}
    tr_em_param_array()

    local index = table_util.index(this.em_param.array, current_value)
    if index then
        config.current.mod.em_param = index
    end
end

---@param event_key string
---@param em_param string
---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT
---@param ignore_environ boolean
local function switch_em_param_mod_array(event_key, em_param, stage, environ, ignore_environ)
    if
        this.current.event_type ~= "monster"
        or (
            event_key == this.current.event
            and stage == this.current.stage
            and environ == this.current.environ
            and ignore_environ == this.current.ignore_environ
            and em_param == this.current.em_param
        )
    then
        return
    end

    local current_value = this.em_param_mod.array and this.em_param_mod.array[config.current.mod.em_param_mod] or nil
    tr_em_param_mod_array()

    local index = table_util.index(this.em_param_mod.array, current_value)
    if index then
        config.current.mod.em_param_mod = index
    end
end

local function switch_spoffer_array()
    if this.current.event_type ~= "monster" then
        return
    end

    local current_value = this.spoffer.array and this.spoffer.array[config.current.mod.spoffer] or nil
    no_tr_update_combo(
        "spoffer",
        table_util.map_array(table_util.values(rt.state.spoffer), function(o)
            return o.unique_index
        end, function(o)
            return o.name
        end),
        nil,
        function(a, b)
            return rt.state.spoffer[a.key].exec_min < rt.state.spoffer[b.key].exec_min
        end
    )
    local index = table_util.index(this.spoffer.array, current_value)
    if index then
        config.current.mod.spoffer = index
    end
end

---@param language string
function this.switch_lang(language)
    if language == this.current.lang then
        return
    end

    this.current.event_type = nil
    this.current.lang = language

    tr_update_combo("event_type")
    tr_update_combo("battlefield_state")
    tr_em_param_array()
    tr_em_param_mod_array()
end

---@param query string
function this.switch_reward_array(query)
    if this.current.reward_filter == query then
        return
    end

    this.current.reward_filter = query

    local current_value = this.reward.filtered_array[config.current.mod.reward_config.reward]
    if this.reward:empty() then
        ---@type SortStruct[]
        local sorted = {}
        for k, v in pairs(ace.item.by_key) do
            table.insert(sorted, { key = k, text = v.name_local })
        end
        table.sort(sorted, function(a, b)
            return a.text < b.text
        end)
        for i = 1, #sorted do
            local value = sorted[i]
            table.insert(this.reward.array, value.text)
            table.insert(this.reward.map, value.key)
        end
    end

    this.reward:filter(function(map_value)
        if query == "" then
            return true
        end

        local number = tonumber(query)
        if number then
            return ace.item.by_key[map_value].id_not_fixed == number
        end

        local query_lower = query:lower()
        local name_lower = ace.item.by_key[map_value].name_local:lower()
        return name_lower:find(query_lower) ~= nil
    end)

    local index = table_util.index(this.reward.filtered_array, current_value)
    if index then
        config.current.mod.reward_config.reward = index
    end
end

---@param event_type string
---@param event string
---@param em_param string
---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT
---@param ignore_environ boolean
function this.switch_event_arrays(event_type, event, em_param, stage, environ, ignore_environ)
    switch_type(event_type, stage)
    switch_area_array(event, em_param, stage, environ, ignore_environ)
    switch_em_param_array(event, stage, environ, ignore_environ)
    switch_em_param_mod_array(event, em_param, stage, environ, ignore_environ)
    switch_spoffer_array()

    this.current.stage = stage
    this.current.event_type = event_type
    this.current.event = event
    this.current.environ = environ
    this.current.ignore_environ = ignore_environ
end

---@param key string
---@return AreaEventData
function this.get_event(key)
    return this.event_table[key]
end

return this
