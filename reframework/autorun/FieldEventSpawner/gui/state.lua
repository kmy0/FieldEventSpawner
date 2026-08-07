---@class GuiState
---@field combo GuiCombo
---@field em_size_min integer
---@field em_size_max integer

---@class (exact) GuiCombo
---@field event_type Combo
---@field event Combo
---@field area Combo
---@field em_param Combo
---@field em_role Combo
---@field em_param_mod Combo
---@field em_difficulty Combo
---@field em_difficulty_rank Combo
---@field em_option_tag Combo
---@field spoffer Combo
---@field quest_rewards Combo
---@field item_rewards Combo

local combo = require("FieldEventSpawner.util.imgui.combo")
local config = require("FieldEventSpawner.config.init")
local data = require("FieldEventSpawner.data.init")
local helpers = require("FieldEventSpawner.data.helpers")
local m = require("FieldEventSpawner.util.ref.methods")
local mod = require("FieldEventSpawner.data.mod")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local gui = data.gui

---@class GuiState
local this = {
    ---@diagnostic disable-next-line: missing-fields
    combo = {},
    em_size_max = 0,
    em_size_min = 0,
}

local function sort_by_value(a, b)
    if a.key == -1 then
        return true
    elseif b.key == -1 then
        return false
    end
    return a.value < b.value
end

local function sort_by_key(a, b)
    if a.key == -1 then
        return true
    elseif b.key == -1 then
        return false
    end
    return a.key < b.key
end

---@param self Combo
---@return boolean
local function is_disabled(self)
    return #self.map == 1 and self.map[1].key == -1
end

