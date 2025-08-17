local lang = require("FieldEventSpawner.lang")
local table_util = require("FieldEventSpawner.table_util")

local this = {}

---@param x number
---@param y number?
function this.set_pos(x, y)
    if not y then
        y = 0
    end
    local pos = imgui.get_cursor_pos()
    pos.x = pos.x + x
    pos.y = pos.y + y
    imgui.set_cursor_pos(pos)
end

---@param color integer
---@param offset_x integer?
---@param offset_y integer?
function this.highlight(color, offset_x, offset_y)
    if not offset_x then
        offset_x = 0
    end
    if not offset_y then
        offset_y = 0
    end
    this.set_pos(offset_x, offset_y)
    imgui.push_style_color(5, color)
    imgui.begin_rect()
    imgui.end_rect(0, 0)
    imgui.pop_style_color(1)
end

---@param str string
---@param x integer
function this.spaced_string(str, x)
    local t = {}
    for i in string.gmatch(str, "([^##]+)") do
        table.insert(t, i)
    end
    if #t > 1 then
        t[1] = string.rep(" ", x) .. t[1] .. string.rep(" ", x)
        return table.concat(t, "##")
    end
    return string.rep(" ", x) .. str .. string.rep(" ", x)
end

---@param str string
---@param key string
---@return boolean
function this.popup_yesno(str, key)
    local ret = false
    if imgui.begin_popup(key, 1 << 27) then
        imgui.spacing()
        imgui.text(this.spaced_string(str, 3))
        imgui.spacing()

        if imgui.button(this.spaced_string("Yes", 3)) then
            imgui.close_current_popup()
            ret = true
        end

        imgui.same_line()

        if imgui.button(this.spaced_string("No", 3)) then
            imgui.close_current_popup()
        end

        imgui.spacing()
        imgui.end_popup()
    end

    return ret
end

---@param text string
---@param seperate boolean?
function this.tooltip(text, seperate)
    if seperate then
        imgui.same_line()
        imgui.text("(?)")
    end
    if imgui.is_item_hovered() then
        imgui.set_tooltip(text)
    end
end

---@param key string
---@param last_key string?
---@return string
function this.tr(key, last_key)
    if not last_key then
        last_key = "name"
    end
    local _key = string.format("%s.%s", key, last_key)
    return lang.tr(_key) .. string.format("##%s", _key)
end

---@param name string
---@param ... any
---@return string
function this.id(name, ...)
    local args = { ... }
    local keys = {}

    for i = 1, #args do
        local arg = args[i]
        if arg then
            table.insert(keys, arg)
        end
    end

    if table_util.empty(keys) then
        return name
    end

    return string.format("%s##%s", name, table.concat(keys, "_"))
end

return this
