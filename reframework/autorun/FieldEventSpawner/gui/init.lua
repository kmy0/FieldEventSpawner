local config = require("FieldEventSpawner.config.init")
local data_ace = require("FieldEventSpawner.data.ace.init")
local data_gui = require("FieldEventSpawner.data.gui")
local data_rt = require("FieldEventSpawner.data.runtime")
local hook = require("FieldEventSpawner.schedule.hook")
local item = require("FieldEventSpawner.gui.item.init")
local reward_builder = require("FieldEventSpawner.gui.reward_builder")
local sched = require("FieldEventSpawner.schedule.init")
local util_gui = require("FieldEventSpawner.gui.util")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {
    window = {
        flags = 1024,
        condition = 1 << 1,
    },
    table = {
        name = "events_info",
        flags = 1 << 7 | 1 << 13 | 1 << 25,
    },
}

local function draw_event_table()
    local events = sched.event_cache.get_stage_table(data_rt.state.stage)
    if
        imgui.begin_table(
            this.table.name,
            3,
            this.table.flags --[[@as ImGuiTableFlags]],
            Vector2f.new(300, 4 * 46)
        )
    then
        local sorted = util_table.values(events)
        ---@cast sorted CachedEvent[]
        table.sort(sorted, function(a, b)
            if a.exec_time == b.exec_time then
                return a.unique_index > b.unique_index
            end
            return a.exec_time > b.exec_time
        end)
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_event"), 1 << 3)
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_area"))
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_remove_button"))

        imgui.table_headers_row()

        for row = 1, #sorted do
            local event = sorted[row]
            imgui.table_next_row()
            imgui.table_set_column_index(0)
            imgui.text(event.name)
            imgui.table_set_column_index(1)
            ---@diagnostic disable-next-line: param-type-mismatch
            imgui.text(event.area)
            imgui.table_set_column_index(2)
            if imgui.button(util_gui.tr("mod.button_remove_event", tostring(row))) then
                local config_mod = config.current.mod

                if not config_mod.disable_button_cooldown then
                    item.spawn.timer:update_args(config.spawn_cooldown.remove)
                    item.spawn.timer:restart()
                end

                sched.remove(data_rt.state.stage, event.unique_index)
            end
        end
        imgui.end_table()
    end
end

local function draw_cheat()
    local message = hook.get_cheat_message()
    if message then
        imgui.text_colored(message, data_gui.colors.bad)
        imgui.separator()
    end
end

---@return string
local function get_monster_crown_text()
    if item.values.event:empty() or item.event_type:value() ~= "monster" then
        return ""
    end

    local event = item.values.get_event(item.event:value())
    ---@cast event MonsterData
    return string.format(
        "%s <= %s, %s >= %s, %s >= %s",
        config.lang:tr("mod.crown.small"),
        event.crown.small,
        config.lang:tr("mod.crown.large"),
        event.crown.large,
        config.lang:tr("mod.crown.king"),
        event.crown.king
    )
end

