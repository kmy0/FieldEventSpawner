local animal_data = require("FieldEventSpawner.data.ace.event.animal")
local data_util = require("FieldEventSpawner.data.util")
local gimmick_data = require("FieldEventSpawner.data.ace.event.gimmick")
local gui_data = require("FieldEventSpawner.data.gui")
local item_data = require("FieldEventSpawner.data.ace.item")
local monster_data = require("FieldEventSpawner.data.ace.event.monster")
local util = require("FieldEventSpawner.util")

local this = require("FieldEventSpawner.data.ace.ace")

local rl = data_util.reverse_lookup

---@param ... AreaEventData[]
---@return table<app.FieldDef.STAGE, table<string, table<string, AreaEventData>>>
local function events_by_stage_ctor(...)
    local events = { ... }
    ---@type table<app.FieldDef.STAGE, table<string, table<string, AreaEventData>>>
    local ret = {}

    ---@param stage app.FieldDef.STAGE
    ---@param type string
    local function get_table(stage, type)
        if not ret[stage] then
            ret[stage] = {}
        end
        if not ret[stage][type] then
            ret[stage][type] = {}
        end
        return ret[stage][type]
    end

    for _, event_t in pairs(events) do
        for _, event in pairs(event_t) do
            for stage, map in pairs(event.map) do
                local event_type = rl(gui_data.map.event_type_to_ex_event, this.enum.ex_event[event.type])
                local t = get_table(map.stage, event_type)
                t[string.format("%s_%s_%s_event_name", stage, event_type, event.id)] = event
            end
        end
    end
    return ret
end

---@param item_array ItemData[]
---@return ItemDataBy
local function item_by_ctor(item_array)
    ---@type ItemDataBy
    local ret = {
        item = item_array,
        by_key = {},
        by_id = {},
    }
    for _, item in pairs(item_array) do
        ret.by_key[item.key] = item
        ret.by_id[item.id_not_fixed] = item
    end
    return ret
end

---@param pop_em app.cExFieldEvent_PopEnemy
---@return string
function this.get_monster_name(pop_em)
    local id = pop_em:get_EmID()
    local guid

    if pop_em._FreeMiniValue2 >> 0 == rl(this.enum.em_role, "BOSS") then
        guid = util.getEnemyExtraName:call(nil, id)
    elseif pop_em._FreeMiniValue2 >> 0 == rl(this.enum.em_role, "FRENZY") then
        guid = util.getEnemyFrenzyName:call(nil, id)
    elseif pop_em._FreeMiniValue2 >> 4 == rl(this.enum.legendary, "NORMAL") then
        guid = util.getEnemyLegendaryName:call(nil, id)
    elseif pop_em._FreeMiniValue2 >> 4 == rl(this.enum.legendary, "KING") then
        guid = util.getEnemyLegendaryKingName:call(nil, id)
    else
        guid = util.getEnemyNameGuid:call(nil, id)
    end
    return util.get_message_local(guid, util.get_language(), true)
end

function this.init()
    data_util.get_enum("app.EX_FIELD_EVENT_TYPE", this.enum.ex_event)
    data_util.get_enum("app.ExDef.POP_EM_TYPE_Fixed", this.enum.pop_em_fixed)
    data_util.get_enum("app.EnemyDef.LEGENDARY_ID", this.enum.legendary)
    data_util.get_enum("app.EnemyDef.ROLE_ID", this.enum.em_role)
    data_util.get_enum("app.EnvironmentType.ENVIRONMENT", this.enum.environ)
    data_util.get_enum("app.QuestDef.RANK", this.enum.quest_rank)
    data_util.get_enum("app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE", this.enum.ex_gimmick)
    data_util.get_enum("this.GimmickDef.BASE_STATE", this.enum.gimmick_state)
    data_util.get_enum("app.cExFieldEvent_Battlefield.BATTLEFIELD_STATE", this.enum.battlefield_state)
    data_util.get_enum("app.QuestCheckUtil.INCORRECT_STATUS", this.enum.incorrect_status)

    local dataman = sdk.get_managed_singleton("app.VariousDataManager")
    ---@cast dataman app.VariousDataManager
    local dataman_settting = dataman:get_Setting()
    this.ex_field_param = dataman_settting:get_ExFieldParam()

    ---@diagnostic disable-next-line: missing-fields
    this.event = {
        by_type = {
            monster = monster_data.get_data(this.ex_field_param),
            animal = animal_data.get_data(this.ex_field_param),
            gimmick = gimmick_data.get_data(this.ex_field_param),
        },
    }
    this.event.by_stage =
        events_by_stage_ctor(this.event.by_type.monster, this.event.by_type.gimmick, this.event.by_type.animal)
    this.item = item_by_ctor(item_data.get_data())
end

return this
