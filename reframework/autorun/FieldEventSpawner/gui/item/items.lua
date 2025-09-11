local config = require("FieldEventSpawner.config")
local data = require("FieldEventSpawner.data")
local item = require("FieldEventSpawner.gui.item_def")
local iv = require("FieldEventSpawner.gui.item.values")
local sched = require("FieldEventSpawner.schedule")
local table_util = require("FieldEventSpawner.table_util")
local timer = require("FieldEventSpawner.timer")
local util = require("FieldEventSpawner.util")

local rt = data.runtime
local ace = data.ace

---@type GuiDataState
local state

---@class GuiItems
local this = {}

function this.switch_arrays()
    iv.switch_event_arrays(
        this,
        this.event_type:value(),
        this.event:value(),
        this.em_param:value(),
        this.em_param_mod:value(),
        this.em_difficulty:value(),
        rt.state.stage,
        rt.state.environ,
        this.is_ignore_environ:value()
    )
    iv.switch_reward_array(this.reward_filter:value())
end

---@return table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>?
function this.get_difficulties()
    local ret = {}
    local event_type = this.event_type:value()

    if event_type ~= "monster" then
        return
    end

    if this.em_difficulty_rank:value() then
        local index = config.get(this.em_difficulty_rank.config_key)
        local rank = tonumber(util.split_string(iv.em_difficulty_rank.array[index], "##")[1]) --[[@as number]]
        ret[rank] = table_util.deep_copy(this.em_difficulty_rank:value())
    else
        for _, difs in
            pairs(iv.em_difficulty.map --[[@as table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>]])
        do
            for rank, guids in pairs(difs) do
                if not ret[rank] then
                    ret[rank] = table_util.deep_copy(guids)
                else
                    table_util.merge_t(ret[rank], table_util.deep_copy(guids))
                end
            end
        end

        for k, v in pairs(ret) do
            ret[k] = table_util.unique(v)
        end
    end

    return ret
end

---@param self ConfigItem
---@param value any
---@return boolean
local function is_combo_changed(self, value)
    local array = self.imgui_draw_args[2]
    local previous_value = self.previous_value
    local previous_array = self.previous_array
    ---@diagnostic disable-next-line: inject-field
    self.previous_value = array[value]
    ---@diagnostic disable-next-line: inject-field
    self.previous_array = table.concat(array, ",") -- might be a bit too much?
    return previous_value ~= array[value] or previous_array ~= self.previous_array
end

local function is_battlefield()
    local bf = this.em_param:value()
    return bf == "battlefield_slay" or bf == "battlefield_repel"
end

this.event_type = item.config:new(
    "mod.event_type",
    imgui.combo,
    { iv.event_type.array },
    "monster",
    function(self, config_value)
        return iv.event_type.map[config_value]
    end,
    nil,
    function(self)
        this.switch_arrays()
    end
)

