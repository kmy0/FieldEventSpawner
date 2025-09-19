---@class SpawnButton : CallbackItem
---@field owner GuiItems
---@field cooldown integer
---@field result SpawnResult
---@field state SpawnState
---@field timer Timer

local config = require("FieldEventSpawner.config.init")
local data_ace = require("FieldEventSpawner.data.ace.init")
local data_gui = require("FieldEventSpawner.data.gui")
local data_rt = require("FieldEventSpawner.data.runtime")
local game_data = require("FieldEventSpawner.util.game.data")
local gui_util = require("FieldEventSpawner.gui.util")
local helpers = require("FieldEventSpawner.data.helpers")
local item = require("FieldEventSpawner.util.imgui.item_def.init")
local spawner = require("FieldEventSpawner.schedule.spawner")
local timer = require("FieldEventSpawner.util.misc.timer")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local rl = game_data.reverse_lookup

---@class SpawnButton
local this = {
    cooldown = 0,
    result = data_rt.enum.spawn_result.OK,
    state = data_rt.enum.spawn_button_state.OK,
    timer = timer:new(config.spawn_cooldown.normal),
}
this.__index = this
setmetatable(this, { __index = item.callback })

---@param self SpawnButton
local function callback(self)
    local config_mod = config.current.mod

    self.result = self:spawn()
    if not config_mod.disable_button_cooldown or self.result ~= data_rt.enum.spawn_result.OK then
        self.timer:update_args(
            self.result == data_rt.enum.spawn_result.OK and config.spawn_cooldown.normal
                or config.spawn_cooldown.failed
        )
        self.timer:restart()
    end
end

---@param self SpawnButton
local function is_disabled(self)
    return self.state ~= data_rt.enum.spawn_button_state.OK
        or self.cooldown > 0
        or not self.owner.event:value()
        or (
            (self.owner.is_battlefield() and data_rt.is_in_quest())
            or (
                self.owner.em_param:value() == "battlefield_repel"
                and self.owner.values.area.map[1] == -1
            )
        )
end

function this:draw()
    local button_height = imgui.get_cursor_screen_pos().y

    if
        item.callback.draw(self, self:update() --[[@as string]])
    then
        self:callback()
    end

    button_height = imgui.get_cursor_screen_pos().y - button_height
    if self.result ~= data_rt.enum.spawn_result.OK and self.cooldown > 0 then
        util_imgui.highlight(data_gui.colors.bad, 0, -button_height)
        util_imgui.tooltip(rl(data_rt.enum.spawn_result, self.result))
    elseif self.state ~= data_rt.enum.spawn_button_state.OK then
        util_imgui.highlight(data_gui.colors.bad, 0, -button_height)
        util_imgui.tooltip(
            config.lang:tr(
                string.format(
                    "mod.tooltip_event_error.%s",
                    rl(data_rt.enum.spawn_button_state, self.state)
                )
            )
        )
    end
end

function this:update_spawn_state()
    self.state = data_rt.enum.spawn_button_state.OK

    if
        not self.owner.values.event:empty()
        and (
            self.owner.values.area:empty()
            or (self.owner.event_type:value() == "monster" and self.owner.values.em_param:empty())
        )
    then
        self.state = data_rt.enum.spawn_button_state.BAD_ENVIRONMENT
    elseif not self.owner.values.event:empty() then
        local event = self.owner.values.get_event(self.owner.event:value())
        if
            self.owner.event_type:value() == "monster"
            and data_rt.is_monster_banned(
                data_rt.state.stage,
                event.id,
                rl(
                    data_ace.enum.pop_em_fixed,
                    data_gui.map.em_param_to_pop_em[self.owner.em_param:value()]
                )
            )
        then
            self.state = data_rt.enum.spawn_button_state.EVENT_NOT_AVAILABLE
        elseif
            ---@cast event GimmickData
            self.owner.event_type:value() == "gimmick"
            and event.ex_id == rl(data_ace.enum.ex_gimmick, "ASSIST_NPC")
            and not data_rt.is_npc_unlocked(event.id_not_fixed)
        then
            self.state = data_rt.enum.spawn_button_state.EVENT_NOT_AVAILABLE
        end
    end
end

