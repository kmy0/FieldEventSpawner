local config = require("FieldEventSpawner.config.init")
local data_animal = require("FieldEventSpawner.data.ace.event.animal")
local data_gimmick = require("FieldEventSpawner.data.ace.event.gimmick")
local data_item = require("FieldEventSpawner.data.ace.item")
local data_monster = require("FieldEventSpawner.data.ace.event.monster")
local e = require("FieldEventSpawner.util.game.enum")
local event_data_serializer =
    require("FieldEventSpawner.data.ace.event.event_data_serializer"):new()
local game_lang = require("FieldEventSpawner.util.game.lang")
local gui = require("FieldEventSpawner.data.gui")
local m = require("FieldEventSpawner.util.ref.methods")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_game = require("FieldEventSpawner.util.game.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = require("FieldEventSpawner.data.ace.ace")
this.reward = require("FieldEventSpawner.data.ace.reward.init")

---@param ... AreaEventData[]
---@return table<app.FieldDef.STAGE, table<string, table<string, AreaEventData>>>
local function make_events_by_stage(...)
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
                local event_type = util_table.reverse_lookup(
                    gui.map.event_type_to_ex_event,
                    e.get("app.EX_FIELD_EVENT_TYPE")[event.type]
                )
                local t = get_table(map.stage, event_type)
                t[string.format("%s_%s_%s_event_name", stage, event_type, event.id)] = event
            end
        end
    end
    return ret
end

---@param item_array ItemData[]
---@return ItemDataBy
local function make_item_by(item_array)
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
        if m.is_exclusive then
            table.insert(res, m.name_local)
        end
    end

    return table.concat(util_table.sort(res), ", ")
end

---@return table<app.FieldDef.STAGE, string>
local function get_swarm_monster_names()
    ---@type table<app.FieldDef.STAGE, string[]>
    local res = {}
    for _, em in pairs(this.event.by_type.monster) do
        for stage, map_data in pairs(em.map) do
            local param = map_data.param
            if param.swarm or param.boss then
                util_table.insert_nested_value(res, { stage }, em.name_local)
            end
        end
    end

    ---@type table<app.FieldDef.STAGE, string>
    local ret = {}
    for stage, name in pairs(res) do
        ret[stage] = table.concat(util_table.sort(name), ", ")
    end
    return ret
end

---@return boolean
local function is_all_em_all_stage()
    ---@type table<app.FieldDef.STAGE, boolean>
    local stages = {}
    for _, em_data in pairs(this.event.by_type.monster) do
        for stage, _ in pairs(em_data.map) do
            stages[stage] = true
        end
    end

    local gog_fixed = e.to_fixed("app.EnemyDef.ID_Fixed", e.get("app.EnemyDef.ID").EM0078_00_0)
    local enemy_setting = s.get("app.EnemyManager"):get_Setting()
    local stage_resident = enemy_setting:get_StageResident()
    ---@type boolean
    local ret = true
    util_game.do_something(stage_resident._DataList, function(_, _, cData)
        if not ret then
            return false
        end

        local stage = e.to_enum("app.FieldDef.STAGE", cData:get_Stage())
        if not stages[stage] then
            return
        end

        ret = cData._EmIDList:Contains(gog_fixed)
    end)

    return ret
end

---@return table<app.EnemyDef.ID, app.FieldDef.STAGE[]>, table<app.EnemyDef.ID, app.FieldDef.STAGE[]>
local function get_em_stage()
    local enemy_setting = s.get("app.EnemyManager"):get_Setting()
    local stage_resident = enemy_setting:get_StageResident()

    ---@type table<app.EnemyDef.ID, app.FieldDef.STAGE[]>
    local missing_em_stage = {}
    ---@type table<app.EnemyDef.ID, app.FieldDef.STAGE[]>
    local em_stage = {}
    util_game.do_something(stage_resident._DataList, function(_, _, cData)
        local stage = e.to_enum("app.FieldDef.STAGE", cData:get_Stage())
        if not this.event.by_stage[stage] then
            return
        end

        util_game.do_something(cData._EmIDList, function(_, _, em_fixed)
            local em = e.to_enum("app.EnemyDef.ID", em_fixed)

            util_table.insert_nested_value(em_stage, { em }, stage)
            local em_data = util_table.value(this.event.by_type.monster, function(_, value)
                return value.id == em
            end)

            if not em_data then
                return
            end

            if not em_data.map[stage] then
                util_table.insert_nested_value(missing_em_stage, { em }, stage)
            end
        end)
    end)

    return missing_em_stage, em_stage
end

---@param stage app.FieldDef.STAGE
---@return string
local function get_stage_name(stage)
    local guid = util_ref.value_type("System.Guid")
    m.getStageNameGuid(stage, guid:address())
    return game_lang.get_message_local2(guid)
end

---@return string
local function get_missing_em_stage_string()
    ---@type table<app.FieldDef.STAGE, app.EnemyDef.ID[]>
    local by_stage = {}

    for em, stages in pairs(this.map.missing_em_stage) do
        for _, stage in pairs(stages) do
            util_table.insert_nested_value(by_stage, { stage }, em)
        end
    end

    local stages = util_table.keys(by_stage)
    table.sort(stages)

    ---@type string[]
    local stage_str = {}
    for _, stage in ipairs(stages) do
        local stage_name = get_stage_name(stage)
        local ems = util_table.sort(by_stage[stage])
        ---@type string[]
        local ems_str = {}

        for _, em in ipairs(ems) do
            local guid = m.getEnemyNameGuid(em)
            local em_name = game_lang.get_message_local2(guid)
            table.insert(ems_str, em_name)
        end

        table.insert(
            stage_str,
            string.format(
                "%s: %s",
                stage_name,
                this.map.is_all_em_all_stage and config.lang:tr("misc.text_all_monsters")
                    or table.concat(ems_str, ", ")
            )
        )
    end

    return table.concat(stage_str, "\n")
end

---@return string
local function get_garkveld_em_stage_string()
    local stages = util_table.sort(this.map.em_stage[e.get("app.EnemyDef.ID").EM0160_50_0])
    local stage_str = {}

    for _, stage in ipairs(stages) do
        local stage_name = get_stage_name(stage)
        table.insert(stage_str, stage_name)
    end

    return table.concat(stage_str, ", ")
end

---@diagnostic disable-next-line: unused-local
local function get_enemyappearancestagedata_user_3_map()
    local stages = {}
    local ems = {}
    local ret = {}
    for _, em_data in pairs(this.event.by_type.monster) do
        for stage, _ in pairs(em_data.map) do
            stages[stage] = true
        end
    end

    for _, em_id in e.iter("app.EnemyDef.ID") do
        if m.isEmValid(em_id) and m.isBossID(em_id) then
            table.insert(ems, em_id)
        end
    end

    local enemy_setting = s.get("app.EnemyManager"):get_Setting()
    local stage_resident = enemy_setting:get_StageResident()
    util_game.do_something(stage_resident._DataList, function(_, _, cData)
        local stage = e.to_enum("app.FieldDef.STAGE", cData:get_Stage())
        if not stages[stage] then
            return
        end

        local stage_serial = cData._Stage:get_Value()
        local arr = util_game.system_array_to_lua(cData._EmIDList)
        local stage_ems = util_table.map_table(arr, function(o)
            return e.to_enum("app.EnemyDef.ID", arr[o])
        end, function(_)
            return true
        end)

        for _, em in pairs(ems) do
            if not stage_ems[em] then
                util_table.insert_nested_value(
                    ret,
                    { stage_serial },
                    e.to_fixed("app.EnemyDef.ID_Fixed", em)
                )
            end
        end
    end)

    json.dump_file("FieldEventSpawner/em_appearance.json", ret)
end

function this.load_invalid_difficulties()
    if this.invalid_difficulties_loaded then
        return
    end

    local config_mod = config.current.mod
    local lowest_dif, highest_dif =
        data_monster.get_lower_upper_difficulties(this.event.by_type.monster)
    this.map.replace_em_rank_guid = {
        [e.get("app.EnemyDef.LEGENDARY_ID").NONE] = lowest_dif,
        [e.get("app.EnemyDef.LEGENDARY_ID").NORMAL] = highest_dif,
        [e.get("app.EnemyDef.LEGENDARY_ID").KING] = highest_dif,
    }

    if config_mod.add_guardian_arkveld then
        local guardian_arkveld_id = e.get("app.EnemyDef.ID").EM0160_50_0
        if
            not util_table.value(this.event.by_type.monster, function(_, value)
                return value.id == guardian_arkveld_id
            end)
        then
            local arkveld_id = e.get("app.EnemyDef.ID").EM0160_00_0
            data_monster.spoof_monster(
                this.event.by_type.monster,
                guardian_arkveld_id,
                arkveld_id,
                this.map.em_stage[guardian_arkveld_id]
            )
            this.map.bad_monsters[guardian_arkveld_id] = true
        end
    end

    if config_mod.add_nerscylla_clone then
        local nerscylla_id = e.get("app.EnemyDef.ID").EM0070_00_0
        local nerscylla_data = util_table.value(this.event.by_type.monster, function(_, value)
            return value.id == nerscylla_id
        end) --[[@as MonsterData]]
        data_monster.add_invalid_role_id(
            nerscylla_data,
            { e.get("app.EnemyDef.ROLE_ID").ROLE_COLLAB_01 }
        )
    end

    if config_mod.add_missing_monsters then
        if config_mod.add_invalid_monsters and this.map.is_all_em_all_stage then
            local arkveld_id = e.get("app.EnemyDef.ID").EM0160_00_0
            local gogmazios_id = e.get("app.EnemyDef.ID").EM0078_00_0
            local omega_planetes_id = e.get("app.EnemyDef.ID").EM0166_00_0

            data_monster.spoof_monster(
                this.event.by_type.monster,
                gogmazios_id,
                arkveld_id,
                this.map.em_stage[gogmazios_id]
            )
            data_monster.spoof_monster(
                this.event.by_type.monster,
                omega_planetes_id,
                arkveld_id,
                this.map.em_stage[omega_planetes_id]
            )

            this.map.bad_monsters[gogmazios_id] = true
            this.map.bad_monsters[omega_planetes_id] = true
        end

        if not util_table.empty(this.map.missing_em_stage) then
            ---@type table<app.FieldDef.STAGE, app.EnemyDef.ID[]>
            local to_spoof = {}
            for em, stages in pairs(this.map.missing_em_stage) do
                for _, stage in pairs(stages) do
                    util_table.insert_nested_value(to_spoof, { stage }, em)
                end
            end

            for stage, ems in pairs(to_spoof) do
                data_monster.spoof_map(
                    this.event.by_type.monster,
                    stage,
                    ems,
                    config_mod.add_invalid_monsters and this.map.is_all_em_all_stage
                )
            end
        end
    end

    if config_mod.add_invalid_difficulties then
        s.get("app.MissionManager"):reflectStreamQuestListCache()

        data_monster.add_invalid_difficulties(
            this.event.by_type.monster,
            config_mod.merge_invalid_difficulties
        )
    end

    if config_mod.add_guardian_arkveld or config_mod.add_missing_monsters then
        this.event.by_stage = make_events_by_stage(
            this.event.by_type.monster,
            this.event.by_type.gimmick,
            this.event.by_type.animal
        )
    end

    this.invalid_difficulties_loaded = true
end

---@return boolean
function this.init()
    if not s.get("app.VariousDataManager") or not s.get("app.EnemyManager") then
        return false
    end

    if
        not e.wrap_init(function()
            e.new("app.EX_FIELD_EVENT_TYPE")
            e.new("app.ExDef.POP_EM_TYPE_Fixed")
            e.new("app.EnemyDef.LEGENDARY_ID")
            e.new("app.EnemyDef.ROLE_ID")
            e.new("app.EnvironmentType.ENVIRONMENT")
            e.new("app.QuestDef.RANK")
            e.new("app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE")
            e.new("ace.GimmickDef.BASE_STATE")
            e.new("app.cExFieldEvent_Battlefield.BATTLEFIELD_STATE")
            e.new("app.QuestCheckUtil.INCORRECT_STATUS")
            e.new("app.EnemyDef.ID")
        end)
    then
        return false
    end

    this.map.legendary_to_key = {
        [e.get("app.EnemyDef.LEGENDARY_ID").NONE] = "none",
        [e.get("app.EnemyDef.LEGENDARY_ID").NORMAL] = "legendary",
        [e.get("app.EnemyDef.LEGENDARY_ID").KING] = "legendary_king",
    }

    local dataman = s.get("app.VariousDataManager")
    ---@cast dataman app.VariousDataManager
    local dataman_settting = dataman:get_Setting()
    this.ex_field_param = dataman_settting:get_ExFieldParam()

    local current_thread = tostring(thread.get_hash())
    local dumped_thread = fs.read(config.current_thread_path)

    if current_thread == dumped_thread then
        this.event = event_data_serializer:from_file(config.event_data_path) --[[@as EventDataBy]]
    end

    if not this.event then
        ---@diagnostic disable-next-line: missing-fields
        this.event = {
            by_type = {
                monster = data_monster.get_data(this.ex_field_param),
                animal = data_animal.get_data(this.ex_field_param),
                gimmick = data_gimmick.get_data(this.ex_field_param),
            },
        }
        event_data_serializer:dump_file(config.event_data_path, this.event)
        fs.write(config.current_thread_path, current_thread)
    end

    -- get_enemyappearancestagedata_user_3_map()

    this.event.by_stage = make_events_by_stage(
        this.event.by_type.monster,
        this.event.by_type.gimmick,
        this.event.by_type.animal
    )
    this.map.is_all_em_all_stage = is_all_em_all_stage()
    this.item = make_item_by(data_item.get_data())
    this.map.spoffer_pairings = get_spoffer_pairings(this.ex_field_param)
    this.map.exclusive_monsters = get_exclusive_monster_names()
    this.map.swarm_monsters = get_swarm_monster_names()
    this.map.item_key_to_name_local = util_table.map_table(this.item.by_key, nil, function(o)
        return o.name_local
    end)
    this.map.missing_em_stage, this.map.em_stage = get_em_stage()
    this.map.missing_em_stage_string = get_missing_em_stage_string()
    this.map.garkveld_em_stage_string = get_garkveld_em_stage_string()

    if s.get("app.GameFlowManager"):get_IsPlayableScene() then
        this.load_invalid_difficulties()
    end

    this.initialized = true
    return true
end

return this
