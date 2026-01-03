---@class GuiRewardData
---@field id app.ItemDef.ID_Fixed
---@field name string
---@field count integer

local config = require("FieldEventSpawner.config.init")
local gui_util = require("FieldEventSpawner.gui.util")
local item = require("FieldEventSpawner.gui.item.init")
local util_imgui = require("FieldEventSpawner.util.imgui.init")

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
        imgui.table_setup_column(gui_util.tr("mod.table_reward_headers.header_reward"), 1 << 3)
        imgui.table_setup_column(gui_util.tr("mod.table_reward_headers.header_count"))
        imgui.table_setup_column(gui_util.tr("mod.table_reward_headers.header_remove_button"))

        imgui.table_headers_row()
        local rewards = confg_reward.array
        local filtered = {}
        for row = 1, #rewards do
            local reward = rewards[row]
            imgui.table_next_row()
            imgui.table_set_column_index(0)
            imgui.text(reward.name)
            imgui.table_set_column_index(1)
            ---@diagnostic disable-next-line: param-type-mismatch
            imgui.text(reward.count)
            imgui.table_set_column_index(2)
            if not imgui.button(gui_util.tr("mod.button_remove_reward", tostring(row))) then
                table.insert(filtered, reward)
            end
        end

        confg_reward.array = filtered
        imgui.end_table()
    end
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
        gui_util.tr("mod.window_reward_builder"),
        gui_reward.is_opened,
        this.window.flags
    )

    imgui.spacing()
    imgui.indent(3)

    item.reward_filter:draw(gui_util.tr("mod.input_reward_filter"))
    util_imgui.tooltip(config.lang:tr("mod.tooltip_reward_filter"))
    item.reward:draw(gui_util.tr("mod.combo_reward"))
    item.reward_count:draw(gui_util.tr("mod.slider_reward_count"))
    item.reward_add:draw(gui_util.tr("mod.button_add_reward"))
    draw_reward_table()

    util_imgui.set_win_state(gui_reward)

    imgui.unindent(3)
    imgui.end_window()
end

return this
