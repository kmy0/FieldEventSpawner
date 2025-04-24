---@class (exact) ConfigItem : ItemBase
---@field default_value any
---@field config_key string
---@field is_disabled (fun(): boolean)?
---@field on_changed_callback (fun())?
---@field is_changed (fun(self: ConfigItem, value: any): boolean)?
---@field protected _getter (fun(config_value): any)?

local config = require("FieldEventSpawner.config")
local item_base = require("FieldEventSpawner.gui.item_def.item_base")

---@class ConfigItem
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = item_base })

---@param config_key string
---@param imgui_draw_func fun(...)
---@param imgui_draw_args any[]?
---@param default_value any?
---@param getter_func (fun(config_value): any)?
---@param is_disabled_func (fun(): boolean)?
---@param on_changed_callback (fun(self: ConfigItem))?
---@param changed_func (fun(self: ConfigItem, value: any): boolean)?
---@return ConfigItem
function this:new(
    config_key,
    imgui_draw_func,
    imgui_draw_args,
    default_value,
    getter_func,
    is_disabled_func,
    on_changed_callback,
    changed_func
)
    if not imgui_draw_args then
        imgui_draw_args = { config.get(config_key) }
    else
        table.insert(imgui_draw_args, 1, config.get(config_key))
    end

    local o = item_base.new(self, imgui_draw_func, imgui_draw_args, is_disabled_func)
    setmetatable(o, self)
    ---@cast o ConfigItem
    o._getter = getter_func
    o.default_value = default_value
    o.config_key = config_key
    o.on_changed_callback = on_changed_callback
    o.is_changed = changed_func
    return o
end

---@return any
function this:value()
    if self.is_disabled and self.is_disabled() then
        return self.default_value
    end

    local value = config.get(self.config_key)
    if self._getter then
        return self._getter(value)
    elseif value then
        return value
    end
    return self.default_value
end

---@param label string
---@return boolean
function this:draw(label)
    self.imgui_draw_args[1] = config.get(self.config_key)
    local changed, value = item_base.draw(self, label)

    if changed or self.is_changed and self:is_changed(value) then
        config.set(self.config_key, value)
        if self.on_changed_callback then
            self:on_changed_callback()
        end
    end
    return changed
end

return this