function this:update()
    self:update_spawn_state()
    self.cooldown = self.timer:active() and math.ceil(self.timer:remaining()) or 0
    local text = gui_util.tr("mod.button_spawn")
    local text_split = util_misc.split_string(text, "##")[1]
    local size = imgui.calc_text_size(text_split)
    size.x = size.x + 6
    size.y = size.y + 6

    self:update_draw_args({ size })

    if self.cooldown == 0 then
        self.result = data_rt.enum.spawn_result.OK
    end
    return self.cooldown > 0 and self.cooldown or text
end

function this:spawn()
    local config_mod = config.current.mod
    local event = self.owner.values.get_event(self.owner.event:value())
    local event_type = self.owner.event_type:value()

    if event_type == "monster" then
        ---@cast event MonsterData
        local em_param = self.owner.em_param:value()
        local role = data_gui.map.em_param_to_role[em_param]
        local role_id = rl(data_ace.enum.em_role, role)
        local legendary = data_gui.map.em_param_mod_to_legendary[self.owner.em_param_mod:value()]
        local legendary_id = rl(data_ace.enum.legendary, legendary)
        local pop_em_type = data_gui.map.em_param_to_pop_em[em_param]
        local rewards = self.owner.is_force_rewards:value() and config_mod.reward_config.array
            or nil
        local environ = self.owner.is_ignore_environ:value()
                and event.map[
                    data_rt.state.stage --[[@as app.FieldDef.STAGE]]
                ].env_by_param[em_param]
            or nil
        local spoffer = self.owner.spoffer:value()
        local difficulty = self.owner.em_difficulty_rank:value()

        -- ensure valid difficulties for specified spoffer
        if spoffer and not difficulty then
            local spoffer_rank = data_rt.state.spoffer[spoffer].rank
            local candidates = self.owner.get_difficulties() --[[@as table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>]]
            difficulty = {}

            for rank, guids in pairs(candidates) do
                if helpers.is_spoffer_pair(rank, spoffer_rank) then
                    difficulty = util_table.merge(difficulty, guids)
                end
            end

            difficulty = util_table.unique(difficulty)
        end

        if self.owner.swarm_count:value() > 0 then
            return spawner.swarm(
                event,
                role_id,
                rl(data_ace.enum.pop_em_fixed, pop_em_type),
                legendary_id,
                data_rt.state.stage,
                self.owner.time:value(),
                self.owner.is_village_boost:value(),
                self.owner.is_yummy:value(),
                self.owner.swarm_count:value(),
                self.owner.area:value(),
                rewards,
                difficulty,
                environ,
                self.owner.em_size:value()
            )
        elseif em_param == "battlefield_repel" or em_param == "battlefield_slay" then
            return spawner.battlefield(
                event,
                role_id,
                legendary_id,
                data_rt.state.stage,
                self.owner.time:value(),
                self.owner.is_yummy:value(),
                data_rt.enum.battlefield_state[em_param],
                self.owner.area:value(),
                rewards,
                difficulty,
                environ,
                self.owner.em_size:value()
            )
        else
            return spawner.monster(
                event,
                role_id,
                rl(data_ace.enum.pop_em_fixed, pop_em_type),
                legendary_id,
                data_rt.state.stage,
                self.owner.time:value(),
                self.owner.is_village_boost:value(),
                self.owner.is_yummy:value(),
                self.owner.area:value(),
                spoffer,
                rewards,
                difficulty,
                environ,
                self.owner.em_size:value()
            )
        end
    elseif event_type == "gimmick" then
        ---@cast event GimmickData
        return spawner.gimmick(
            event,
            data_rt.state.stage,
            self.owner.time:value(),
            self.owner.is_ignore_environ:value(),
            self.owner.area:value()
        )
    elseif event_type == "animal" then
        ---@cast event AnimalData
        return spawner.animal(
            event,
            data_rt.state.stage,
            self.owner.time:value(),
            self.owner.is_ignore_environ:value(),
            self.owner.area:value()
        )
    end
end

---@param owner GuiItems
---@return SpawnButton
function this.init(owner)
    local o = item.callback:new(callback, imgui.button, nil, is_disabled) --[[@as SpawnButton]]
    setmetatable(o, this)
    o.owner = owner
    return o
end

return this.init
