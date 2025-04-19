local config = require("FieldEventSpawner.config")
local data = require("FieldEventSpawner.data")
local gui_util = require("FieldEventSpawner.gui.util")
local item = require("FieldEventSpawner.gui.item")
local lang = require("FieldEventSpawner.lang")
local reward_builder = require("FieldEventSpawner.gui.reward_builder")
local sched = require("FieldEventSpawner.schedule")
local spawn = require("FieldEventSpawner.spawn")
local table_util = require("FieldEventSpawner.table_util")
local timer = require("FieldEventSpawner.timer")
local util = require("FieldEventSpawner.util")

local ace = data.ace
local gui = data.gui
local rt = data.runtime
local rl = data.util.reverse_lookup

local this = {
    is_opened = false,
}
local window = {
    flags = 1024,
    condition = 1 << 1,
}
local table_data = {
    name = "events_info",
    flags = 1 << 8 | 1 << 7 | 1 << 10 | 1 << 13 | 1 << 25,
}

---@class GuiDataState
local state = {
    spawn_button = {
        key = "spawn_button",
        cooldown = 0,
        result = rt.enum.spawn_result.OK,
        state = rt.enum.spawn_button_state.OK,
        ---@param self table
        ---@param cb_item CallbackItem
        update = function(self, cb_item)
            self.cooldown = math.ceil(timer.remaining_key(self.key))
            local text = gui_util.tr("spawn_button")
            local text_split = util.split_string(text, "##")[1]
            local size = imgui.calc_text_size(text_split)
            size.x = size.x + 6
            size.y = size.y + 6
            cb_item.imgui_draw_args[1] = size
            return self.cooldown > 0 and self.cooldown or text
        end,
    },
    open_reward_builder = false,
    callbacks = {},
}
state.spawn_button.self = state.spawn_button

function state.callbacks.spawn()
    local event = item.values.get_event(item.event:value())
    local event_type = item.event_type:value()

    if event_type == "monster" then
        ---@cast event MonsterData
        local em_param = item.em_param:value()
        local role = gui.map.em_param_to_role[em_param]
        local role_id = rl(ace.enum.em_role, role)
        local legendary = gui.map.em_param_mod_to_legendary[item.em_param_mod:value()]
        local legendary_id = rl(ace.enum.legendary, legendary)
        local pop_em_type = gui.map.em_param_to_pop_em[em_param]

        if item.swarm_count:value() > 0 then
            return spawn.swarm(
                event,
                role_id,
                rl(ace.enum.pop_em_fixed, pop_em_type),
                legendary_id,
                rt.state.stage,
                item.time:value(),
                item.is_village_boost:value(),
                item.is_yummy:value(),
                item.is_ignore_environ:value(),
                item.swarm_count:value(),
                item.area:value(),
                item.is_force_rewards:value() and config.current.mod.reward_config.array or nil
            )
        elseif em_param == "battlefield" then
            return spawn.battlefield(
                event,
                role_id,
                legendary_id,
                rt.state.stage,
                item.time:value(),
                item.is_yummy:value(),
                item.is_ignore_environ:value(),
                rt.enum.battlefield_state[item.battlefield:value()],
                item.area:value(),
                item.is_force_rewards:value() and config.current.mod.reward_config.array or nil
            )
        else
            return spawn.monster(
                event,
                role_id,
                rl(ace.enum.pop_em_fixed, pop_em_type),
                legendary_id,
                rt.state.stage,
                item.time:value(),
                item.is_village_boost:value(),
                item.is_yummy:value(),
                item.is_ignore_environ:value(),
                item.area:value(),
                item.spoffer:value(),
                item.is_force_rewards:value() and config.current.mod.reward_config.array or nil
            )
        end
    elseif event_type == "gimmick" then
        ---@cast event GimmickData
        return spawn.gimmick(
            event,
            rt.state.stage,
            item.time:value(),
            item.is_ignore_environ:value(),
            item.area:value()
        )
    elseif event_type == "animal" then
        ---@cast event AnimalData
        return spawn.animal(event, rt.state.stage, item.time:value(), item.is_ignore_environ:value(), item.area:value())
    end
