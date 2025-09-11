---@class GuiRewardData
---@field id app.ItemDef.ID_Fixed
---@field name string
---@field count integer

local config = require("FieldEventSpawner.config")
local gui_util = require("FieldEventSpawner.gui.util")
local item = require("FieldEventSpawner.gui.item")
local lang = require("FieldEventSpawner.lang")

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
    if
        imgui.begin_table(this.table.name, 3, this.table.flags --[[@as ImGuiTableFlags]], Vector2f.new(0, 10 * 28))
    then
        imgui.table_setup_column(gui_util.tr("reward_table.headers.reward_header"), 1 << 3)
        imgui.table_setup_column(gui_util.tr("reward_table.headers.count_header"))
        imgui.table_setup_column(gui_util.tr("reward_table.headers.remove_button_header"))

        imgui.table_headers_row()
        local rewards = config.current.mod.reward_config.array
        local _rewards = {}
        for row = 1, #rewards do
            local reward = rewards[row]
            imgui.table_next_row()
            imgui.table_set_column_index(0)
            imgui.text(reward.name)
            imgui.table_set_column_index(1)
            ---@diagnostic disable-next-line: param-type-mismatch
            imgui.text(reward.count)
            imgui.table_set_column_index(2)
            if not imgui.button(gui_util.tr("reward_table.remove_button") .. string.format("_%s", row)) then
                table.insert(_rewards, reward)
            end
        end

        config.current.mod.reward_config.array = _rewards
        imgui.end_table()
    end
end

function this.draw()
    imgui.set_next_window_pos(
        Vector2f.new(config.current.gui.reward_builder.pos_x, config.current.gui.reward_builder.pos_y),
        this.window.condition
    )
    imgui.set_next_window_size(
        Vector2f.new(config.current.gui.reward_builder.size_x, config.current.gui.reward_builder.size_y),
        this.window.condition
    )

    config.current.gui.reward_builder.is_opened = imgui.begin_window(
        gui_util.tr("reward_builder"),
        config.current.gui.reward_builder.is_opened,
        this.window.flags
    )

    imgui.spacing()
    imgui.indent(3)

    item.reward_filter:draw(gui_util.tr("reward_filter"))
    gui_util.tooltip(lang.tr("reward_filter.tooltip"))
    item.reward:draw(gui_util.tr("reward_combo"))
    item.reward_count:draw(gui_util.tr("reward_count_slider"))
    item.reward_add:draw(gui_util.tr("reward_add_button"))
    draw_reward_table()

    if not config.current.gui.reward_builder.is_opened then
        local pos = imgui.get_window_pos()
        local size = imgui.get_window_size()
        config.current.gui.reward_builder.pos_x, config.current.gui.reward_builder.pos_y = pos.x, pos.y
        config.current.gui.reward_builder.size_x, config.current.gui.reward_builder.size_y = size.x, size.y
    end

    imgui.unindent(3)
    imgui.end_window()
end

return this
