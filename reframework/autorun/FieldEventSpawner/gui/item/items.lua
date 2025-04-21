local config = require("FieldEventSpawner.config")
local data = require("FieldEventSpawner.data")
local item = require("FieldEventSpawner.gui.item_def")
local iv = require("FieldEventSpawner.gui.item.values")
local sched = require("FieldEventSpawner.schedule")
local table_util = require("FieldEventSpawner.table_util")
local timer = require("FieldEventSpawner.timer")

local rt = data.runtime
local ace = data.ace

---@type GuiDataState
local state

local this = {}

function this.switch_arrays()
    iv.switch_event_arrays(
        this.event_type:value(),
        this.event:value(),
        this.em_param:value(),
        this.em_param_mod:value(),
        rt.state.stage,
        rt.state.environ,
        this.is_ignore_environ:value()
    )
    iv.switch_reward_array(this.reward_filter:value())
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
    function(config_value)
        return iv.event_type.map[config_value]
    end,
    nil,
    function(self)
        this.switch_arrays()
    end
)

this.event = item.config:new("mod.event", imgui.combo, { iv.event.array }, nil, function(config_value)
    return iv.event.map[config_value]
end, function()
    return iv.event:empty()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.area = item.config:new("mod.area", imgui.combo, { iv.area.array }, nil, function(config_value)
    return iv.area.map[config_value]
end, function()
    return not this.is_force_area:value() or iv.area:empty()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.em_param = item.config:new("mod.em_param", imgui.combo, { iv.em_param.array }, nil, function(config_value)
    return iv.em_param.map[config_value]
end, function()
    return iv.em_param:empty()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.em_param_mod = item.config:new(
    "mod.em_param_mod",
    imgui.combo,
    { iv.em_param_mod.array },
    nil,
    function(config_value)
        return iv.em_param_mod.map[config_value]
    end,
    function()
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
    function(config_value)
        return iv.em_difficulty.map[config_value]
    end,
    function()
        return iv.em_difficulty:empty() or not this.is_force_difficulty:value()
    end,
    function(self)
        this.switch_arrays()
    end,
    is_combo_changed
)

this.spoffer = item.config:new("mod.spoffer", imgui.combo, { iv.spoffer.array }, nil, function(config_value)
    return iv.spoffer.map[config_value]
end, function()
    return not this.is_spoffer:value()
end, function(self)
    this.switch_arrays()
end, is_combo_changed)

this.swarm_count = item.config:new("mod.swarm_count", imgui.slider_int, { 0, 5 }, 0, nil, function()
    local em_param = this.em_param:value()
    return (em_param ~= "swarm" and em_param ~= "boss")
        or (em_param == "legendary" and not iv.current.em_param_struct.boss)
end)

this.time = item.config:new("mod.time", imgui.slider_int, { 1, 60 })
this.is_ignore_environ = item.config:new("mod.is_ignore_environ", imgui.checkbox)
this.is_force_area = item.config:new("mod.is_force_area", imgui.checkbox, nil, false, nil, function()
    return iv.area:empty() or (this.event_type:value() == "monster" and this.em_param:value() == "battlefield_slay")
end)

this.is_yummy = item.config:new("mod.is_yummy", imgui.checkbox, nil, false, nil, function()
    return (this.swarm_count:value() > 0 and this.em_param:value() == "normal")
        or rt.is_in_quest()
        or this.is_force_rewards:value()
end)

this.is_village_boost = item.config:new("mod.is_village_boost", imgui.checkbox, nil, false, nil, function()
    return rt.is_in_quest()
        or not rt.is_village_boost_unlocked(rt.state.stage)
        or is_battlefield()
        or (this.swarm_count:value() > 0 and this.em_param:value() ~= "boss")
end)

this.is_force_rewards = item.config:new("mod.is_force_rewards", imgui.checkbox, nil, false, nil, function()
    return rt.is_in_quest()
end)

this.is_spoffer = item.config:new("mod.is_spoffer", imgui.checkbox, nil, false, nil, function()
    local em_param = this.em_param:value()
    return rt.is_in_quest()
        or not rt.is_spoffer_unlocked(rt.state.stage)
        or is_battlefield()
        or em_param == "swarm"
        or this.swarm_count:value() > 0
        or iv.spoffer:empty()
end)

this.is_force_difficulty = item.config:new("mod.is_force_difficulty", imgui.checkbox, nil, false, nil, function()
    return iv.em_difficulty:empty()
end)

this.spawn = item.callback:new(
    function()
        state.spawn_button.result = state.callbacks.spawn()
        timer.new(
            state.spawn_button.key,
            state.spawn_button.result == rt.enum.spawn_result.OK and config.spawn_cooldown.normal
                or config.spawn_cooldown.failed
        )
    end,
    imgui.button,
    nil,
    function()
        return state.spawn_button.state ~= rt.enum.spawn_button_state.OK
            or state.spawn_button.cooldown > 0
            or not this.event:value()
            or (is_battlefield() and (rt.is_in_quest() or (iv.area.map[1] == -1)))
    end
)

this.clear_schedule = item.callback:new(
    function()
        timer.new(state.spawn_button.key, config.spawn_cooldown.clear_schedule)
        sched.clear()
    end,
    imgui.button,
    nil,
    function()
        ---@diagnostic disable-next-line: return-type-mismatch
        return rt.is_in_quest()
    end
)

this.rebuild_schedule = item.callback:new(
    function()
        timer.new(state.spawn_button.key, config.spawn_cooldown.rebuild_schedule)
        sched.rebuild()
    end,
    imgui.button,
    nil,
    function()
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
    function(config_value)
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
    function()
        return table_util.empty(iv.reward.filtered_array)
    end,
    function(self)
        iv.switch_reward_array(this.reward_filter:value())
    end,
    is_combo_changed
)

this.reward_add = item.callback:new(
    function()
        table.insert(config.current.mod.reward_config.array, this.reward:value())
    end,
    imgui.button,
    nil,
    function()
        return #config.current.mod.reward_config.array >= 10 or not this.reward:value()
    end
)

this.edit_rewards = item.callback:new(
    function()
        state.open_reward_builder = true
    end,
    imgui.button,
    nil,
    function()
        return not this.is_force_rewards:value()
    end
)

---@protected
---@param init_state GuiDataState
function this._init(init_state)
    state = init_state
end

return this
