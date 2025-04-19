---@class (exact) CallbackItem : ItemBase
---@field callback fun()
---@field protected __index CallbackItem

local item_base = require("FieldEventSpawner.gui.item_def.item_base")

---@class CallbackItem
local this = {}
this.__index = this
setmetatable(this, { __index = item_base })

---@param callback fun()
---@param imgui_draw_func fun(...)
---@param imgui_draw_args any[]?
---@param is_disabled_func (fun(): boolean)?
---@return CallbackItem
function this:new(callback, imgui_draw_func, imgui_draw_args, is_disabled_func)
	local o = item_base.new(self, imgui_draw_func, imgui_draw_args, is_disabled_func)
	setmetatable(o, self)
	---@cast o CallbackItem
	o.callback = callback
	return o
end

---@param label string
function this:draw(label)
	if item_base.draw(self, label) then
		self.callback()
	end
end

return this
