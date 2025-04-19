local config = require("FieldEventSpawner.config")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local this = {
    ---@type table<string, table<string, any>>
    lang = {},
    ---@type string[]
    sorted = {},
    font = nil,
}

function this.init()
    this.load()
    this.change()
end

function this.load()
    local files = fs.glob(string.format([[%s\\lang\\.*json]], config.name))
    for i = 1, #files do
        local file = files[i]
        local fn = file:match("([^/\\]+)$")
        local name = fn:match("(.+)%..+$")
        this.lang[name] = json.load_file(file)
        table.insert(this.sorted, name)
    end
    table.sort(this.sorted)
end

function this.change()
    local t = this.lang[config.current.gui.lang]
    local font = t._font or {}
    ---@diagnostic disable-next-line: param-type-mismatch
    this.font = imgui.load_font(font.name or config.font.name, font.size or config.font.size, { 0x1, 0xFFFF, 0 })
end

---@param key string
---@return string
function this.tr(key)
    local t = this.lang[config.current.gui.lang]
    local ret

    if not key:find(".") then
        ret = t[key]
    else
        ret = table_util.get_nested_value(t, util.split_string(key, "%."))
    end

    if not ret then
        return string.format("Bad key: %s", key)
    end
    return ret
end

return this
