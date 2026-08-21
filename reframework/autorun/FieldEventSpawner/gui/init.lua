local ace = require("FieldEventSpawner.data.ace.init")
local combo_values = require("FieldEventSpawner.gui.combo_values")
local config = require("FieldEventSpawner.config.init")
local gui = require("FieldEventSpawner.data.gui")
local helpers = require("FieldEventSpawner.gui.helpers")
local hook = require("FieldEventSpawner.schedule.hook")
local menu_bar = require("FieldEventSpawner.gui.menu_bar")
local mod = require("FieldEventSpawner.data.mod")
local reward_builder = require("FieldEventSpawner.gui.reward_builder")
local sched = require("FieldEventSpawner.schedule.init")
local set = require("FieldEventSpawner.util.imgui.config_set"):new(config)
local spawn_button = require("FieldEventSpawner.gui.spawn_button")
local state = require("FieldEventSpawner.gui.state")
local util_gui = require("FieldEventSpawner.gui.util")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {
    window = {
        flags = 1024,
        condition = 2,
    },
}

---@param combo Combo
---@param name string
---@param config_key string
---@return boolean
local function combo_with_disabled(combo, name, config_key)
    local changed = false
    local disabled = combo:is_disabled()
    imgui.begin_disabled(disabled)

    if #combo.values <= 1 then
        util_imgui.fake_combo(#combo.values == 1 and combo.values[1] or "", name, nil, disabled)
    else
        changed = set:combo(name, config_key, combo.values)
    end

    imgui.end_disabled()

    return changed
end

local function draw_invalid_rewards()
    local drag_width = config.lang.font_size * (50 / 16)
    local combo_width = util_imgui.get_something_with_any_width(drag_width)
    local disabled = helpers.is_invalid_rewards_disabled()

    imgui.begin_disabled(disabled)

    if #state.combo.em_invalid_reward.values <= 1 then
        util_imgui.fake_combo(
            #state.combo.em_invalid_reward.values == 1 and state.combo.em_invalid_reward.values[1]
                or "",
            nil,
            combo_width,
            disabled
        )
    else
        imgui.set_next_item_width(combo_width)
        set:combo(
            "##combo_invalid_rewards",
            "mod.em_invalid_reward",
            state.combo.em_invalid_reward.values
        )
    end

    local event = helpers.get_current_event()
    if event then
        ---@cast event MonsterData
        local rewards = event.invalid_rewards[state.combo.em_invalid_reward:get()]
        if rewards then
            local txt = util_table.values(rewards.items, function(o)
                return string.format("%s x%s", o.name, o.num)
            end)

            util_imgui.tooltip(table.concat(txt, "\n"))
        end
    end

    imgui.same_line()
    imgui.set_next_item_width(drag_width)
    set:drag_int(
        util_gui.tr("mod.em_invalid_reward_slot"),
        "mod.em_invalid_reward_slot",
        0.1,
        1,
        10
    )
    util_imgui.tooltip(config.lang:tr("mod.tooltip_em_invalid_reward_slot"))
    imgui.end_disabled()
end

local function draw_cheat()
    local message = hook.get_cheat_message()
    if message then
        imgui.text_colored(message, gui.colors.bad)
        imgui.separator()
    end
end

---@return string
local function get_monster_crown_text()
    local event = helpers.get_current_event()
    if not event then
        return config.lang:tr("mod.tooltip_em_size")
    end

    ---@cast event MonsterData
    return string.format(
        "%s <= %s, %s >= %s, %s >= %s\n%s",
        config.lang:tr("mod.crown.small"),
        event.crown.small,
        config.lang:tr("mod.crown.large"),
        event.crown.large,
        config.lang:tr("mod.crown.king"),
        event.crown.king,
        config.lang:tr("mod.tooltip_em_size")
    )
end

function this.draw()
    local gui_main = config.gui.current.gui.main
    local gui_reward = config.gui.current.gui.reward_builder
    local config_mod = config.current.mod

    if config.lang.font then
        imgui.push_font(config.lang.font)
    end

    imgui.set_next_window_pos(Vector2f.new(gui_main.pos_x, gui_main.pos_y), this.window.condition)
    imgui.set_next_window_size(
        Vector2f.new(gui_main.size_x, gui_main.size_y),
        this.window.condition
    )

    gui_main.is_opened = imgui.begin_window(
        string.format("%s %s", config.name, config.commit),
        gui_main.is_opened,
        this.window.flags
    )

    util_imgui.set_win_state(gui_main)

    if not gui_main.is_opened then
        if config.lang.font then
            imgui.pop_font()
        end

        config.save_global()
        imgui.end_window()
        return
    end

    if imgui.begin_menu_bar() then
        menu_bar.draw()
        imgui.end_menu_bar()
    end

    imgui.spacing()
    imgui.indent(3)

    if mod.state.schedule ~= mod.enum.schedule_state["OK"] then
        imgui.indent(3)
        imgui.text_colored(config.lang:tr("mod.text_wait"), gui.colors.bad)
        imgui.unindent(3)

        if config.lang.font then
            imgui.pop_font()
        end

        imgui.end_window()
        return
    end

    combo_values.update()

    if config_mod.display_cheat_errors then
        draw_cheat()
    end

    if config_mod.pause_schedule then
        imgui.text_colored(config.lang:tr("misc.text_pause_schedule"), gui.colors.bad)
        imgui.separator()
    end

    util_imgui.draw_child_window("main_buttons", function()
        spawn_button.draw()
        imgui.same_line()

        imgui.begin_disabled(mod.is_in_quest())
        if imgui.button(util_gui.tr("mod.button_clear_schedule")) then
            if not config.current.mod.disable_button_cooldown then
                spawn_button.timer:restart(config.spawn_cooldown.clear_schedule)
            end

            sched.clear()
        end

        util_imgui.tooltip(config.lang:tr("mod.tootlip_clear_schedule"))
        imgui.same_line()

        if imgui.button(util_gui.tr("mod.button_rebuild_schedule")) then
            if not config.current.mod.disable_button_cooldown then
                spawn_button.timer:restart(config.spawn_cooldown.rebuild_schedule)
            end

            sched.rebuild()
        end

        imgui.end_disabled()

        util_imgui.tooltip(config.lang:tr("mod.tooltip_rebuild_schedule"))
        imgui.separator()
    end, 28, 2)

    imgui.begin_child_window("everything_else", { 0, 0 }, false)

    combo_with_disabled(
        state.combo.event_type,
        util_gui.tr("mod.combo_event_type"),
        "mod.event_type"
    )
    combo_with_disabled(state.combo.event, util_gui.tr("mod.combo_event"), "mod.event")

    if state.combo.area:is_disabled() and config_mod.area ~= 1 then
        config:set("mod.area", 1)
    end
    combo_with_disabled(state.combo.area, util_gui.tr("mod.combo_area"), "mod.area")

    set:slider_int(util_gui.tr("mod.slider_time"), "mod.time", 0, 60)

    if helpers.is_spawn_delay_disabled() and config_mod.spawn_delay ~= 0 then
        config:set("mod.spawn_delay", 0)
    end

    imgui.begin_disabled(helpers.is_spawn_delay_disabled())
    set:slider_int(
        util_gui.tr("mod.slider_spawn_delay"),
        "mod.spawn_delay",
        0,
        60,
        config:get("mod.spawn_delay") == 0 and config.lang:tr("misc.text_disabled")
            or config:get("mod.spawn_delay")
    )
    imgui.end_disabled()
    util_imgui.tooltip(config.lang:tr("mod.tooltip_spawn_delay"), true)

    if state.combo.event_type:get() == "monster" then
        util_imgui.separator_text(config.lang:tr("mod.tooltip_category_difficulty"))

        combo_with_disabled(state.combo.em_param, util_gui.tr("mod.combo_em_param"), "mod.em_param")
        combo_with_disabled(state.combo.em_role, util_gui.tr("mod.combo_em_role"), "mod.em_role")
        combo_with_disabled(
            state.combo.em_param_mod,
            util_gui.tr("mod.combo_em_param_mod"),
            "mod.em_param_mod"
        )
        combo_with_disabled(
            state.combo.em_difficulty,
            util_gui.tr("mod.combo_em_param_difficulty"),
            "mod.em_difficulty"
        )
        util_imgui.tooltip(config.lang:tr("mod.tooltip_em_param_difficulty"), true)
        combo_with_disabled(
            state.combo.em_difficulty_rank,
            util_gui.tr("mod.combo_em_param_difficulty_rank"),
            "mod.em_difficulty_rank"
        )
        util_imgui.tooltip(config.lang:tr("mod.tooltip_quest_rank"), true)
        set:combo_chips(
            util_gui.tr("mod.combo_em_option_tag"),
            "mod.em_option_tag",
            config_mod.em_option_tags,
            state.combo.em_option_tag,
            util_gui.tr("mod.button_add_option_tag"),
            nil,
            function()
                util_imgui.tooltip(config.lang:tr("mod.tooltip_combo_em_option_tag"), true)
            end
        )

        util_imgui.separator_text(config.lang:tr("mod.tooltip_category_misc"))

        local disabled = helpers.is_em_size_disabled()
        if disabled and config_mod.em_size ~= -1 then
            config:set("mod.em_size", -1)
        end

        imgui.begin_disabled(disabled)
        set:slider_int(
            util_gui.tr("mod.slider_em_size"),
            "mod.em_size",
            -1,
            state.em_size_max - state.em_size_min,
            config:get("mod.em_size") == -1 and config.lang:tr("misc.text_disabled")
                or config:get("mod.em_size") + state.em_size_min
        )
        imgui.end_disabled()
        util_imgui.tooltip(get_monster_crown_text(), true)

        disabled = helpers.is_swarm_count_disabled()
        if disabled and config_mod.swarm_count ~= 1 then
            config:set("mod.swarm_count", 1)
        end

        imgui.begin_disabled(disabled)
        set:slider_int(
            util_gui.tr("mod.slider_swarm_count"),
            "mod.swarm_count",
            1,
            #state.swarm_count_array,
            state.swarm_count_array[config:get("mod.swarm_count")] < 2
                    and config.lang:tr("misc.text_disabled")
                or tostring(state.swarm_count_array[config:get("mod.swarm_count")])
        )
        imgui.end_disabled()
        util_imgui.tooltip(
            config.lang:tr("mod.tooltip_swarm_count")
                .. (ace.map.swarm_monsters[mod.state.stage] or config.lang:tr("misc.text_none")),
            true
        )

        util_imgui.separator_text(config.lang:tr("mod.tooltip_category_spoffer"))

        if state.combo.spoffer:is_disabled() and config_mod.spoffer ~= 1 then
            config:set("mod.spoffer", 1)
        end

        combo_with_disabled(state.combo.spoffer, util_gui.tr("mod.combo_spoffer"), "mod.spoffer")
        util_imgui.tooltip(config.lang:tr("mod.tooltip_spoffer"), true)
        local spoffer_unlocked = mod.is_spoffer_unlocked(mod.state.stage)
        if not spoffer_unlocked then
            util_imgui.tooltip_exclamation(
                config.lang:tr("mod.tooltip_not_available"),
                gui.colors.bad
            )
        end

        set:checkbox(util_gui.tr("mod.box_allow_exclusive_em"), "mod.is_allow_exclusive_em")
        util_imgui.tooltip(
            config.lang:tr("mod.tooltip_allow_exclusive_em")
                .. (
                    ace.map.exclusive_monsters ~= "" and ace.map.exclusive_monsters
                    or config.lang:tr("misc.text_none")
                ),
            true
        )

        imgui.begin_disabled(helpers.is_spoffer_swarm_disabled())
        set:checkbox(util_gui.tr("mod.box_spoffer_swarm"), "mod.is_spoffer_swarm")
        imgui.end_disabled()
        util_imgui.tooltip(config.lang:tr("mod.tooltip_spoffer_swarm"), true)

        if not spoffer_unlocked then
            util_imgui.tooltip_exclamation(
                config.lang:tr("mod.tooltip_not_available"),
                gui.colors.bad
            )
        end

        util_imgui.separator_text(config.lang:tr("mod.tooltip_category_rewards"))

        combo_with_disabled(
            state.combo.quest_rewards,
            util_gui.tr("mod.combo_rewards"),
            "mod.rewards"
        )
        util_imgui.tooltip(config.lang:tr("mod.tooltip_combo_rewards"), true)

        if config_mod.add_invalid_rewards then
            draw_invalid_rewards()
        end

        imgui.begin_disabled(state.combo.quest_rewards:get() ~= "user_defined")
        if imgui.button(util_gui.tr("mod.button_open_rewards_builder")) then
            gui_reward.is_opened = true
        end
        imgui.end_disabled()

        imgui.begin_disabled(helpers.is_yummy_disabled())
        set:checkbox(util_gui.tr("mod.box_yummy"), "mod.is_yummy")
        imgui.end_disabled()
        util_imgui.tooltip(config.lang:tr("mod.tooltip_yummy"), true)

        imgui.begin_disabled(helpers.is_village_boost_disabled())
        set:checkbox(util_gui.tr("mod.box_village_boost"), "mod.is_village_boost")
        imgui.end_disabled()
        util_imgui.tooltip(config.lang:tr("mod.tooltip_village_boost"), true)
        if not mod.is_village_boost_unlocked(mod.state.stage) then
            util_imgui.tooltip_exclamation(
                config.lang:tr("mod.tooltip_not_available"),
                gui.colors.bad
            )
        end
    end

    if gui_reward.is_opened then
        reward_builder.draw()
    end

    if config.lang.font then
        imgui.pop_font()
    end

    imgui.spacing()
    imgui.unindent(3)
    imgui.end_child_window()
    imgui.end_window()
end

---@return boolean
function this.init()
    state.init()
    return true
end

return this
