---@class GuiRewardData
---@field id app.ItemDef.ID_Fixed
---@field name string
---@field count integer

local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
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
    table = {
        name = "reward_info",
        flags = 1 << 8 | 1 << 7 | 1 << 10 | 1 << 13 | 1 << 25,
    },
}

local function draw_reward_table()
    local confg_reward = config.current.mod.reward_config

    if
        imgui.begin_table(
            this.table.name,
            3,
            this.table.flags --[[@as ImGuiTableFlags]],
            Vector2f.new(0, 10 * 28)
        )
    then
        imgui.table_setup_column(util_gui.tr("mod.table_reward_headers.header_reward"), 1 << 3)
        imgui.table_setup_column(util_gui.tr("mod.table_reward_headers.header_count"))
        imgui.table_setup_column(util_gui.tr("mod.table_reward_headers.header_remove_button"))

        imgui.table_headers_row()
        local rewards = confg_reward.array
        local filtered = {}
        for row = 1, #rewards do
            local reward = rewards[row]
            local changed = false
            imgui.table_next_row()
            imgui.table_set_column_index(0)
            imgui.text(reward.name)
            imgui.table_set_column_index(1)
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

            imgui.table_set_column_index(2)
            if not imgui.button(util_gui.tr("mod.button_remove_reward", tostring(row))) then
                table.insert(filtered, reward)
            end
        end

        confg_reward.array = filtered
        if not util_table.empty(filtered) then
            config:save()
        end
        imgui.end_table()
    end
end

function this.draw()
    local gui_reward = config.gui.current.gui.reward_builder
    local config_mod = config.current.mod

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

    if set:input_text(util_gui.tr("mod.input_reward_filter"), "mod.reward_config.filter") then
        config_mod.reward_config.reward = state.combo.item_rewards:swap(
            helpers.filter_item_rewards(config_mod.reward_config.filter),
            config_mod.reward_config.reward
        ) --[[@as number]]
    end

    util_imgui.tooltip(config.lang:tr("mod.tooltip_reward_filter"))
    set:combo(
        util_gui.tr("mod.combo_reward"),
        "mod.reward_config.reward",
        state.combo.item_rewards.values
    )
    set:slider_int(util_gui.tr("mod.slider_reward_count"), "mod.reward_config.count", 1, 255)

    imgui.begin_disabled(
        #config_mod.reward_config.array >= 10 or not state.combo.item_rewards:get()
    )
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

    draw_reward_table()

    util_imgui.set_win_state(gui_reward)

    imgui.unindent(3)
    imgui.end_window()
end

return this
