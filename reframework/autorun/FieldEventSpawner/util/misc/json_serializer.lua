---@class SerializedObj
---@field __type string

---@class JsonSerializer
---@field serializers table<string, fun(obj: any): SerializedObj>
---@field deserializers table<string, fun(obj: SerializedObj): any>

---@class JsonSerializer
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this

--- @param t table
--- @return boolean
local function is_array(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
            return false
        end
        n = n + 1
    end
    for i = 1, n do
        if t[i] == nil then
            return false
        end
    end
    return true
end

--- @param t table
--- @return boolean
local function all_string_keys(t)
    for k in pairs(t) do
        if type(k) ~= "string" then
            return false
        end
    end
    return true
end

---@param serializers table<string, fun(obj: any): SerializedObj>?
---@param deserializers table<string, fun(obj: SerializedObj): any>?
---@return JsonSerializer
function this:new(serializers, deserializers)
    local o = {
        serializers = serializers or {},
        deserializers = deserializers or {},
    }

    setmetatable(o, self)
    ---@cast o JsonSerializer

    return o
end

---@param obj any
---@return string
---@diagnostic disable-next-line: unused-local
function this:get_type_name(obj)
    error("json_serializer: Not implemented...")
end

--- @param type_name string
--- @param serialize_fn fun(obj: any): SerializedObj
--- @param deserialize_fn fun(obj: SerializedObj): any
function this:register(type_name, serialize_fn, deserialize_fn)
    self.serializers[type_name] = serialize_fn
    self.deserializers[type_name] = deserialize_fn
end

--- @param type_name string
function this:unregister(type_name)
    self.serializers[type_name] = nil
    self.deserializers[type_name] = nil
end

--- @param obj any
--- @param type_name string
--- @return SerializedObj
function this:serialize_registered(obj, type_name)
    local fn = type_name and self.serializers[type_name]
    if not fn then
        error(
            ("json_serializer: no serializer registered for type '%s'."):format(tostring(type_name))
        )
    end

    local result = fn(obj)
    result.__type = type_name
    return result
end

--- @param obj any
--- @return table|SerializedObj|any?
function this:serialize(obj)
    if obj == nil then
        return
    end

    local lt = type(obj)
    if lt == "table" then
        if obj.__type and self.serializers[obj.__type] then
            return self:serialize_registered(obj, obj.__type)
        end

        if next(obj) == nil then
            return { __type = "__empty" }
        end

        if is_array(obj) then
            local out = {}
            for i, v in ipairs(obj) do
                out[i] = self:serialize(v)
            end
            return out
        end

        if all_string_keys(obj) then
            local out = {}
            for k, v in pairs(obj) do
                out[k] = self:serialize(v)
            end
            return out
        end

        local kv_pairs = {}
        for k, v in pairs(obj) do
            kv_pairs[#kv_pairs + 1] = { self:serialize(k), self:serialize(v) }
        end
        return { __type = "__map", pairs = kv_pairs }
    end

    if lt == "userdata" then
        return self:serialize_registered(obj, self:get_type_name(obj))
    end

    return obj
end

--- @param data table
--- @return any
function this:deserialize(data)
    if data == nil then
        return
    end

    local lt = type(data)
    if lt == "table" then
        if data.__type == "__empty" then
            return {}
        end

        if data.__type == "__map" then
            local out = {}
            for _, kv in ipairs(data.pairs or {}) do
                local k = self:deserialize(kv[1])
                local v = self:deserialize(kv[2])
                out[k] = v
            end
            return out
        end

        if data.__type then
            local fn = self.deserializers[data.__type]
            if not fn then
                error(
                    ("json_serializer: no deserializer registered for type '%s'."):format(
                        tostring(data.__type)
                    )
                )
            end

            local resolved = {}
            for k, v in pairs(data) do
                if k == "__type" then
                    resolved[k] = v
                else
                    resolved[k] = self:deserialize(v)
                end
            end

            ---@cast resolved SerializedObj
            return fn(resolved)
        end

        local out = {}
        for k, v in pairs(data) do
            out[k] = self:deserialize(v)
        end
        return out
    end

    return data
end

--- @param obj table
--- @param indent number?
--- @return string
function this:to_json(obj, indent)
    return json.dump_string(self:serialize(obj) --[[@as table]], indent)
end

--- @param json_str string
--- @return any
function this:from_json(json_str)
    local data = json.load_string(json_str) --[[@as table]]
    return self:deserialize(data)
end

---@param filepath string
---@return table?
function this:from_file(filepath)
    local ret = json.load_file(filepath)
    if ret then
        ret = self:deserialize(ret)
    end

    return ret
end

---@param filepath string
---@param obj table
---@param indent integer?
function this:dump_file(filepath, obj, indent)
    json.dump_file(filepath, self:serialize(obj), indent)
end

return this