end

local function draw_event_table()
    local events = sched.cache.get_stage_table(rt.state.stage)
    if
        imgui.begin_table(table_data.name, 3, table_data.flags --[[@as ImGuiTableFlags]], Vector2f.new(0, 4 * 46))
    then
        local sorted = table_util.values(events)
        ---@cast sorted CachedEvent[]
        table.sort(sorted, function(a, b)
            if a.exec_time == b.exec_time then
                return a.unique_index > b.unique_index
            end
            return a.exec_time > b.exec_time
        end)
        imgui.table_setup_column(gui_util.tr("event_table.headers.event_header"), 1 << 3)
        imgui.table_setup_column(gui_util.tr("event_table.headers.area_header"))
        imgui.table_setup_column(gui_util.tr("event_table.headers.remove_button_header"))

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
            if imgui.button(gui_util.tr("event_table.remove_button") .. string.format("_%s", row)) then
                timer.new(state.spawn_button.key, config.spawn_cooldown.remove)
                sched.remove(rt.state.stage, event.unique_index)
            end
        end
        imgui.end_table()
    end
end

---@return SpawnState
local function check_current_event()
    ---@type SpawnState
    local ret = rt.enum.spawn_button_state.OK

    if
        not item.values.event:empty()
        and (item.values.area:empty() or (item.event_type:value() == "monster" and item.values.em_param:empty()))
    then
        ret = rt.enum.spawn_button_state.BAD_ENVIRONMENT
    elseif not item.values.event:empty() then
        local event = item.values.get_event(item.event:value())
        if
            item.event_type:value() == "monster"
            and rt.is_monster_banned(
                rt.state.stage,
                event.id,
                rl(ace.enum.pop_em_fixed, gui.map.em_param_to_pop_em[item.em_param:value()])
            )
        then
            ret = rt.enum.spawn_button_state.EVENT_NOT_AVAILABLE
        elseif
            ---@cast event GimmickData
            item.event_type:value() == "gimmick"
            and event.ex_id == rl(ace.enum.ex_gimmick, "ASSIST_NPC")
            and not rt.is_npc_unlocked(event.id_not_fixed)
        then
            ret = rt.enum.spawn_button_state.EVENT_NOT_AVAILABLE
        end
    else
        state.spawn_button.state = rt.enum.spawn_button_state.OK
    end
    return ret
end

