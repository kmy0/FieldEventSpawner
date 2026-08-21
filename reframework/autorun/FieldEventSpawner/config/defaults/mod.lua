---@class (exact) MainSettings : SettingsBase
---@field version string
---@field mod ModSettings

---@class (exact) ModLanguage
---@field file string
---@field fallback boolean
---@field font_size integer

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
---@field merge_invalid_difficulties boolean
---@field add_invalid_difficulties boolean
---@field add_guardian_arkveld boolean
---@field add_missing_monsters boolean
---@field add_invalid_monsters boolean
---@field add_nerscylla_clone boolean
---
---@field event_type integer
---@field event integer
---@field rewards integer
---@field area integer
---@field spoffer integer
---@field em_param integer
---@field em_param_mod integer
---@field battlefield_state integer
---@field em_difficulty integer
---@field em_difficulty_rank integer
---@field em_role integer
---@field em_option_tag integer
---@field em_option_tags table<string, integer>
---@field em_option_em integer
---
---@field em_size integer
---@field time integer
---@field swarm_count integer
---@field spawn_delay integer
---
---@field is_ignore_environ boolean
---@field is_yummy boolean
---@field is_village_boost boolean
---@field is_allow_invalid_quest boolean
---@field is_allow_exclusive_em boolean
---@field is_spoffer_swarm boolean
---@field is_spoffer_size_save boolean

local version = require("FieldEventSpawner.config.version")

---@type MainSettings
return {
    version = version.version,
    mod = {
        lang = {
            file = "en-us",
            fallback = true,
            font_size = 16,
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
        merge_invalid_difficulties = false,
        add_invalid_difficulties = false,
        add_guardian_arkveld = false,
        add_missing_monsters = false,
        add_invalid_monsters = false,
        add_nerscylla_clone = false,
        --
        event = 1,
        event_type = 1,
        rewards = 1,
        area = 1,
        em_param = 1,
        em_param_mod = 1,
        battlefield_state = 1,
        spoffer = 1,
        em_difficulty = 1,
        em_difficulty_rank = 1,
        em_role = 1,
        em_option_tag = 1,
        em_option_tags = {},
        em_option_em = -1,
        --
        time = 30,
        swarm_count = 2,
        em_size = 100,
        spawn_delay = 0,
        --
        is_ignore_environ = false,
        is_yummy = false,
        is_village_boost = false,
        is_allow_invalid_quest = false,
        is_allow_exclusive_em = false,
        is_spoffer_swarm = false,
        is_spoffer_size_save = false,
    },
}
