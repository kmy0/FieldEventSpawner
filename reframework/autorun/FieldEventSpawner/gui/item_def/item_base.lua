---@class (exact) ItemBase
---@field is_disabled (fun(): boolean)?
---@field imgui_draw_args any[]
---@field protected _draw fun(self: ConfigItem, label: string): any
---@field protected _imgui_draw fun(...)

---@class ItemBase
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this

---@param draw_func fun(...)
---@param draw_args any[]?
---@param is_disabled_func (fun(): boolean)?
---@return ItemBase
function this:new(draw_func, draw_args, is_disabled_func)
    local o = {
        is_disabled = is_disabled_func,
        _imgui_draw = draw_func,
        imgui_draw_args = draw_args and draw_args or {},
    }
    setmetatable(o, self)
    ---@cast o ItemBase
    return o
end

---@param label string
function this:draw(label)
    imgui.begin_disabled(self.is_disabled and self.is_disabled() or false)
    local ret = { self._imgui_draw(label, table.unpack(self.imgui_draw_args)) }
    imgui.end_disabled()
    return table.unpack(ret)
end

return this