function this.draw()
    if lang.font then
        imgui.push_font(lang.font)
    end

    item.values.switch_lang(config.current.gui.lang)

    imgui.set_next_window_pos(
        Vector2f.new(config.current.gui.main.pos_x, config.current.gui.main.pos_y),
        window.condition
    )
    imgui.set_next_window_size(
        Vector2f.new(config.current.gui.main.size_x, config.current.gui.main.size_y),
        window.condition
    )

    this.is_opened =
        imgui.begin_window(string.format("%s %s", config.name, config.version), this.is_opened, window.flags)

    if not this.is_opened then
        if lang.font then
            imgui.pop_font()
        end
        imgui.end_window()
        local pos = imgui.get_window_pos()
        local size = imgui.get_window_size()
        config.current.gui.main.pos_x, config.current.gui.main.pos_y = pos.x, pos.y
        config.current.gui.main.size_x, config.current.gui.main.size_y = size.x, size.y
        config.save()
        rt.clear_feature_unlock()
        return
    end

    if imgui.begin_menu_bar() then
        if imgui.begin_menu(gui_util.tr("config_menu"), true) then
            if imgui.begin_menu(gui_util.tr("config_menu.entries.lang"), true) then
                for i = 1, #lang.sorted do
                    local menu_item = lang.sorted[i]
                    if imgui.menu_item(menu_item, nil, config.current.gui.lang == menu_item) then
                        config.current.gui.lang = menu_item
                        lang.change()
                    end
                end
                imgui.end_menu()
            end
            imgui.end_menu()
        end
        imgui.end_menu_bar()
    end

    if rt.state.schedule ~= rt.enum.schedule_state["OK"] then
        imgui.indent(3)
        imgui.text_colored(lang.tr("wait_text.name"), gui.colors.bad)
        imgui.unindent(3)
        imgui.end_window()
        return
    end

    imgui.spacing()
    imgui.indent(3)

    item.switch_arrays()

    item.event_type:draw(gui_util.tr("event_type_combo"))
    item.event:draw(gui_util.tr("event_combo"))
    item.area:draw(gui_util.tr("area_combo"))

    if item.event_type:value() == "monster" then
        item.em_param:draw(gui_util.tr("em_param_combo"))
        item.em_param_mod:draw(gui_util.tr("em_param_mod_combo"))
        item.battlefield:draw(gui_util.tr("battlefield_state_combo"))
        item.swarm_count:draw(gui_util.tr("swarm_count_slider"))
        gui_util.tooltip(lang.tr("swarm_count_slider.tooltip.name"))
        item.spoffer:draw(gui_util.tr("spoffer_combo"))
    end

    item.time:draw(gui_util.tr("time_slider"))
    item.is_ignore_environ:draw(gui_util.tr("ignore_environ_box"))
    gui_util.tooltip(lang.tr("ignore_environ_box.tooltip.name"))
    item.is_force_area:draw(gui_util.tr("force_area_box"))

    if item.event_type:value() == "monster" then
        imgui.separator()
        item.is_yummy:draw(gui_util.tr("yummy_box"))
        item.is_village_boost:draw(gui_util.tr("village_boost_box"))
        if not rt.is_village_boost_unlocked(rt.state.stage) then
            gui_util.tooltip(lang.tr("not_available_tooltip.name"), true)
        end
        item.is_spoffer:draw(gui_util.tr("spoffer_box"))
        if not rt.is_spoffer_unlocked(rt.state.stage) then
            gui_util.tooltip(lang.tr("not_available_tooltip.name"), true)
        end
        item.is_force_rewards:draw(gui_util.tr("force_rewards_box"))
        imgui.same_line()
        item.edit_rewards:draw(gui_util.tr("open_rewards_builder_button"))
        imgui.separator()
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    item.spawn:draw(state.spawn_button:update(item.spawn))
    if state.spawn_button.result ~= rt.enum.spawn_result.OK and state.spawn_button.cooldown > 0 then
        gui_util.highlight(gui.colors.bad, 0, -27)
        gui_util.tooltip(rl(rt.enum.spawn_result, state.spawn_button.result))
    elseif state.spawn_button.state ~= rt.enum.spawn_button_state.OK then
        gui_util.highlight(gui.colors.bad, 0, -27)
        gui_util.tooltip(
            lang.tr(string.format("event_error.%s.name", rl(rt.enum.spawn_button_state, state.spawn_button.state)))
        )
    end

    imgui.same_line()
    item.clear_schedule:draw(gui_util.tr("clear_schedule_button"))
    gui_util.tooltip(lang.tr("clear_schedule_button.tooltip.name"))
    imgui.same_line()
    item.rebuild_schedule:draw(gui_util.tr("rebuild_schedule_button"))
    gui_util.tooltip(lang.tr("rebuild_schedule_button.tooltip.name"))

    if imgui.tree_node(gui_util.tr("event_table_tree_node")) then
        draw_event_table()
        imgui.tree_pop()
    end

    state.spawn_button.state = check_current_event()

    if state.open_reward_builder then
        reward_builder.is_opened = true
        reward_builder.draw()
    end

    if not reward_builder.is_opened then
        state.open_reward_builder = false
    end

    if lang.font then
        imgui.pop_font()
    end

    imgui.unindent(3)
    imgui.end_window()
end

function this.init()
    item.init(state)
end

return this
