local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
local mod = require("FieldEventSpawner.data.mod")
local sched = require("FieldEventSpawner.schedule.init")
local set = require("FieldEventSpawner.util.imgui.config_set"):new(config)
local spawn_button = require("FieldEventSpawner.gui.spawn_button")
local state = require("FieldEventSpawner.gui.state")
local util_gui = require("FieldEventSpawner.gui.util")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {}

---@param label string
---@param draw_func fun()
---@param enabled_obj boolean?
---@param text_color integer?
---@return boolean
local function draw_menu(label, draw_func, enabled_obj, text_color)
    enabled_obj = enabled_obj == nil and true or enabled_obj

    if text_color then
        imgui.push_style_color(0, text_color)
    end

    local menu = imgui.begin_menu(label, enabled_obj)

    if text_color then
        imgui.pop_style_color(1)
    end

    if menu then
        draw_func()
        imgui.end_menu()
    end

    return menu
end

local function draw_mod_menu()
    imgui.push_style_var(14, Vector2f.new(0, 2))

    set:menu_item(util_gui.tr("menu.config.disable_button_cooldown"), "mod.disable_button_cooldown")
    set:menu_item(util_gui.tr("menu.config.display_cheat_errors"), "mod.display_cheat_errors")
    set:menu_item(util_gui.tr("menu.config.pause_schedule"), "mod.pause_schedule")
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_pause_schedule"))

    imgui.separator()

    set:menu_item(util_gui.tr("mod.box_ignore_environ"), "mod.is_ignore_environ")
    util_imgui.tooltip(config.lang:tr("mod.tooltip_ignore_environ"))
    set:menu_item(util_gui.tr("mod.box_allow_invalid_quest"), "mod.is_allow_invalid_quest")
    set:menu_item(util_gui.tr("menu.config.is_spoffer_size_save"), "mod.is_spoffer_size_save")
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_is_spoffer_size_save"))

    imgui.separator()
    set:menu_item(
        util_gui.tr("menu.config.add_invalid_difficulties"),
        "mod.add_invalid_difficulties"
    )
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_add_invalid_difficulties"))
    set:menu_item(
        util_gui.tr("menu.config.merge_invalid_difficulties"),
        "mod.merge_invalid_difficulties",
        not config.current.mod.add_invalid_difficulties
    )
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_merge_invalid_difficulties"))
    set:menu_item(util_gui.tr("menu.config.add_invalid_rewards"), "mod.add_invalid_rewards")
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_add_invalid_rewards"))
    set:menu_item(
        util_gui.tr("menu.config.merge_invalid_rewards"),
        "mod.merge_invalid_rewards",
        not config.current.mod.add_invalid_rewards
    )
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_merge_invalid_rewards"))
    set:menu_item(util_gui.tr("menu.config.add_missing_monsters"), "mod.add_missing_monsters")
    util_imgui.tooltip(
        config.lang:tr("menu.config.tooltip_add_missing_monsters")
            .. ace.map.missing_em_stage_string
    )
    set:menu_item(
        util_gui.tr("menu.config.add_invalid_monsters"),
        "mod.add_invalid_monsters",
        not config.current.mod.add_missing_monsters
    )
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_add_invalid_monsters"))
    set:menu_item(util_gui.tr("menu.config.add_guardian_arkveld"), "mod.add_guardian_arkveld")
    util_imgui.tooltip(
        config.lang:tr("menu.config.tooltip_add_guardian_arkveld")
            .. ace.map.garkveld_em_stage_string
    )
    set:menu_item(util_gui.tr("menu.config.add_nerscylla_clone"), "mod.add_nerscylla_clone")
    util_imgui.tooltip(config.lang:tr("menu.config.tooltip_add_nerscylla_clone"))

    imgui.pop_style_var(1)
end

local function draw_lang_menu()
    local config_lang = config.current.mod.lang
    imgui.push_style_var(14, Vector2f.new(0, 2))

    for i = 1, #config.lang.sorted do
        local menu_item = config.lang.sorted[i]
        if
            util_imgui.menu_item(menu_item, config_lang.file == menu_item)
            and config_lang.file ~= menu_item
        then
            config_lang.file = menu_item
            config.lang:change()
            config:save()
            state.translate_combo()
        end
    end

    imgui.separator()

    set:menu_item(util_gui.tr("menu.language.fallback"), "mod.lang.fallback")
    util_imgui.tooltip(config.lang:tr("menu.language.tooltip_fallback"))

    imgui.indent(2)
    draw_menu(util_gui.tr("menu.language.font_size.name"), function()
        imgui.spacing()

        if set:slider_int("##font_size_slider", "mod.lang.font_size", 8, 48) then
            config_lang.font_size = math.min(math.max(config_lang.font_size, 8), 48)
        end

        imgui.same_line()

        if imgui.button(util_gui.tr("menu.language.font_size.button_apply")) then
            config.lang:change(nil, config_lang.font_size)
        end

        imgui.spacing()
    end)
    imgui.unindent(2)

    imgui.pop_style_var(1)
end

local function draw_my_events_menu()
    local events = sched.event_cache.get_stage_table(mod.state.stage)
    local step_y = 4 * 46 / config.lang.default_font_size
    local flags = imgui.TableFlags.BordersInner
        | imgui.TableFlags.SizingFixedFit
        | imgui.TableFlags.ScrollY --[[@as ImGuiTableFlags]]

    if
        imgui.begin_table("events_info", 5, flags, Vector2f.new(-1, step_y * config.lang.font_size))
    then
        local sorted = util_table.values(events)
        ---@cast sorted CachedEvent[]
        table.sort(sorted, function(a, b)
            if a.exec_time == b.exec_time then
                return a.unique_index > b.unique_index
            end
            return a.exec_time > b.exec_time
        end)

        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_remove_button"))
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_event"))
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_area"))
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_date"))
        imgui.table_setup_column(util_gui.tr("mod.table_event_headers.header_opt"))

        imgui.table_headers_row()

        for row = 1, #sorted do
            local event = sorted[row]
            imgui.table_next_row()
            imgui.table_set_column_index(0)
            if imgui.button(util_gui.tr("mod.button_remove_event", tostring(row))) then
                local config_mod = config.current.mod

                if not config_mod.disable_button_cooldown then
                    spawn_button.timer:update_args(config.spawn_cooldown.remove)
                    spawn_button.timer:restart()
                end

                sched.remove(mod.state.stage, event.unique_index)
            end

            imgui.table_set_column_index(1)
            imgui.text(event.name)

            imgui.table_set_column_index(2)
            ---@diagnostic disable-next-line: param-type-mismatch
            imgui.text(event.area)

            imgui.table_set_column_index(3)
            imgui.text(os.date("%Y-%m-%d %H:%M:%S", event.timestamp or 0)--[[@as string]])

            imgui.table_set_column_index(4)
            imgui.text(event.opt)
        end
        imgui.end_table()
    end
end

function this.draw()
    draw_menu(util_gui.tr("menu.config.name"), draw_mod_menu)
    draw_menu(util_gui.tr("menu.language.name"), draw_lang_menu)
    draw_menu(util_gui.tr("menu.my_events.name"), draw_my_events_menu)
end

return this
