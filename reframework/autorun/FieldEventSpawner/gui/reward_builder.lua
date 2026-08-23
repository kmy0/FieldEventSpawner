---@class GuiRewardData
---@field id app.ItemDef.ID_Fixed
---@field name string
---@field count integer

local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
local gui_helpers = require("FieldEventSpawner.gui.helpers")
local helpers = require("FieldEventSpawner.data.helpers")
local set = require("FieldEventSpawner.util.imgui.config_set"):new(config)
local state = require("FieldEventSpawner.gui.state")
local util_gui = require("FieldEventSpawner.gui.util")
local util_imgui = require("FieldEventSpawner.util.imgui.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {
    window = {
        flags = 0,
        condition = 1 << 1,
    },
    ---@type string?
    type = nil,
}

local function draw_reward_table()
    local confg_reward = config.current.mod.reward_config
    local flags = imgui.TableFlags.BordersInnerV | imgui.TableFlags.SizingFixedFit --[[@as ImGuiTableFlags]]

    if imgui.begin_table("reward_info", 4, flags) then
        imgui.table_setup_column("##1")
        imgui.table_setup_column(util_gui.tr("mod.table_reward_headers.header_remove_button"))
        imgui.table_setup_column(util_gui.tr("mod.table_reward_headers.header_count"))
        imgui.table_setup_column(util_gui.tr("mod.table_reward_headers.header_reward"), 1 << 3)

        imgui.table_headers_row()
        local rewards = confg_reward.array
        local filtered = {}
        for row = 1, #rewards do
            local reward = rewards[row]
            local changed = false
            imgui.table_next_row()
            imgui.table_set_column_index(0)
            imgui.text(row .. ".")

            imgui.table_set_column_index(1)
            if not imgui.button(util_gui.tr("mod.button_remove_reward", tostring(row))) then
                table.insert(filtered, reward)
            end

            imgui.table_set_column_index(2)
            imgui.set_next_item_width(config.lang.font_size * 4)
            ---@diagnostic disable-next-line: param-type-mismatch
            changed, reward.count = imgui.drag_int("##" .. row, reward.count, 1, 1, 255)
            if reward.count > 255 then
                reward.count = 255
            elseif reward.count < 1 then
                reward.count = 1
            end

            if changed then
                config:save()
            end

            imgui.table_set_column_index(3)
            imgui.text(reward.name)
        end

        confg_reward.array = filtered
        if not util_table.empty(filtered) then
            config:save()
        end
        imgui.end_table()
    end
end

local function draw_user_defined()
    local config_mod = config.current.mod

    if
        set:input_text(util_gui.tr("mod.input_reward_filter"), "mod.reward_config.filter")
        or this.type ~= "user_defined"
    then
        config_mod.reward_config.reward = state.combo.item_rewards:filter(
            helpers.filter_item_rewards(config_mod.reward_config.filter),
            config_mod.reward_config.reward
        )
        this.type = "user_defined"
    end

    util_imgui.tooltip(config.lang:tr("mod.tooltip_reward_filter"))
    if #state.combo.item_rewards.values <= 1 then
        util_imgui.fake_combo(
            #state.combo.item_rewards.values == 1 and state.combo.item_rewards.values[1] or "",
            util_gui.tr("mod.combo_reward")
        )
    else
        set:combo(
            util_gui.tr("mod.combo_reward"),
            "mod.reward_config.reward",
            state.combo.item_rewards.values
        )
    end

    imgui.set_next_item_width(
        util_imgui.get_something_with_button_width(util_gui.tr("mod.button_add_reward"))
    )
    set:slider_int(
        "##" .. util_gui.tr("mod.slider_reward_count"),
        "mod.reward_config.count",
        1,
        255
    )

    imgui.begin_disabled(
        #config_mod.reward_config.array >= 10 or not state.combo.item_rewards:get()
    )
    imgui.same_line()
    if imgui.button(util_gui.tr("mod.button_add_reward")) then
        local key = state.combo.item_rewards:get()
        local item_data = ace.item.by_key[key]

        if key and item_data then
            table.insert(config_mod.reward_config.array, {
                id = item_data.id,
                name = item_data.name_local,
                count = config_mod.reward_config.count,
            })
        end

        config:save()
    end
    imgui.end_disabled()

    util_imgui.set_label(util_gui.tr("mod.slider_reward_count"))

    draw_reward_table()
end

local function draw_specific_quest()
    local config_mod = config.current.mod

    if
        set:input_text(util_gui.tr("mod.input_reward_filter"), "mod.reward_config.filter")
        or this.type ~= "specific_quest"
    then
        local event = gui_helpers.get_current_event() --[[@as MonsterData]]
        config_mod.em_invalid_reward = state.combo.em_invalid_reward:filter(
            helpers.filter_specific_quest(event.invalid_rewards, config_mod.reward_config.filter),
            config_mod.em_invalid_reward
        )
        this.type = "specific_quest"
    end

    util_imgui.tooltip(config.lang:tr("mod.tooltip_reward_filter"))

    local drag_width = config.lang.font_size * (50 / 16)
    local combo_width = util_imgui.get_something_with_any_width(drag_width)

    if #state.combo.em_invalid_reward.values <= 1 then
        util_imgui.fake_combo(
            #state.combo.em_invalid_reward.values == 1 and state.combo.em_invalid_reward.values[1]
                or "",
            nil,
            combo_width
        )
    else
        imgui.set_next_item_width(combo_width)
        set:combo(
            "##combo_invalid_rewards",
            "mod.em_invalid_reward",
            state.combo.em_invalid_reward.values
        )
    end

    util_imgui.tooltip(gui_helpers.build_invalid_reward_tooltip())

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
end

function this.draw()
    local gui_reward = config.gui.current.gui.reward_builder

    imgui.set_next_window_pos(
        Vector2f.new(gui_reward.pos_x, gui_reward.pos_y),
        this.window.condition
    )
    imgui.set_next_window_size(
        Vector2f.new(gui_reward.size_x, gui_reward.size_y),
        this.window.condition
    )

    gui_reward.is_opened = imgui.begin_window(
        util_gui.tr("mod.window_reward_builder"),
        gui_reward.is_opened,
        this.window.flags
    )

    imgui.spacing()
    imgui.indent(3)
    local quest_rewards = state.combo.quest_rewards:get()
    local event = gui_helpers.get_current_event() --[[@as MonsterData]]

    if quest_rewards ~= this.type or event.id ~= this.id then
        this.type = nil
        this.id = event.id
    end

    if quest_rewards == "user_defined" then
        draw_user_defined()
    elseif quest_rewards == "specific_quest" then
        draw_specific_quest()
    end

    util_imgui.set_win_state(gui_reward)

    imgui.unindent(3)
    imgui.end_window()
end

return this
