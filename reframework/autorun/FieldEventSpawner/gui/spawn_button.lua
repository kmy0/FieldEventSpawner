---@class SpawnButton
---@field cooldown integer
---@field result SpawnResult
---@field state SpawnState
---@field timer Timer

local config = require("FieldEventSpawner.config.init")
local e = require("FieldEventSpawner.util.game.enum")
local gui = require("FieldEventSpawner.data.gui")
local helpers = require("FieldEventSpawner.gui.helpers")
local mod = require("FieldEventSpawner.data.mod")
local state = require("FieldEventSpawner.gui.state")
local timer = require("FieldEventSpawner.util.misc.timer")
local util_gui = require("FieldEventSpawner.gui.util")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local rl = util_table.reverse_lookup

---@class SpawnButton
local this = {
    cooldown = 0,
    result = mod.enum.spawn_result.OK,
    state = mod.enum.spawn_button_state.OK,
    timer = timer:new(config.spawn_cooldown.normal),
}

---@protected
function this._update_spawn_state()
    local combo = state.combo
    this.state = mod.enum.spawn_button_state.OK

    if
        not combo.event:is_disabled()
        and (
            helpers.is_combo_empty(combo.area)
            or (combo.event_type:get() == "monster" and helpers.is_combo_empty(combo.em_param))
        )
    then
        this.state = mod.enum.spawn_button_state.BAD_ENVIRONMENT
    elseif not combo.event:is_disabled() then
        local event = helpers.get_current_event()
        if
            state.combo.event_type:get() == "monster"
            and mod.is_monster_banned(
                mod.state.stage,
                event.id,
                e.get("app.ExDef.POP_EM_TYPE_Fixed")[gui.map.em_param_to_pop_em[state.combo.em_param:get()]]
            )
        then
            this.state = mod.enum.spawn_button_state.EVENT_NOT_AVAILABLE
        elseif
            ---@cast event GimmickData
            state.combo.event_type:get() == "gimmick"
            and event.ex_id == e.get("app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE").ASSIST_NPC
            and not mod.is_npc_unlocked(event.id_not_fixed)
        then
            this.state = mod.enum.spawn_button_state.EVENT_NOT_AVAILABLE
        end
    end
end

---@protected
---@return string, Vector2f
function this._update()
    this._update_spawn_state()
    this.cooldown = this.timer:active() and math.ceil(this.timer:remaining()) or 0
    local text = util_gui.tr("mod.button_spawn")
    local text_split = util_misc.split_string(text, "##")[1]
    local size = imgui.calc_text_size(text_split)
    size.x = size.x + 6
    size.y = size.y + 6

    if this.cooldown == 0 then
        this.result = mod.enum.spawn_result.OK
    end
    return tostring(this.cooldown > 0 and this.cooldown or text), size
end

function this.is_disabled()
    return this.state ~= mod.enum.spawn_button_state.OK
        or this.cooldown > 0
        or not state.combo.event:get()
        or (helpers.is_battlefield_current_stage() and mod.is_in_quest())
end

function this.draw()
    local button_height = imgui.get_cursor_screen_pos().y
    local text, size = this._update()

    imgui.begin_disabled(this.is_disabled())
    local button = imgui.button(text, size)
    imgui.end_disabled()

    if button then
        local config_mod = config.current.mod

        this.result = helpers.spawn()
        if not config_mod.disable_button_cooldown or this.result ~= mod.enum.spawn_result.OK then
            this.timer:update_args(
                this.result == mod.enum.spawn_result.OK and config.spawn_cooldown.normal
                    or config.spawn_cooldown.failed
            )
            this.timer:restart()
        end
    end

    button_height = imgui.get_cursor_screen_pos().y - button_height
    if this.result ~= mod.enum.spawn_result.OK and this.cooldown > 0 then
        util_imgui.highlight(gui.colors.bad, 0, -button_height)
        util_imgui.tooltip(rl(mod.enum.spawn_result, this.result))
    elseif this.state ~= mod.enum.spawn_button_state.OK then
        util_imgui.highlight(gui.colors.bad, 0, -button_height)
        util_imgui.tooltip(
            config.lang:tr(
                string.format(
                    "mod.tooltip_event_error.%s",
                    rl(mod.enum.spawn_button_state, this.state)
                )
            )
        )
    end
end

return this
