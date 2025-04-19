---@class (exact) GuiData
---@field combo GuiCombo

---@class (exact) GuiCombo
---@field event_type string[]
---@field battlefield_state string[]
---@field em_param string[]

---@class GuiData
local this = {
    combo = {
        event_type = {
            "monster",
            "gimmick",
            "animal",
        },
        battlefield_state = {
            "repel",
            "slay",
        },
        em_param = {
            "legendary",
            "frenzy",
            "boss",
            "normal",
            "swarm",
            "nushi",
            "battlefield",
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
            battlefield = "NORMAL",
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
            battlefield = "BATTLEFIELD",
            boss = "NORMAL",
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
