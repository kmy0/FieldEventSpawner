---@class (exact) AceData
---@field event EventDataBy
---@field item ItemDataBy
---@field ex_field_param app.user_data.ExFieldParam
---@field map AceMap
---@field initialized boolean
---@field invalid_difficulties_loaded boolean
---@field init fun(): boolean
---@field load_invalid_difficulties fun()
---@field restore_em_stage_appearance fun()

---@class (exact) EventDataByType
---@field monster MonsterData[]
---@field animal AnimalData[]
---@field gimmick GimmickData[]

---@class (exact) EventDataBy
---@field by_type EventDataByType
---@field by_stage table<app.FieldDef.STAGE, table<string, table<string, AreaEventData>>>

---@class (exact) ItemDataBy
---@field item ItemData[]
---@field by_key table<string, ItemData>
---@field by_id table<integer, ItemData>

---@class (exact) AceMap
---@field ex_event_to_time_field table<string, string[]>
---@field ex_event_to_id_field table<string, string>
---@field ex_event_to_area_field table<string, string>
---@field ex_gimmick_to_flag table<string, integer>
---@field pop_em_to_param_field table<string, string>
---@field pop_em_to_em_param_key table<string, string>
---@field spoffer_pairings table<string, boolean>
---@field exclusive_monsters string
---@field swarm_monsters table<app.FieldDef.STAGE, string>
---@field em_size_min integer
---@field em_size_max integer
---@field item_key_to_name_local table<string, string>
---@field dummy_area integer
---@field replace_em_rank_guid table<app.EnemyDef.LEGENDARY_ID, string>
---@field bad_monsters table<app.EnemyDef.ID, boolean>
---@field legendary_to_key table<app.EnemyDef.LEGENDARY_ID, string>
---@field missing_em_stage table<app.EnemyDef.ID, app.FieldDef.STAGE[]>
---@field em_stage table<app.EnemyDef.ID, app.FieldDef.STAGE[]>
---@field missing_em_stage_string string
---@field garkveld_em_stage_string string
---@field is_all_em_all_stage boolean

---@class AceData
local this = {
    map = {
        ex_event_to_time_field = {
            POP_EM = { "_FreeMiniValue5" },
            GIMMICK_EVENT = { "_FreeMiniValue1" },
            ANIMAL_EVENT = { "_FreeMiniValue1" },
            BATTLEFIELD = { "_FreeMiniValue1", "_FreeMiniValue2" },
        },
        ex_event_to_id_field = {
            POP_EM = "_FreeValue0",
            GIMMICK_EVENT = "_FreeValue1",
            ANIMAL_EVENT = "_FreeValue1",
            BATTLEFIELD = "_FreeValue1",
        },
        ex_event_to_area_field = {
            POP_EM = "_FreeMiniValue3",
            GIMMICK_EVENT = "_FreeMiniValue0",
            ANIMAL_EVENT = "_FreeMiniValue0",
            BATTLEFIELD = "_FreeMiniValue6",
        },
        ex_gimmick_to_flag = {
            NONE = 0,
            RARE_TOKUSAN = 1,
            ASSIST_NPC = 2,
            ANCIENT_COIN = 4,
        },
        pop_em_to_param_field = {
            NORMAL = "_NormalPopParams",
            NUSHI = "_NushiPopParams",
            SWARM = "_SwarmPopParams",
            BATTLEFIELD = "_BattlefieldPopParams",
            BF_POP_BELONGING = "_BattlefieldPopParams",
            LEGENDARY = "_LegendaryPopParams",
            FRENZY = "_FrenzyPopParams",
            COCOON = "_CocoonPopParams",
            POP_MANY = "_PopManyPopParams",
            POP_MANY_2 = "_PopManyPopParams_2",
        },
        pop_em_to_em_param_key = {
            FRENZY = "frenzy",
            LEGENDARY = "legendary",
            COCOON = "cocoon",
            NORMAL = "normal",
            NUSHI = "nushi",
            SWARM = "swarm",
            BATTLEFIELD = "battlefield_slay",
            BF_POP_BELONGING = "battlefield_repel",
            POP_MANY_2 = "pop_many2",
        },
        spoffer_pairings = {},
        exclusive_monsters = "",
        em_size_min = 88,
        em_size_max = 125,
        swarm_monsters = {},
        item_key_to_name_local = {},
        dummy_area = -100,
        replace_em_rank_guid = {},
        bad_monsters = {},
        legendary_to_key = {},
        missing_em_stage = {},
        em_stage = {},
        missing_em_stage_string = "",
        garkveld_em_stage_string = "",
        is_all_em_all_stage = false,
    },
    initialized = false,
    invalid_difficulties_loaded = false,
}

return this
