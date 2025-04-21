---@class (exact) AceData
---@field enum AceEnum
---@field event EventDataBy
---@field item ItemDataBy
---@field ex_field_param app.user_data.ExFieldParam
---@field map AceMap
---@field init fun()
---@field get_monster_name fun(pop_em: app.cExFieldEvent_PopEnemy): string

---@class (exact) AceEnum
---@field ex_event table<app.EX_FIELD_EVENT_TYPE, string>
---@field pop_em_fixed table<app.ExDef.POP_EM_TYPE_Fixed, string>
---@field legendary table<app.EnemyDef.LEGENDARY_ID, string>
---@field em_role table<app.EnemyDef.ROLE_ID, string>
---@field environ table<app.EnvironmentType.ENVIRONMENT, string>
---@field quest_rank table<app.QuestDef.RANK, string>
---@field ex_gimmick table<app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE, string>
---@field gimmick_state table<ace.GimmickDef.BASE_STATE, string>
---@field battlefield_state table<app.cExFieldEvent_Battlefield.BATTLEFIELD_STATE, string>

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

---@class AceData
local this = {
    enum = {
        ex_event = {},
        pop_em_fixed = {},
        legendary = {},
        em_role = {},
        environ = {},
        quest_rank = {},
        ex_gimmick = {},
        gimmick_state = {},
        battlefield_state = {},
    },
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
        },
    },
}

return this
