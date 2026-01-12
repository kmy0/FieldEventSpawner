---@class (exact) MainSettings : SettingsBase
---@field version string
---@field mod ModSettings

---@class (exact) ModLanguage
---@field file string
---@field fallback boolean

---@class (exact) RewardSettings
---@field array GuiRewardData[]
---@field count integer
---@field filter string
---@field reward integer

---@class (exact) ModSettings
---@field reward_config RewardSettings
---@field lang ModLanguage
---
---@field disable_button_cooldown boolean
---@field display_cheat_errors boolean
---@field pause_schedule boolean
---
---@field event_type integer
---@field event integer
---@field area integer
---@field spoffer integer
---@field em_param integer
---@field em_param_mod integer
---@field battlefield_state integer
---@field em_difficulty integer
---@field em_difficulty_rank integer
---
---@field em_size integer
---@field time integer
---@field swarm_count integer
---@field spawn_delay integer
---
---@field is_ignore_environ boolean
---@field is_yummy boolean
---@field is_village_boost boolean
---@field is_force_area boolean
---@field is_spoffer boolean
---@field is_force_difficulty boolean
---@field is_allow_invalid_quest boolean
---@field is_force_rewards boolean
---@field is_force_size boolean
---@field is_allow_exclusive_em boolean

local version = require("FieldEventSpawner.config.version")

---@type MainSettings
return {
    version = version.version,
    mod = {
        lang = {
            file = "en-us",
            fallback = true,
        },
        reward_config = {
            array = {},
            count = 1,
            filter = "",
            reward = 1,
        },
        disable_button_cooldown = false,
        display_cheat_errors = true,
        pause_schedule = false,
        --
        event = 1,
        event_type = 1,
        area = 1,
        em_param = 1,
        em_param_mod = 1,
        battlefield_state = 1,
        spoffer = 1,
        em_difficulty = 1,
        em_difficulty_rank = 1,
        --
        time = 30,
        swarm_count = 2,
        em_size = 100,
        spawn_delay = 0,
        --
        is_ignore_environ = false,
        is_yummy = false,
        is_village_boost = false,
        is_force_area = false,
        is_spoffer = false,
        is_force_rewards = false,
        is_force_difficulty = false,
        is_allow_invalid_quest = false,
        is_force_size = false,
        is_allow_exclusive_em = false,
    },
}
