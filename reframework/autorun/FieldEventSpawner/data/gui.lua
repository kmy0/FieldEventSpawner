---@class (exact) GuiData
---@field combo GuiCombo

---@class (exact) GuiCombo
---@field event_type string[]
---@field em_param string[]
---@field em_param_mod string[]

---@class GuiData
local this = {
    combo = {
        event_type = {
            "monster",
            "gimmick",
            "animal",
        },
        em_param = {
            "legendary",
            "frenzy",
            "boss",
            "normal",
            "swarm",
            "nushi",
            "battlefield_repel",
            "battlefield_slay",
        },
        em_param_mod = {
            "none",
            "legendary",
            "legendary_king",
        },
    },
    map = {
        ---@enum EmParamToRole
        em_param_to_role = {
            legendary = "NORMAL",
            frenzy = "FRENZY",
            boss = "BOSS",
            legendary_king = "NORMAL",
            normal = "NORMAL",
            nushi = "NORMAL",
            swarm = "NORMAL",
            battlefield_repel = "NORMAL",
            battlefield_slay = "NORMAL",
            cocoon = "COCOON",
        },
        ---@enum EmParamModToLeg
        em_param_mod_to_legendary = {
            legendary = "NORMAL",
            legendary_king = "KING",
            none = "NONE",
        },
        ---@enum EmParamToPopEm
        em_param_to_pop_em = {
            frenzy = "FRENZY",
            legendary = "LEGENDARY",
            cocoon = "COCOON",
            normal = "NORMAL",
            nushi = "NUSHI",
            swarm = "SWARM",
            battlefield_repel = "BATTLEFIELD",
            battlefield_slay = "BATTLEFIELD",
            boss = "SWARM",
        },
        ---@enum EventTypeToExEvent
        event_type_to_ex_event = {
            monster = "POP_EM",
            gimmick = "GIMMICK_EVENT",
            animal = "ANIMAL_EVENT",
        },
    },
    ---@enum GuiColors
    colors = {
        bad = 0xff1947ff,
        good = 0xff47ff59,
        info = 0xff27f3f5,
    },
}

return this
