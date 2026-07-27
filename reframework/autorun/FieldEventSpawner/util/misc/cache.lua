---@class Cache
---@field protected _map table<any, any>
---@field protected _clearable boolean

---@class (exact) CacheMemoizeOptionalArgs
---@field do_hash boolean?
---@field deep_hash_table boolean?
---@field key_index integer?
---@field key_as_string boolean?

local hash = require("FieldEventSpawner.util.misc.hash")

---@class Cache
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
---@type Cache[]
---@diagnostic disable-next-line: inject-field
this._instances = setmetatable({}, { __mode = "v" })

---@return Cache
function this:new()
    local o = {
        _map = {},
        _clearable = true,
    }
    setmetatable(o, self)
    ---@cast o Cache
    table.insert(this._instances, o)
    return o
end

---@param key any
---@param value any
function this:set(key, value)
    ---@diagnostic disable-next-line: no-unknown
    self._map[key] = value
end

---@param key any
---@return any
function this:get(key)
    return self._map[key]
end

---@param deep_hash_table boolean?
---@param ... any
---@return any, string
function this:get_hashed(deep_hash_table, ...)
    local key = hash.hash_args(deep_hash_table, ...)
    return self:get(key), key
end

function this:clear()
    self._map = {}
end

---@generic T: fun(...): any
---@param func T
---@param predicate (fun(cached_value: any, key: any?): boolean)?
---@param optional_args CacheMemoizeOptionalArgs?
---@return T
function this.memoize(func, predicate, optional_args)
    local cache = this:new()
    optional_args = optional_args or {}

    local wrapped = {
        clear = function()
            cache:clear()
        end,
    }
    setmetatable(wrapped, {
        __call = function(_, ...)
            ---@type any
            local key
            if optional_args.do_hash then
                key =
                    ---@diagnostic disable-next-line: param-type-mismatch
                    hash.hash_args(
                        optional_args.deep_hash_table,
                        not optional_args.key_index and ... or select(optional_args.key_index, ...)
                    )
            else
                if select("#", ...) > 0 then
                    ---@diagnostic disable-next-line: no-unknown
                    key = select(optional_args.key_index or 1, ...)
                else
                    key = 1
                end
            end

            if optional_args.key_as_string then
                key = tostring(key)
            end

            local cached = cache:get(key)

            if cached ~= nil and (not predicate or (predicate and predicate(cached, key))) then
                return cached
            end

            ---@diagnostic disable-next-line: no-unknown
            local ret = func(...)
            cache:set(key, ret)

            return ret
        end,
    })

    return wrapped
end

function this.clear_all()
    for _, o in pairs(this._instances) do
        if o._clearable then
            o:clear()
        end
    end
end

return this