this.combo.event_type = combo:new(nil, {
    sort_fn = sort_by_value,
    translate_fn = function(key)
        return config.lang:tr("mod.combo_event_type_values." .. key)
    end,
    getter_fn = function(self)
        return self:get_key(config.current.mod.event_type)
    end,
})
this.combo.event = combo:new(nil, {
    sort_fn = sort_by_value,
    translate_fn = function(key, value)
        return string.format("%s##%s", value, key)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        return self:get_key(config.current.mod.event)
    end,
})
this.combo.area = combo:new(nil, {
    sort_fn = sort_by_key,
    map_fn = function(o)
        return tostring(o)
    end,
    getter_fn = function(self)
        local ret = self:get_key(config.current.mod.area)
        if ret ~= -1 then
            return ret
        end
    end,
    is_disabled_fn = function(self)
        if is_disabled(self) then
            return true
        end

        local gui_helpers = require("FieldEventSpawner.gui.helpers")

        return (
            this.combo.event_type:get() == "monster"
            and this.combo.em_param:get() == "battlefield_slay"
        )
            or util_table.contains(self.values, tostring(data.ace.map.dummy_area))
            or this.combo.em_param:get() == "invalid"
                and gui_helpers.is_battlefield_monster_current_stage()
    end,
    translate_fn = function(key, value)
        if key == -1 then
            return config.lang:tr("misc.text_random")
        end
        return value
    end,
})
this.combo.em_param = combo:new(nil, {
    sort_fn = sort_by_value,
    translate_fn = function(key)
        return config.lang:tr("mod.combo_em_param_values." .. key)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        return self:get_key(config.current.mod.em_param)
    end,
})
this.combo.em_role = combo:new(nil, {
    sort_fn = sort_by_key,
    translate_fn = function(_, value)
        return config.lang:tr("mod.combo_em_role_values." .. value)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        return self:get_key(config.current.mod.em_role)
    end,
})
this.combo.em_option_tag = combo:new(nil, {
    sort_fn = sort_by_key,
    getter_fn = function()
        local ret = 0
        for bit, _ in pairs(config.current.mod.em_option_tags) do
            ret = ret | tonumber(bit)
        end

        if ret == 0 then
            return
        end

        return ret
    end,
})
this.combo.em_param_mod = combo:new(nil, {
    sort_fn = sort_by_value,
    translate_fn = function(key)
        return config.lang:tr("mod.combo_em_param_mod_values." .. key)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        return self:get_key(config.current.mod.em_param_mod)
    end,
})
this.combo.em_difficulty = combo:new(nil, {
    sort_fn = sort_by_key,
    map_fn = function(o)
        return tostring(o)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        local ret = self:get_key(config.current.mod.em_difficulty)
        if ret == -1 then
            return
        end

        return ret
    end,
    is_disabled_fn = is_disabled,
    translate_fn = function(key, value)
        if key == -1 then
            return config.lang:tr("misc.text_random")
        end
        return value
    end,
})
this.combo.em_difficulty_rank = combo:new(nil, {
    sort_fn = function(a, b)
        local a_rank = m.getRewardRankFromDifficulty(a.key)
        local b_rank = m.getRewardRankFromDifficulty(b.key)

        if a_rank ~= b_rank then
            return a_rank < b_rank
        end

        local a_rate = helpers.get_difficulty_rate(a.key)
        local b_rate = helpers.get_difficulty_rate(b.key)

        return a_rate:get_Health() < b_rate:get_Health()
    end,
    map_fn = function(o)
        return tostring(o)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        local ret = self:get_key(config.current.mod.em_difficulty_rank)
        if ret == -1 then
            return
        end

        return ret
    end,
    is_disabled_fn = function(self)
        return is_disabled(self) or self:get_key(config.current.mod.em_difficulty_rank) == -1
    end,
    translate_fn = function(key, value)
        if key == -1 then
            return config.lang:tr("misc.text_random")
        end

        local gui_helpers = require("FieldEventSpawner.gui.helpers")
        local diff_table = gui_helpers.get_monster_difficulties_table()

        if not diff_table then
            return value
        end

        local em_difficulty = diff_table[this.combo.em_difficulty:get()]
        if not em_difficulty then
            return value
        end

        local rate = helpers.get_difficulty_rate(key)
        return string.format(
            "%s%s   |   %sx %s,  %sx %s,  %sx %s##%s",
            m.getRewardRankFromDifficulty(key),
            config.lang:tr("misc.text_star"),
            util_misc.round(rate:get_Health(), 2),
            config.lang:tr("misc.text_hp"),
            util_misc.round(rate:get_Attack(), 2),
            config.lang:tr("misc.text_attack"),
            util_misc.round(rate:get_PartsVital(), 2),
            config.lang:tr("misc.text_parts_vital"),
            util_game.format_guid(key)
        )
    end,
})
this.combo.spoffer = combo:new(nil, {
    sort_fn = function(a, b)
        if a.key == -1 then
            return true
        elseif b.key == -1 then
            return false
        end
        return mod.state.spoffer[a.key].exec_min < mod.state.spoffer[b.key].exec_min
    end,
    is_disabled_fn = function(self)
        if is_disabled(self) then
            return true
        end
        local helpers = require("FieldEventSpawner.gui.helpers")
        return mod.is_in_quest()
            or not mod.is_spoffer_unlocked(mod.state.stage)
            or helpers.is_battlefield_monster()
            or config.current.mod.swarm_count > 0
            or config.current.mod.spawn_delay > 0
    end,
    translate_fn = function(key, value)
        if key == -1 then
            return config.lang:tr("misc.text_disabled")
        end
        return string.format("%s##%s", value, key)
    end,
    getter_fn = function(self)
        if self:is_disabled() then
            return
        end

        local ret = self:get_key(config.current.mod.spoffer)
        if ret == -1 then
            return
        end

        return ret
    end,
})
this.combo.quest_rewards = combo:new(gui.combo.rewards, {
    sort_fn = function(a, b)
        if a.key == "disabled" then
            return true
        elseif b.key == "disabled" then
            return false
        end
        return a.value < b.value
    end,
    translate_fn = function(key)
        return config.lang:tr("mod.combo_rewards_values." .. key)
    end,
    getter_fn = function(self)
        return self:get_key(config.current.mod.rewards)
    end,
})
this.combo.item_rewards = combo:new(nil, {
    sort_fn = sort_by_value,
    getter_fn = function(self)
        return self:get_key(config.current.mod.reward_config.reward)
    end,
})

function this.translate_combo()
    for _, c in
        pairs(this.combo --[[@as table<string, Combo>]])
    do
        c:translate()
    end
end

function this.init()
    this.combo.event_type:swap(util_table.map_array(gui.combo.event_type))
    this.combo.quest_rewards:swap(util_table.map_array(gui.combo.rewards))
    this.combo.item_rewards:swap(
        helpers.filter_item_rewards(config.current.mod.reward_config.filter)
    )
    this.translate_combo()
end

return this
