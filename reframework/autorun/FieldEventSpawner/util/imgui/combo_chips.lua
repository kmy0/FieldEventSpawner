---@class (exact) ComboChipActionButton
---@field label string
---@field is_draw (fun(selection: integer, item_selection: table<string, integer>, combo: Combo, changed: boolean): boolean)?
---@field action fun(selection: integer, item_selection: table<string, integer>, combo: Combo, changed: boolean): boolean, integer

local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")
---@module "FieldEventSpawner.util.imgui.init"
local util_imgui = util_misc.lazy_require("FieldEventSpawner.util.imgui.init")

local this = {}

local FRAME_PADDING_X = 4.0
local ITEM_SPACING_X = 8.0
local SOME_X = 3.0

local COL_BORDER = 0xff4d4e4f
local COL_BORDER_ACTION = 0xff696969
local COL_BG = 0xff1c1b1a

---@param max_x number
---@param text string
---@return boolean
local function is_new_line(max_x, text)
    return imgui.get_cursor_pos().x
            + imgui.calc_text_size(text).x
            + ITEM_SPACING_X
            + FRAME_PADDING_X
            + SOME_X
        >= max_x
end

---@param selection integer
---@param item_selection table<string, integer>
---@param combo Combo
---@return integer
function this.select_item(selection, item_selection, combo)
    local key = combo:get_key(selection)
    if not item_selection[key] then
        item_selection[key] = util_table.empty(item_selection) and 1
            or math.max(table.unpack(util_table.values(item_selection))) + 1
        selection = combo:disable_item(key)
    end

    return selection
end

---@param combo_key string
---@param item_selection table<string, integer>
---@param combo Combo
---@return integer
function this.deselect_item(combo_key, item_selection, combo)
    item_selection[combo_key] = nil
    return combo:enable_item(combo_key)
end

---@param selection integer
---@param item_selection table<string, integer>
---@param combo Combo
---@param changed boolean
---@return boolean, integer
---@diagnostic disable-next-line: unused-local
function this.clear_selection(selection, item_selection, combo, changed)
    combo:enable_all_items()
    util_table.clear(item_selection)
    changed = true
    return changed, 1
end

---@param selection integer
---@param item_selection table<string, integer>
---@param combo Combo
---@param changed boolean
---@return boolean, integer
function this.select_all(selection, item_selection, combo, changed)
    this.clear_selection(selection, item_selection, combo, changed)
    while #combo.map > 0 do
        this.select_item(1, item_selection, combo)
    end
    changed = true
    return changed, 1
end

---@param label string
---@param selection integer
---@param item_selection table<string, integer>
---@param combo Combo
---@param button_label string
---@param action_buttons ComboChipActionButton[]?
---@param tooltip_fn fun()?
---@return boolean, integer
function this.combo_chips(
    label,
    selection,
    item_selection,
    combo,
    button_label,
    action_buttons,
    tooltip_fn
)
    local changed = false
    local id

    label, id = table.unpack(util_misc.split_string(label, "##"))
    local combo_width = util_imgui.get_something_with_button_width(button_label)
    local disabled = util_table.empty(combo.values)

    imgui.begin_disabled(disabled)

    if #combo.values <= 1 then
        util_imgui.fake_combo(
            #combo.values == 1 and combo.values[1] or "",
            nil,
            combo_width,
            disabled
        )
    else
        imgui.set_next_item_width(combo_width)
        ---@diagnostic disable-next-line: cast-local-type
        changed, selection = imgui.combo("##" .. id, selection, combo.values)
    end
    ---@cast selection integer

    imgui.same_line()
    if imgui.button(button_label) then
        this.select_item(selection, item_selection, combo)
        changed = true
    end

    imgui.end_disabled()

    imgui.same_line()
    local max_x = imgui.get_cursor_pos().x

    if label then
        util_imgui.set_label(label)
    end

    if tooltip_fn then
        tooltip_fn()
    end

    if not util_table.empty(item_selection) and not util_table.empty(combo.disabled) then
        local sorted = util_table.sort(util_table.keys(item_selection), function(a, b)
            return item_selection[a] < item_selection[b]
        end)

        imgui.push_style_color(5, COL_BORDER)
        imgui.push_style_var(13, 2)
        imgui.push_style_color(21, COL_BG)

        for i = 1, #sorted do
            local val = sorted[i]
            local text = combo:get_disabled(val).value

            if i ~= 1 and is_new_line(max_x, text) then
                imgui.new_line()
            end

            if imgui.button(string.format("%s##%s_%s", text, label, i)) then
                selection = this.deselect_item(val, item_selection, combo)
                changed = true
            end

            imgui.same_line()
        end

        imgui.pop_style_color(2)
        imgui.pop_style_var(1)

        if action_buttons then
            imgui.push_style_color(5, COL_BORDER_ACTION)
            imgui.push_style_var(13, 2)
            imgui.push_style_color(21, COL_BG)

            for i = 1, #action_buttons do
                local ab = action_buttons[i]

                if ab.is_draw and not ab.is_draw(selection, item_selection, combo, changed) then
                    goto continue
                end

                if is_new_line(max_x, ab.label) then
                    imgui.new_line()
                end

                if imgui.button(string.format("%s##action_button_%s_%s", ab.label, label, i)) then
                    local a_changed = false
                    a_changed, selection = ab.action(selection, item_selection, combo, changed)
                    changed = a_changed or changed
                end

                imgui.same_line()

                ::continue::
            end

            imgui.pop_style_color(2)
            imgui.pop_style_var(1)
        end

        imgui.new_line()
    end

    return changed, selection
end

return this
