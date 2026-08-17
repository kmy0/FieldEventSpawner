---@class EnumUtil
---@field enums table<string, Enum>

---@generic T
---@class Enum<T> : {[string]: T}, {[T]: string}
---@field field_to_enum table<string, T>
---@field enum_to_field table<T, string>
---@field ok boolean

local util_game = require("FieldEventSpawner.util.game.util")
local util_table = require("FieldEventSpawner.util.misc.table")
local logger = require("FieldEventSpawner.util.misc.logger").g
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_ref = require("FieldEventSpawner.util.ref.init")

---@class EnumUtil
local this = {
    enums = {},
}

---@class Enum
local Enum = {}
---@diagnostic disable-next-line: inject-field
Enum.__index = function(self, key)
    if rawget(Enum, key) then
        return rawget(Enum, key)
    end

    if type(key) == "string" then
        return rawget(self, "field_to_enum")[key]
    elseif type(key) == "number" then
        return rawget(self, "enum_to_field")[key]
    end
end
---@diagnostic disable-next-line: inject-field
Enum.__pairs = function(self)
    return pairs(rawget(self, "field_to_enum"))
end

---@generic T
---@param enum_type `T`
---@param predicate (fun(key: string, value: integer): boolean)?
---@param duplicate_ok boolean?
---@return Enum<T>
function Enum:new(enum_type, predicate, duplicate_ok)
    ---@type Enum
    local o = {
        enum_to_field = {},
        field_to_enum = {},
        ok = false,
    }
    setmetatable(o, self)

    local type_def = util_ref.types.get(enum_type)
    if not type_def then
        return o
    end

    o.field_to_enum = util_game.get_fields(type_def, predicate)
    o.ok = not util_table.empty(o.field_to_enum)

    if o.ok then
        local keys = util_table.sort(util_table.keys(o.field_to_enum), function(a, b)
            if o.field_to_enum[a] == o.field_to_enum[b] then
                return a < b
            end

            return o.field_to_enum[a] < o.field_to_enum[b]
        end)

        for i = 1, #keys do
            local key = keys[i]
            local value = o.field_to_enum[key]

            if not duplicate_ok and o.enum_to_field[value] then
                logger:warn(
                    string.format(
                        "Enum %s: Duplicate values - %s, %s",
                        enum_type,
                        key,
                        o.enum_to_field[value]
                    )
                )
            end

            o.enum_to_field[value] = key
        end

        ---@diagnostic disable-next-line: undefined-field
        if _G.__DUMP_ENUM then
            o:dump(enum_type)
        end
    end

    setmetatable(o, self)
    return o
end

---@param key string
---@param enum integer
function Enum:add(key, enum)
    if self.field_to_enum[key] then
        logger:warn(string.format("Enum %s: Duplicate field - %s", key))
    end

    if self.enum_to_field[enum] then
        logger:warn(string.format("Enum %s: Duplicate values - %s", key, self.enum_to_field[enum]))
    end

    self.field_to_enum[key] = enum
    self.enum_to_field[enum] = key
end

---@param enum_type string
function Enum:dump(enum_type)
    local lines = {
        "---@meta",
        "",
        string.format("---@class (exact) Enum.%s : Enum<%s>", enum_type, enum_type),
    }

    local keys = util_table.keys(self.enum_to_field) --[==[@as integer[]]==]
    table.sort(keys)

    for _, k in ipairs(keys) do
        table.insert(lines, string.format("---@field %s %s", self[k], enum_type))
    end

    for _, k in ipairs(keys) do
        table.insert(lines, string.format('---@field ["%s"] %s', self[k], enum_type))
    end

    for _, k in ipairs(keys) do
        table.insert(lines, string.format('---@field [%s] "%s"', k, self[k]))
    end

    local f = io.open(string.format("ENUM_DUMP/%s.lua", enum_type), "w+") --[[@as file*]]
    f:write(table.concat(lines, "\n"))
    f:write("\n")
    f:close()
end

---@generic T
---@param fixed_type `T`
---@param enum_value integer
---@return T
function this.to_fixed(fixed_type, enum_value)
    ---@cast fixed_type string
    local enum_type = fixed_type:match("(.+)_Fixed$")
    local fixed_enum = this.get(fixed_type) --[[@as {[string]: integer}]]
    local enum = this.get(enum_type) --[[@as {[integer]: string}]]
    local enum_field = enum[enum_value]
    return fixed_enum[enum_field]
end

---@generic T
---@param enum_type `T`
---@param fixed_value integer
---@return T
function this.to_enum(enum_type, fixed_value)
    ---@cast enum_type string
    local fixed_type = enum_type .. "_Fixed"
    local fixed_enum = this.get(fixed_type) --[[@as {[integer]: string}]]
    local enum = this.get(enum_type) --[[@as {[string]: integer}]]
    local fixed_field = fixed_enum[fixed_value]
    return enum[fixed_field]
end

---@generic T
---@param enum_type `T`
---@return fun(): string, T
function this.iter(enum_type)
    local enum = this.get(enum_type) --[[@as Enum<any>]]
    local iter, state, key = pairs(enum)
    return function()
        local value
        key, value = iter(state, key)
        return key, value
    end
end

---@param enum_types string[]
---@return fun(): string, integer
function this.iter_many(enum_types)
    local type_index = 1
    local current_enum = this.get(enum_types[type_index]) --[[@as Enum<any>]]
    local iter, state, key = pairs(current_enum)

    return function()
        while type_index <= #enum_types do
            local value
            key, value = iter(state, key)

            if key ~= nil then
                ---@diagnostic disable-next-line: return-type-mismatch
                return key, value
            end

            type_index = type_index + 1
            if type_index <= #enum_types then
                current_enum = this.get(enum_types[type_index]) --[[@as Enum<any>]]
                iter, state, key = pairs(current_enum)
            end
            ---@diagnostic disable-next-line: missing-return
        end
    end
end

---@generic T
---@param enum_type Enum.`T`
---@return T
function this.get(enum_type)
    if not this.enums[enum_type] then
        ---@diagnostic disable-next-line: assign-type-mismatch
        this.enums[enum_type] = Enum:new(enum_type)
    end

    return this.enums[enum_type]
end

---@generic T
---@param enum_type `T`
---@return Enum<T>
function this.get_noexact(enum_type)
    return this.get(enum_type)
end

---@generic T
---@param enum_type Enum.`T`
---@param predicate (fun(key: string, value: integer): boolean)?
---@param duplicate_ok boolean?
---@return Enum<T>
function this.new(enum_type, predicate, duplicate_ok)
    local ret = Enum:new(enum_type, predicate, duplicate_ok)
    ---@diagnostic disable-next-line: assign-type-mismatch
    this.enums[enum_type] = ret
    return ret
end

---@param fn fun()
---@return boolean
function this.wrap_init(fn)
    local ret = true
    util_misc.try(fn, function(err)
        log.debug(err)
        ret = false
    end)

    ret = not util_table.any(this.enums, function(_, value)
        return not value.ok
    end)

    return ret
end

return this