this.event = item.config:new("mod.event", imgui.combo, { iv.event.array }, nil, function(self, config_value)
    return iv.event.map[config_value]
end, function(self)
    return iv.event:empty()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.area = item.config:new("mod.area", imgui.combo, { iv.area.array }, nil, function(self, config_value)
    return iv.area.map[config_value]
end, function(self)
    return not this.is_force_area:value() or iv.area:empty()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.em_param = item.config:new("mod.em_param", imgui.combo, { iv.em_param.array }, nil, function(self, config_value)
    return iv.em_param.map[config_value]
end, function(self)
    return iv.em_param:empty()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.em_param_mod = item.config:new(
    "mod.em_param_mod",
    imgui.combo,
    { iv.em_param_mod.array },
    nil,
    function(self, config_value)
        return iv.em_param_mod.map[config_value]
    end,
    function(self)
        return iv.em_param_mod:empty()
    end,
    function(self)
        this.switch_arrays()
    end,
    is_combo_changed
)

this.em_difficulty = item.config:new(
    "mod.em_difficulty",
    imgui.combo,
    { iv.em_difficulty.array },
    nil,
    function(self, config_value)
        return iv.em_difficulty.map[config_value]
    end,
    function(self)
        return iv.em_difficulty:empty() or not this.is_force_difficulty:value()
    end,
    function(self)
        this.switch_arrays()
    end,
    is_combo_changed
)

this.em_difficulty_rank = item.config:new(
    "mod.em_difficulty_rank",
    imgui.combo,
    { iv.em_difficulty_rank.array },
    nil,
    function(self, config_value)
        return iv.em_difficulty_rank.map[config_value]
    end,
    function(self)
        return iv.em_difficulty_rank:empty() or not this.is_force_difficulty:value()
    end,
    function(self)
        this.switch_arrays()
    end,
    is_combo_changed
)

this.spoffer = item.config:new("mod.spoffer", imgui.combo, { iv.spoffer.array }, nil, function(self, config_value)
    return iv.spoffer.map[config_value]
end, function(self)
    return not this.is_spoffer:value()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.swarm_count = item.config:new("mod.swarm_count", imgui.slider_int, { 0, 5 }, 0, nil, function(self)
    local em_param = this.em_param:value()
    return (em_param ~= "swarm" and em_param ~= "boss")
        or (em_param == "legendary" and not iv.current.em_param_struct.boss)
end)

this.em_size = item.config:new("mod.em_size", imgui.slider_int, { 88, 125 }, nil, nil, function(self)
    return not this.is_force_size:value()
end)

this.time = item.config:new("mod.time", imgui.slider_int, { 1, 60 })
this.is_ignore_environ = item.config:new("mod.is_ignore_environ", imgui.checkbox, nil, false)
this.is_force_area = item.config:new("mod.is_force_area", imgui.checkbox, nil, false, nil, function(self)
    return iv.area:empty() or (this.event_type:value() == "monster" and this.em_param:value() == "battlefield_slay")
end)

this.is_yummy = item.config:new("mod.is_yummy", imgui.checkbox, nil, false, nil, function(self)
    return (this.swarm_count:value() > 0 and this.em_param:value() == "normal")
        or rt.is_in_quest()
        or this.is_force_rewards:value()
end)

this.is_village_boost = item.config:new("mod.is_village_boost", imgui.checkbox, nil, false, nil, function(self)
    return rt.is_in_quest()
        or not rt.is_village_boost_unlocked(rt.state.stage)
        or is_battlefield()
        or (this.swarm_count:value() > 0 and this.em_param:value() ~= "boss")
end)

this.is_allow_invalid_quest = item.config:new(
    "mod.is_allow_invalid_quest",
    imgui.checkbox,
    nil,
    false,
    nil,
    function(self)
        return rt.is_in_quest()
    end
)

this.is_force_rewards = item.config:new("mod.is_force_rewards", imgui.checkbox, nil, false, nil, function(self)
    return rt.is_in_quest()
end)

this.is_spoffer = item.config:new("mod.is_spoffer", imgui.checkbox, nil, false, nil, function(self)
    return rt.is_in_quest()
        or not rt.is_spoffer_unlocked(rt.state.stage)
        or is_battlefield()
        or this.swarm_count:value() > 0
        or iv.spoffer:empty()
end)

this.is_force_difficulty = item.config:new("mod.is_force_difficulty", imgui.checkbox, nil, false, nil, function(self)
    return iv.em_difficulty:empty()
end)
this.is_force_size = item.config:new("mod.is_force_size", imgui.checkbox, nil, false, nil, function(self)
    return not this.em_difficulty:value() or this.em_size.imgui_draw_args[2] == this.em_size.imgui_draw_args[3]
end)

this.spawn = item.callback:new(
    function(self)
        state.spawn_button.result = state.callbacks.spawn()
        if not config.current.mod.disable_button_cooldown or state.spawn_button.result ~= rt.enum.spawn_result.OK then
            timer.new(
                state.spawn_button.key,
                state.spawn_button.result == rt.enum.spawn_result.OK and config.spawn_cooldown.normal
                    or config.spawn_cooldown.failed
            )
        end
    end,
    imgui.button,
    nil,
    function(self)
        return state.spawn_button.state ~= rt.enum.spawn_button_state.OK
            or state.spawn_button.cooldown > 0
            or not this.event:value()
            or (
                (is_battlefield() and rt.is_in_quest())
                or (this.em_param:value() == "battlefield_repel" and iv.area.map[1] == -1)
            )
    end
)

this.clear_schedule = item.callback:new(
    function(self)
        if not config.current.mod.disable_button_cooldown then
            timer.new(state.spawn_button.key, config.spawn_cooldown.clear_schedule)
        end
        sched.clear()
    end,
    imgui.button,
    nil,
    function(self)
        ---@diagnostic disable-next-line: return-type-mismatch
        return rt.is_in_quest()
    end
)

this.rebuild_schedule = item.callback:new(
    function(self)
        if not config.current.mod.disable_button_cooldown then
            timer.new(state.spawn_button.key, config.spawn_cooldown.rebuild_schedule)
        end
        sched.rebuild()
    end,
    imgui.button,
    nil,
    function(self)
        ---@diagnostic disable-next-line: return-type-mismatch
        return rt.is_in_quest()
    end
)

this.reward_filter = item.config:new("mod.reward_config.filter", imgui.input_text, nil, nil, nil, nil, function(self)
    iv.switch_reward_array(self:value())
end)

this.reward_count = item.config:new("mod.reward_config.count", imgui.slider_int, { 1, 255 })

this.reward = item.config:new(
    "mod.reward_config.reward",
    imgui.combo,
    { iv.reward.filtered_array },
    nil,
    function(self, config_value)
        local key = iv.reward.filtered_map[config_value]
        local item_data = ace.item.by_key[key]
        if not key or not item_data then
            return
        end
        ---@type GuiRewardData
        return {
            id = item_data.id,
            name = item_data.name_local,
            count = this.reward_count:value(),
        }
    end,
    function(self)
        return table_util.empty(iv.reward.filtered_array)
    end,
    function(self)
        iv.switch_reward_array(this.reward_filter:value())
    end,
    is_combo_changed
)

this.reward_add = item.callback:new(
    function(self)
        table.insert(config.current.mod.reward_config.array, this.reward:value())
    end,
    imgui.button,
    nil,
    function(self)
        return #config.current.mod.reward_config.array >= 10 or not this.reward:value()
    end
)

this.edit_rewards = item.callback:new(
    function(self)
        state.open_reward_builder = true
    end,
    imgui.button,
    nil,
    function(self)
        return not this.is_force_rewards:value()
    end
)

---@protected
---@param init_state GuiDataState
function this._init(init_state)
    state = init_state
end

return this
