local data_animal = require("FieldEventSpawner.data.ace.event.animal")
local data_gimmick = require("FieldEventSpawner.data.ace.event.gimmick")
local data_gui = require("FieldEventSpawner.data.gui")
local data_item = require("FieldEventSpawner.data.ace.item")
local data_monster = require("FieldEventSpawner.data.ace.event.monster")
local game_data = require("FieldEventSpawner.util.game.data")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_game = require("FieldEventSpawner.util.game.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = require("FieldEventSpawner.data.ace.ace")

local rl = game_data.reverse_lookup

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
                local event_type =
                    rl(data_gui.map.event_type_to_ex_event, this.enum.ex_event[event.type])
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

---@param ex_field_param app.user_data.ExFieldParam
---@return table<string, boolean>
local function get_spoffer_pairings(ex_field_param)
    local ret = {}
    local spoffer_by_rank = ex_field_param._SpOfferSecondTargetWeightsByFirstEmRank

    util_game.do_something(spoffer_by_rank, function(_, _, value)
        local first_rank = value:get_FirstEmRank()
        local targets = value:get_SecondTargetWeights()

        util_game.do_something(targets, function(_, _, value2)
            local second_rank = value2:get_EmRank()
            local key = util_table.sort({ first_rank, second_rank })
            ret[string.format("%s,%s", table.unpack(key))] = value2:get_Weight() > 0
        end)
    end)

    return ret
end

---@return string
local function get_exclusive_monster_names()
    ---@type string[]
    local res = {}
    for _, m in pairs(this.event.by_type.monster) do
        if m.exclusive then
            table.insert(res, m.name_local)
        end
    end

    return table.concat(util_table.sort(res), ", ")
end

---@return boolean
function this.init()
    if not s.get("app.VariousDataManager") or not s.get("app.EnemyManager") then
        return false
    end

    game_data.get_enum("app.EX_FIELD_EVENT_TYPE", this.enum.ex_event)
    game_data.get_enum("app.ExDef.POP_EM_TYPE_Fixed", this.enum.pop_em_fixed)
    game_data.get_enum("app.EnemyDef.LEGENDARY_ID", this.enum.legendary)
    game_data.get_enum("app.EnemyDef.ROLE_ID", this.enum.em_role)
    game_data.get_enum("app.EnvironmentType.ENVIRONMENT", this.enum.environ)
    game_data.get_enum("app.QuestDef.RANK", this.enum.quest_rank)
    game_data.get_enum("app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE", this.enum.ex_gimmick)
    game_data.get_enum("ace.GimmickDef.BASE_STATE", this.enum.gimmick_state)
    game_data.get_enum(
        "app.cExFieldEvent_Battlefield.BATTLEFIELD_STATE",
        this.enum.battlefield_state
    )
    game_data.get_enum("app.QuestCheckUtil.INCORRECT_STATUS", this.enum.incorrect_status)

    if
        util_table.any(
            this.enum --[[@as table<string, table<integer, string>>]],
            function(key, value)
                return util_table.empty(value)
            end
        )
    then
        return false
    end

    local dataman = s.get("app.VariousDataManager")
    ---@cast dataman app.VariousDataManager
    local dataman_settting = dataman:get_Setting()
    this.ex_field_param = dataman_settting:get_ExFieldParam()

    ---@diagnostic disable-next-line: missing-fields
    this.event = {
        by_type = {
            monster = data_monster.get_data(this.ex_field_param),
            animal = data_animal.get_data(this.ex_field_param),
            gimmick = data_gimmick.get_data(this.ex_field_param),
        },
    }
    this.event.by_stage = events_by_stage_ctor(
        this.event.by_type.monster,
        this.event.by_type.gimmick,
        this.event.by_type.animal
    )
    this.item = item_by_ctor(data_item.get_data())
    this.map.spoffer_pairings = get_spoffer_pairings(this.ex_field_param)
    this.map.exclusive_monsters = get_exclusive_monster_names()
    this.initialized = true
    return true
end

return this
