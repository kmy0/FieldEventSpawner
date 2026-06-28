---@class (exact) Combo
---@field values string[]
---@field map ComboMap[]
---@field sort_fn (fun(a: ComboMap, b: ComboMap): boolean)?
---@field map_fn (fun(value: any): string)?
---@field _translate_fn (fun(key: any, value:any): string)?
---@field _is_disabled_fn (fun(self: Combo): boolean)?
---@field _getter_fn (fun(self: Combo): any?)?
---@field disabled ComboMap[]

---@alias ComboMap {key: any, value: string}

---@class (exact) ComboOptionalArgs
---@field sort_fn (fun(a: ComboMap, b: ComboMap): boolean)?
---@field map_fn (fun(value: any): string)?
---@field translate_fn (fun(key: any, value:any): string)?
---@field is_disabled_fn (fun(self: Combo): boolean)?
---@field getter_fn (fun(self: Combo): any?)?
---@field disabled_keys any[]?

local util_table = require("FieldEventSpawner.util.misc.table")

---@class Combo
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this

---@param key_to_value table?
---@param optional_args ComboOptionalArgs?
---@return Combo
function this:new(key_to_value, optional_args)
    optional_args = optional_args or {}

    local o = {
        sort_fn = optional_args.sort_fn,
        map_fn = optional_args.map_fn,
        _translate_fn = optional_args.translate_fn,
        _is_disabled_fn = optional_args.is_disabled_fn,
        _getter_fn = optional_args.getter_fn,
        disabled = {},
        map = {},
        values = {},
    }

    if key_to_value then
        this._map(o, key_to_value)
    end

    setmetatable(o, self)
    ---@cast o Combo

    for _, key in pairs(optional_args.disabled_keys or {}) do
        o:disable_item(key)
    end
    return o
end

---@overload fun(key_to_value: table, current_index: integer): integer
---@overload fun(key_to_value: table)
---@param key_to_value table
---@param current_index integer?
---@param disabled_keys any[]?
---@return integer?
function this:swap(key_to_value, current_index, disabled_keys)
    self.disabled = {}

    if current_index then
        local current_value = self.map[current_index]
        local current_key = current_value and current_value.key
        local ret = current_index

        self:_map(key_to_value)
        if self._translate_fn then
            self:translate()
        end

        if current_key then
            ret = util_table.index(self.map, function(o)
                return o.key == current_key
            end) or 1
        end

        return ret
    end
    self:_map(key_to_value)

    for _, key in pairs(disabled_keys or {}) do
        self:disable_item(key)
    end
end

---@param current_index integer?
function this:translate(current_index)
    if not self._translate_fn then
        return
    end

    self.values = {}
    local current_item = self.map[current_index or 1] or {}
    local current_key = current_item.key

    for _, v in pairs(self.map) do
        v.value = self._translate_fn(v.key, v.value)
    end

    for _, v in pairs(self.disabled) do
        v.value = self._translate_fn(v.key, v.value)
    end

    if self.sort_fn then
        table.sort(self.map, self.sort_fn)
    end

    for i = 1, #self.map do
        local m = self.map[i]
        table.insert(self.values, m.value)
    end

    return util_table.index(self.map, function(o)
        return o.key == current_key
    end) or 1
end

function this:is_disabled()
    if self:empty() then
        return true
    end

    if self._is_disabled_fn then
        return self:_is_disabled_fn()
    end

    return false
end

---@param index integer
---@return any
function this:get_key(index)
    local ret = self.map[index]
    if ret then
        return ret.key
    end
end

---@param index integer
---@return string
function this:get_value(index)
    return self.map[index].value
end

---@return any
function this:get()
    if self._getter_fn then
        return self:_getter_fn()
    end
end

---@param key any?
---@param value string?
---@return ComboMap
function this:get_disabled(key, value)
    return util_table.value(self.disabled, function(_, item)
        return key == item.key or value == item.value
    end) --[[@as ComboMap]]
end

---@param key any?
---@param value string?
---@return integer
function this:disable_item(key, value)
    local index = self:get_index(key, value)
    if index then
        local item = table.remove(self.map, index)
        table.insert(self.disabled, item)
        table.remove(self.values, index)
    end

    return math.max(index - 1, 1)
end

---@param key any?
---@param value string?
---@return integer
function this:enable_item(key, value)
    ---@type integer
    local index

    if key then
        index = util_table.index(self.disabled, function(o)
            return o.key == key
        end) --[[@as integer]]
    elseif value then
        index = util_table.index(self.disabled, function(o)
            return o.value == value
        end) --[[@as integer]]
    end

    local item = table.remove(self.disabled, index)
    table.insert(self.map, item)

    if self.sort_fn then
        table.sort(self.map, self.sort_fn)
    end

    self.values = {}
    for i = 1, #self.map do
        local m = self.map[i]
        table.insert(self.values, m.value)
    end

    return self:get_index(key, value) --[[@as integer]]
end

function this:enable_all_items()
    for _, v in pairs(util_table.values(self.disabled)) do
        self:enable_item(v.key)
    end
end

function this:disable_all_items()
    for _, v in pairs(util_table.values(self.map)) do
        self:disable_item(v.key)
    end
end

---@param key any?
---@param value string?
---@return integer?
function this:get_index(key, value)
    if key then
        return util_table.index(self.map, function(o)
            return o.key == key
        end)
    end

    if value then
        return util_table.index(self.map, function(o)
            return o.value == value
        end)
    end
end

function this:size()
    return #self.values
end

function this:empty()
    return util_table.empty(self.values)
end

---@protected
---@param key_to_value table
function this:_map(key_to_value)
    self.values = {}
    self.map = {}

    local t = key_to_value
    if self.map_fn then
        t = util_table.map_table(t, nil, self.map_fn)
    end

    for k, v in pairs(t) do
        table.insert(self.map, { key = k, value = v })
    end

    if self.sort_fn then
        table.sort(self.map, self.sort_fn)
    end

    for i = 1, #self.map do
        local m = self.map[i]
        table.insert(self.values, m.value)
    end
end

return this
