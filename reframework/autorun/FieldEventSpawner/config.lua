---@class (exact) WindowState
---@field pos_x integer
---@field pos_y integer
---@field size_x integer
---@field size_y integer
---@field is_opened boolean

---@class (exact) GuiState
---@field main WindowState
---@field reward_builder WindowState
---@field lang string
---@field lang_fallback boolean

---@class (exact) RewardSettings
---@field array GuiRewardData[]
---@field count integer
---@field filter string
---@field reward integer

---@class (exact) ModSettings
---@field event_type integer
---@field disable_button_cooldown boolean
---@field display_cheat_errors boolean
---@field event integer
---@field area integer
---@field spoffer integer
---@field em_param integer
---@field em_param_mod integer
---@field battlefield_state integer
---@field is_ignore_environ boolean
---@field is_yummy boolean
---@field is_village_boost boolean
---@field is_force_area boolean
---@field is_spoffer boolean
---@field is_force_difficulty boolean
---@field is_allow_invalid_quest boolean
---@field time integer
---@field swarm_count integer
---@field is_force_rewards boolean
---@field reward_config RewardSettings
---@field em_difficulty integer
---@field em_difficulty_rank integer

---@class (exact) SpawnCooldown
---@field normal integer
---@field clear_schedule integer
---@field rebuild_schedule integer
---@field failed integer
---@field remove integer

---@class (exact) Settings
---@field gui GuiState
---@field mod ModSettings

---@class (exact) Font
---@field name string?
---@field size integer

---@class (exact) Config
---@field version string
---@field font Font
---@field name string
---@field config_path string
---@field cache_path string
---@field default_lang_path string
---@field spawn_cooldown SpawnCooldown
---@field display_cheat_timer integer
---@field display_cheat_timer_name string
---@field default Settings
---@field current Settings
---@field init fun()
---@field load fun()
---@field save fun()
---@field restore fun()
---@field get fun(key: string): any
---@field set fun(key: string, value: any)

local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

---@class Config
local this = {}

this.version = "0.0.9"
this.name = "FieldEventSpawner"
this.config_path = this.name .. "/config.json"
this.cache_path = this.name .. "/cache.json"
this.default_lang_path = this.name .. "/lang/en-us.json"
this.display_cheat_timer_name = "cheat_timer"
this.display_cheat_timer = 30
this.font = {
    size = 16,
}
this.spawn_cooldown = {
    normal = 3,
    clear_schedule = 10,
    rebuild_schedule = 10,
    failed = 5,
    remove = 3,
}
---@diagnostic disable-next-line: missing-fields
this.current = {}
this.default = {
    gui = {
        main = {
            pos_x = 50,
            pos_y = 50,
            size_x = 800,
            size_y = 700,
            is_opened = false,
        },
        reward_builder = {
            pos_x = 50,
            pos_y = 50,
            size_x = 800,
            size_y = 700,
            is_opened = false,
        },
        lang = "en-us",
        lang_fallback = true,
    },
    mod = {
        disable_button_cooldown = false,
        display_cheat_errors = true,
        event = 1,
        event_type = 1,
        area = 1,
        em_param = 1,
        em_param_mod = 1,
        battlefield_state = 1,
        swarm_count = 2,
        spoffer = 1,
        em_difficulty = 1,
        em_difficulty_rank = 1,
        is_ignore_environ = false,
        is_yummy = false,
        is_village_boost = false,
        is_force_area = false,
        is_spoffer = false,
        is_force_rewards = false,
        is_force_difficulty = false,
        is_allow_invalid_quest = false,
        time = 30,
        reward_config = {
            array = {},
            count = 1,
            filter = "",
            reward = 1,
        },
    },
}

---@param key string
---@return any
function this.get(key)
    local ret = this.current
    if not key:find(".") then
        return ret[key]
    end

    local keys = util.split_string(key, "%.")
    for i = 1, #keys do
        ret = ret[keys[i]]
    end
    return ret
end

---@param key string
---@param value any
function this.set(key, value)
    local t = this.current
    if not key:find(".") then
        t[key] = value
        return
    end
    table_util.set_nested_value(t, util.split_string(key, "%."), value)
end

function this.load()
    local loaded_config = json.load_file(this.config_path)
    if loaded_config then
        this.current = table_util.merge(this.default, loaded_config) --[[@as Settings]]
    else
        this.current = table_util.deep_copy(this.default)
    end
end

function this.save()
    json.dump_file(this.config_path, this.current)
end

function this.restore()
    this.current = table_util.deep_copy(this.default)
    this.save()
end

function this.init()
    this.load()
end

return this
