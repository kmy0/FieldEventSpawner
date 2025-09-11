---@class MainConfig : ConfigBase
---@field current MainSettings
---@field default MainSettings
---
---@field lang Language
---@field gui GuiConfig
---
---@field version string
---@field commit string
---@field name string
---
---@field default_config_path string
---@field cache_path string
---
---@field spawn_cooldown SpawnCooldown
---@field display_cheat_timer integer
---@field em_size_min integer
---@field em_size_max integer
---@field force_area_timer integer

---@class (exact) SpawnCooldown
---@field normal integer
---@field clear_schedule integer
---@field rebuild_schedule integer
---@field failed integer
---@field remove integer

local config_base = require("FieldEventSpawner.util.misc.config_base")
local lang = require("FieldEventSpawner.config.lang")
local util_misc = require("FieldEventSpawner.util.misc.init")
local version = require("FieldEventSpawner.config.version")

local mod_name = "FieldEventSpawner"
local config_path = util_misc.join_paths(mod_name, "config.json")

---@class MainConfig
local this = config_base:new(require("FieldEventSpawner.config.defaults.mod"), config_path)

this.version = version.version
this.commit = version.commit
this.name = mod_name

this.default_config_path = config_path
this.cache_path = util_misc.join_paths(this.name, "data", "cache.json")

this.display_cheat_timer = 30
this.force_area_timer = 60
this.em_size_max = -1
this.em_size_min = -1
this.spawn_cooldown = {
    normal = 3,
    clear_schedule = 10,
    rebuild_schedule = 10,
    failed = 5,
    remove = 3,
}

this.gui = config_base:new(
    require("FieldEventSpawner.config.defaults.gui"),
    util_misc.join_paths(this.name, "other_configs", "gui.json")
) --[[@as GuiConfig]]
this.lang = lang:new(
    require("FieldEventSpawner.config.defaults.lang"),
    util_misc.join_paths(this.name, "lang"),
    "en-us.json",
    this
)

---@return boolean
function this.init()
    this:load()
    this.gui:load()
    this.lang:load()

    return true
end

return this
