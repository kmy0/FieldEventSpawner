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
local default = {
    _font = {
        name = nil,
        size = 16,
    },
    config_menu = {
        name = "Config",
        entries = {
            lang = {
                name = "Language",
                fallback = {
                    name = "Fallback",
                    tooltip = "Display message in english if key is missing",
                },
            },
        },
    },
    event_type_combo = {
        values = {
            monster = "Monster",
            gimmick = "Gimmick",
            animal = "Animal",
        },
        name = "Event Type",
    },
    event_combo = {
        name = "Event",
    },
    spoffer_combo = {
        name = "Special Offer Monster",
    },
    area_combo = {
        name = "Area",
    },
    em_param_combo = {
        name = "Difficulty Param",
        values = {
            legendary = "Tempered",
            frenzy = "Frenzied",
            normal = "Normal",
            swarm = "Swarm",
            boss = "Alpha",
            nushi = "Apex",
            battlefield_repel = "Battlefield Repel",
            battlefield_slay = "Battlefield Slay",
        },
    },
    em_param_mod_combo = {
        name = "Difficulty Mod",
        values = {
            none = "None",
            legendary = "Tempered",
            legendary_king = "Arch-Tempered",
        },
    },
    swarm_count_slider = {
        name = "Swarm Count",
        tooltip = {
            name = "Number of extra monsters to include",
        },
    },
    time_slider = {
        name = "Time",
    },
    ignore_environ_box = {
        name = "Ignore Environment",
        tooltip = {
            name = "Bypass event environment requirement",
        },
    },
    force_area_box = {
        name = "Force Area",
    },
    yummy_box = {
        name = "More Rewards",
    },
    spoffer_box = {
        name = "Special Offer",
    },
    village_boost_box = {
        name = "Village Boost",
    },
    force_rewards_box = {
        name = "Force Rewards",
    },
    open_rewards_builder_button = {
        name = "Edit Rewards",
    },
    spawn_button = {
        name = "Spawn",
    },
    clear_schedule_button = {
        name = "Clear Schedule",
        tooltip = {
            name = "Clear ALL events",
        },
    },
    rebuild_schedule_button = {
        name = "Rebuild Schedule",
        tooltip = {
            name = "Clear schedule and fill with new events",
        },
    },
    wait_text = {
        name = "Waiting for valid Stage...",
    },
    event_table = {
        headers = {
            event_header = {
                name = "Event",
            },
            area_header = {
                name = "Area",
            },
            remove_button_header = {
                name = "",
            },
        },
        remove_button = {
            name = "Remove",
        },
    },
    event_table_tree_node = {
        name = "My Events",
    },
    em_swarm_suffix = {
        name = "Swarm",
    },
    not_available_tooltip = {
        name = "Not available on this Stage",
    },
    event_error = {
        BAD_ENVIRONMENT = {
            name = "This event can't be spawned while the current environment is active",
        },
        EVENT_NOT_AVAILABLE = {
            name = "This event is either not unlocked or something is preventing it from spawning",
        },
    },
    reward_filter = {
        name = "Filter",
        tooltip = "Filter by item name or ID",
    },
    reward_combo = {
        name = "Reward",
    },
    reward_count_slider = {
        name = "Amount",
    },
    reward_add_button = {
        name = "Add",
    },
    reward_table = {
        headers = {
            reward_header = {
                name = "Reward",
            },
            count_header = {
                name = "Amount",
            },
            remove_button_header = {
                name = "",
            },
        },
        remove_button = {
            name = "Remove",
        },
    },
    reward_builder = {
        name = "Reward Builder",
    },
    force_difficulty = {
        name = "Force Difficulty",
    },
    em_param_difficulty_combo = {
        name = "Difficulty",
    },
    em_param_difficulty_rank_combo = {
        name = "Quest Rank",
    },
    allow_invalid_quest = {
        name = "Allow Invalid Quests",
    },
}

function this.init()
    this.load()

    local t = this.lang[config.current.gui.lang]
    if not t then
        config.current.gui.lang = config.default.gui.lang
    end
    this.change()
end

function this.load()
    json.dump_file(config.default_lang_path, default)

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

---@protected
---@param t table<string, any>
---@param key string
---@param fallback boolean?
---@return string
function this._tr(t, key, fallback)
    ---@type string
    local ret

    if not key:find(".") then
        ret = t[key]
    else
        ret = table_util.get_nested_value(t, util.split_string(key, "%."))
    end

    if not ret and fallback and config.current.gui.lang ~= config.default.gui.lang then
        return this._tr(default, key)
    elseif not ret then
        return string.format("Bad key: %s", key)
    end

    return ret
end

---@param key string
---@return string
function this.tr(key)
    return this._tr(this.lang[config.current.gui.lang], key, config.current.gui.lang_fallback)
end

return this