function this.draw()
    local gui_main = config.gui.current.gui.main
    local gui_reward = config.gui.current.gui.reward_builder
    local config_mod = config.current.mod
    local config_lang = config_mod.lang

    if config.lang.font then
        imgui.push_font(config.lang.font)
    end

    item.values.switch_lang(config_lang.file)

    imgui.set_next_window_pos(Vector2f.new(gui_main.pos_x, gui_main.pos_y), this.window.condition)
    imgui.set_next_window_size(
        Vector2f.new(gui_main.size_x, gui_main.size_y),
        this.window.condition
    )

    gui_main.is_opened = imgui.begin_window(
        string.format("%s %s", config.name, config.version),
        gui_main.is_opened,
        this.window.flags
    )

    util_imgui.set_win_state(gui_main)

    if not gui_main.is_opened then
        if config.lang.font then
            imgui.pop_font()
        end

        config.save_global()
        data_rt.clear_feature_unlock()
        imgui.end_window()
        return
    end

    if imgui.begin_menu_bar() then
        local changed = false

        if imgui.begin_menu(util_gui.tr("menu.config.name"), true) then
            changed, config_mod.disable_button_cooldown = util_imgui.menu_item(
                util_gui.tr("menu.config.disable_button_cooldown"),
                config_mod.disable_button_cooldown
            )
            changed, config_mod.display_cheat_errors = util_imgui.menu_item(
                util_gui.tr("menu.config.display_cheat_errors"),
                config_mod.display_cheat_errors
            )
            changed, config_mod.pause_schedule = util_imgui.menu_item(
                util_gui.tr("menu.config.pause_schedule"),
                config_mod.pause_schedule
            )
            util_imgui.tooltip(config.lang:tr("menu.config.tooltip_pause_schedule"))

            imgui.end_menu()
        end

        if imgui.begin_menu(util_gui.tr("menu.language.name"), true) then
            for i = 1, #config.lang.sorted do
                local menu_item = config.lang.sorted[i]
                if util_imgui.menu_item(menu_item, config_lang.file == menu_item) then
                    config_lang.file = menu_item
                    config.lang:change()
                    config:save()
                end
            end

            imgui.separator()

            if
                util_imgui.menu_item(util_gui.tr("menu.language.fallback"), config_lang.fallback)
            then
                config_lang.fallback = not config_lang.fallback
            end
            util_imgui.tooltip(config.lang:tr("menu.language.tooltip_fallback"))

            imgui.end_menu()
        end

        if imgui.begin_menu(util_gui.tr("menu.my_events.name"), true) then
            draw_event_table()

            imgui.end_menu()
        end

        if changed then
            config:save()
        end

        imgui.end_menu_bar()
    end

    if data_rt.state.schedule ~= data_rt.enum.schedule_state["OK"] then
        imgui.indent(3)
        imgui.text_colored(config.lang:tr("mod.text_wait"), data_gui.colors.bad)
        imgui.unindent(3)

        if config.lang.font then
            imgui.pop_font()
        end

        imgui.end_window()
        return
    end

    imgui.spacing()
    imgui.indent(3)

    if config_mod.display_cheat_errors then
        draw_cheat()
    end

    if config_mod.pause_schedule then
        imgui.text_colored(config.lang:tr("misc.text_pause_schedule"), data_gui.colors.bad)
        imgui.separator()
    end

    item.switch_arrays()

    util_imgui.draw_child_window("main_buttons", function()
        item.spawn:draw()
        imgui.same_line()
        item.clear_schedule:draw(util_gui.tr("mod.button_clear_schedule"))
        util_imgui.tooltip(config.lang:tr("mod.tootlip_clear_schedule"))
        imgui.same_line()
        item.rebuild_schedule:draw(util_gui.tr("mod.button_rebuild_schedule"))
        util_imgui.tooltip(config.lang:tr("mod.tooltip_rebuild_schedule"))
        imgui.separator()
    end, 28, 2)

    imgui.begin_child_window("everything_else", { 0, 0 }, false)

    item.event_type:draw(util_gui.tr("mod.combo_event_type"))
    item.event:draw(util_gui.tr("mod.combo_event"))
    item.area:draw(util_gui.tr("mod.combo_area"))

    if item.event_type:value() == "monster" then
        item.em_param:draw(util_gui.tr("mod.combo_em_param"))
        item.em_param_mod:draw(util_gui.tr("mod.combo_em_param_mod"))
        item.em_difficulty:draw(util_gui.tr("mod.combo_em_param_difficulty"))
        item.em_difficulty_rank:draw(util_gui.tr("mod.combo_em_param_difficulty_rank"))
        item.em_size:draw(util_gui.tr("mod.slider_em_size"))
        util_imgui.tooltip(get_monster_crown_text(), true)
        item.swarm_count:draw(util_gui.tr("mod.slider_swarm_count"))
        util_imgui.tooltip(config.lang:tr("mod.tooltip_swarm_count"))
        item.spoffer:draw(util_gui.tr("mod.combo_spoffer"))
    end

    item.time:draw(util_gui.tr("mod.slider_time"))
    item.spawn_delay:draw(util_gui.tr("mod.slider_spawn_delay"))
    util_imgui.tooltip(config.lang:tr("mod.tooltip_spawn_delay"))
    item.is_ignore_environ:draw(util_gui.tr("mod.box_ignore_environ"))
    util_imgui.tooltip(config.lang:tr("mod.tooltip_ignore_environ"))
    item.is_force_area:draw(util_gui.tr("mod.box_force_area"))

    if item.event_type:value() == "monster" then
        imgui.separator()
        item.is_yummy:draw(util_gui.tr("mod.box_yummy"))
        item.is_village_boost:draw(util_gui.tr("mod.box_village_boost"))
        if not data_rt.is_village_boost_unlocked(data_rt.state.stage) then
            util_imgui.tooltip(config.lang:tr("mod.tooltip_not_available"), true)
        end
        item.is_spoffer:draw(util_gui.tr("mod.box_spoffer"))
        if not data_rt.is_spoffer_unlocked(data_rt.state.stage) then
            util_imgui.tooltip(config.lang:tr("mod.tooltip_not_available"), true)
        end
        imgui.same_line()
        item.is_allow_exclusive_em:draw(util_gui.tr("mod.box_allow_exclusive_em"))
        util_imgui.tooltip(
            config.lang:tr("mod.tooltip_allow_exclusive_em")
                .. (
                    data_ace.map.exclusive_monsters ~= "" and data_ace.map.exclusive_monsters
                    or config.lang:tr("misc.text_none")
                )
        )
        item.is_force_difficulty:draw(util_gui.tr("mod.box_force_difficulty"))
        item.is_force_size:draw(util_gui.tr("mod.box_force_size"))
        item.is_force_rewards:draw(util_gui.tr("mod.box_force_rewards"))
        imgui.same_line()
        item.edit_rewards:draw(util_gui.tr("mod.button_open_rewards_builder"))
        item.is_allow_invalid_quest:draw(util_gui.tr("mod.box_allow_invalid_quest"))
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

return this
