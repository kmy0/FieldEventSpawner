---@class (exact) MonsterParamModifier
---@field legendary boolean
---@field none boolean
---@field legendary_king boolean

---@class (exact) MonsterDifficulty
---@field legendary table<integer, System.Guid[]>?
---@field none table<integer, System.Guid[]>?
---@field legendary_king table<integer, System.Guid[]>?

---@class (exact) MonsterParam
---@field frenzy MonsterParamModifier?
---@field legendary MonsterParamModifier?
---@field swarm MonsterParamModifier?
---@field nushi MonsterParamModifier?
---@field cocoon MonsterParamModifier?
---@field normal MonsterParamModifier?
---@field boss MonsterParamModifier?
---@field battlefield_repel MonsterParamModifier?
---@field battlefield_slay MonsterParamModifier?

---@class (exact) MonsterMapData : MapData
---@field param MonsterParam
---@field param_by_env table<app.EnvironmentType.ENVIRONMENT, MonsterParam>
---@field area_by_param table<string, integer[]>
---@field area_by_env_by_param table<app.EnvironmentType.ENVIRONMENT, table<string, integer[]>>
---@field difficulty_by_param table<string, MonsterDifficulty>
---@field difficulty_by_env_by_param table<app.EnvironmentType.ENVIRONMENT, table<string, MonsterDifficulty>>
---@field env_by_param table<string, app.EnvironmentType.ENVIRONMENT[]>

---@class (exact) MonsterData : AreaEventData
---@field id app.EnemyDef.ID
---@field map table<app.FieldDef.STAGE, MonsterMapData>
---@field monster_map_data_ctor fun(stage: app.FieldDef.STAGE, is_battlefield: boolean?): MonsterMapData

local ace_data = require("FieldEventSpawner.data.ace.ace")
local data_util = require("FieldEventSpawner.data.util")
local event = require("FieldEventSpawner.data.ace.event.event")
local gui_data = require("FieldEventSpawner.data.gui")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local this = {}
---@class MonsterData
local MonsterData = {}
MonsterData.__index = MonsterData
setmetatable(MonsterData, { __index = event })

local rl = data_util.reverse_lookup

---@param id app.EnemyDef.ID
---@param name_english string
---@param name_local string
---@param type app.EX_FIELD_EVENT_TYPE
---@return MonsterData
function MonsterData:new(id, name_english, name_local, type)
    local o = event.new(self, name_english, name_local, type)
    setmetatable(o, self)
    ---@cast o MonsterData
    o.id = id
    return o
end

---@param stage app.FieldDef.STAGE
---@return MonsterMapData
function MonsterData.monster_map_data_ctor(stage)
    local ret = event.map_data_ctor(stage)
    ---@cast ret MonsterMapData
    ret.param = {}
    ret.param_by_env = {}
    ret.difficulty_by_param = {}
    ret.difficulty_by_env_by_param = {}
    ret.area_by_param = {}
    ret.area_by_env_by_param = {}
    ret.env_by_param = {}
    return ret
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@param em_param string
---@return integer[]?
function MonsterData:get_area_array(stage, environ, em_param)
    local map = self.map[stage]
    if not map then
        return
    end

    if environ then
        return table_util.get_nested_value(map.area_by_env_by_param, { environ, em_param })
    end
    return map.area_by_param[em_param]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@param em_param string
---@param em_param_mod string
---@return table<integer, System.Guid>?
function MonsterData:get_difficulty_table(stage, environ, em_param, em_param_mod)
    local map = self.map[stage]
    if not map then
        return
    end

    if environ then
        return table_util.get_nested_value(map.difficulty_by_env_by_param, { environ, em_param, em_param_mod })
    end

    local t = map.difficulty_by_param[em_param] or {}
    return t[em_param_mod]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@return MonsterParam?
function MonsterData:get_param_struct(stage, environ)
    local map = self.map[stage]
    if not map then
        return
    end

    if environ then
        return map.param_by_env[environ]
    end
    return map.param
end

---@param em_id app.EnemyDef.ID
---@param stage app.FieldDef.STAGE
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@return app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base?
local function get_pop_param(em_id, stage, pop_em_type)
    local field_layout = ace_data.ex_field_param:getFieldLayout(stage)
    if not field_layout then
        return
    end
    local pop_param_by_hr = field_layout:getEmPopParamByHR(999, pop_em_type)
    local field_name = ace_data.map.pop_em_to_param_field[ace_data.enum.pop_em_fixed[pop_em_type]]
    local type_param_array = pop_param_by_hr:get_field(field_name)
    ---@cast type_param_array  System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base>
    return field_layout:getPopParamByEmID(em_id, type_param_array)
end

---@param em_id app.EnemyDef.ID
---@param field_ids app.FieldDef.STAGE[]
---@return table<app.FieldDef.STAGE, MonsterMapData>
local function get_battlefield_data(em_id, field_ids)
    local ret = {}
    local pop_em_type = rl(ace_data.enum.pop_em_fixed, "BATTLEFIELD")
    for stage, _ in pairs(field_ids) do
        local pop_param = get_pop_param(em_id, stage, pop_em_type)
        if not pop_param then
            goto continue
        end
        ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
        local belonging_array = pop_param._PopBelongingStageParam
        ret[stage] = MonsterData.monster_map_data_ctor(stage)

        if belonging_array:get_Count() > 0 then
            local belonging_enum = util.get_array_enum(belonging_array)
            while belonging_enum:MoveNext() do
                local belonging = belonging_enum:get_Current()
                ---@cast belonging app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam
                local area = belonging:get_AreaNo()
                for environ_type, _ in pairs(ace_data.enum.environ) do
                    table_util.insert_nested_value(ret[stage], { "area_by_env", environ_type }, area)
                end
                table.insert(ret[stage].area, area)
            end
        else
            local area = -1
            for environ_type, _ in pairs(ace_data.enum.environ) do
                table_util.insert_nested_value(ret[stage], { "area_by_env", environ_type }, area)
            end
            table.insert(ret[stage].area, area)
        end
        ::continue::
    end
    return ret
end

---@param area_move_info_by_em app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfoByEm
---@return table<app.FieldDef.STAGE, MonsterMapData>
local function get_stage_data(area_move_info_by_em)
    local area_move_info_array = area_move_info_by_em:get_AllAreaMoveInfoArray()
    local enum = util.get_array_enum(area_move_info_array)
    ---@type table<app.FieldDef.STAGE, MonsterMapData>
    local ret = {}

    while enum:MoveNext() do
        local area_move_info = enum:get_Current()
        ---@cast area_move_info app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo
        local stage = area_move_info:get_Stage()
        local param_area_info_by_env = area_move_info._AreaInfoByEnv
        local by_env_enum = util.get_array_enum(param_area_info_by_env._EnvParams)
        local map_data = MonsterData.monster_map_data_ctor(stage)

        while by_env_enum:MoveNext() do
            local area_info_by_env = by_env_enum:get_Current()
            ---@cast area_info_by_env app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv
            local environ = area_info_by_env:get_EnvType()
            local area_array = area_info_by_env:get_AreaNoArray()

            if area_array:get_Count() == 0 then
                goto continue
            end

            local area_enum = util.get_array_enum(area_array)
            ---@type integer[]
            local areas = {}
            while area_enum:MoveNext() do
                table.insert(areas, area_enum:get_Current())
            end

            table.sort(areas)
            map_data.area_by_env[environ] = areas
            map_data.area = table_util.table_merge(map_data.area, areas)
            ::continue::
        end

        if not table_util.empty(map_data.area) then
            map_data.area = table_util.set(map_data.area)
            table.sort(map_data.area)
            ret[stage] = map_data
        end
    end
    return ret
end

---@param em_id app.EnemyDef.ID
---@param map_data table<app.FieldDef.STAGE, MonsterMapData>
local function get_param_data(em_id, map_data)
    ---@param md MonsterMapData
    ---@param key string
    ---@param em_param MonsterParamModifier
    ---@param em_difficulty MonsterDifficulty
    ---@param env_check (fun(env: app.EnvironmentType.ENVIRONMENT): boolean)?
    local function iter(md, key, em_param, em_difficulty, env_check)
        for env, areas in pairs(md.area_by_env) do
            if env_check and not env_check(env) then
                goto continue
            end

            table_util.set_nested_value(md.param_by_env, { env, key }, em_param)
            table_util.set_nested_value(md.area_by_env_by_param, { env, key }, areas)
            table_util.set_nested_value(md.difficulty_by_env_by_param, { env, key }, em_difficulty)
            md.env_by_param = table_util.insert_nested_value(md.env_by_param, { key }, env)
            md.env_by_param[key] = table_util.set(md.env_by_param[key])
            md.area_by_param[key] = table_util.set(table_util.merge_nested_array(md.area_by_param, { key }, areas))
            md.difficulty_by_param[key] = em_difficulty

            if md.param[key] then
                md.param[key].none = md.param[key].none or em_param.none
                md.param[key].legendary = md.param[key].legendary or em_param.legendary
                md.param[key].legendary_king = md.param[key].legendary_king or em_param.legendary_king
            else
                md.param[key] = em_param
            end
            ::continue::
        end
    end

    local enemyman = sdk.get_managed_singleton("app.EnemyManager")
    ---@cast enemyman app.EnemyManager
    local em_setting = enemyman:get_Setting()
    local diff2 = em_setting:get_Difficulty2()

    ---@param difficulty_params System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
    ---@param legendary_id app.EnemyDef.LEGENDARY_ID
    ---@param bool boolean
    ---@return table<integer, System.Guid[]>?
    local function get_difficulty(difficulty_params, legendary_id, bool)
        if not bool then
            return
        end

        ---@type table<integer, System.Guid[]>
        local ret = {}
        for i = 0, difficulty_params:get_Count() - 1 do
            local weight = difficulty_params:get_Item(i)
            ---@cast weight app.user_data.ExFieldParam_LayoutData.cDifficultyWeight
            local guid = weight:call("getDifficultyRankID(app.EnemyDef.LEGENDARY_ID)", legendary_id)
            local rate = diff2:getDifficultyRate(guid)
            table_util.insert_nested_value(ret, { rate:get_RewardGrade() }, guid)
        end
        return ret
    end

    local legendary = {
        none = rl(ace_data.enum.legendary, "NONE"),
        legendary = rl(ace_data.enum.legendary, "NORMAL"),
        legendary_king = rl(ace_data.enum.legendary, "KING"),
    }
    for stage, md in pairs(map_data) do
        for param_key, pop_em in pairs(gui_data.map.em_param_to_pop_em) do
            local pop_em_type = rl(ace_data.enum.pop_em_fixed, pop_em)
            local pop_param = get_pop_param(em_id, stage, pop_em_type)

            if not pop_param then
                goto continue
            end

            local leg_prob = pop_param:get_LegendaryProbability()
            local pop_param_by_env = pop_param._ParamsByEnv
            local env_check = pop_param_by_env
                    and function(env)
                        local param_by_env_base = pop_param_by_env:getParamByEnv(env)
                        if not param_by_env_base then
                            return false
                        end
                        return param_by_env_base:get_RandomWeight() > 0
                    end
                or nil

            if param_key == "legendary" then
                iter(md, param_key, {
                    none = false,
                    legendary = true,
                    legendary_king = false,
                }, {
                    legendary = get_difficulty(pop_param._DifficultyParams, legendary.legendary, true),
                }, env_check)
                goto continue
            end

            if param_key == "battlefield_repel" then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
                iter(md, param_key, {
                    none = leg_prob < 100,
                    legendary = leg_prob > 0,
                    legendary_king = false,
                }, {
                    none = get_difficulty(pop_param._DifficultyParams_PopBelonging, legendary.none, leg_prob < 100),
                    legendary = get_difficulty(
                        pop_param._DifficultyParams_PopBelonging,
                        legendary.legendary,
                        leg_prob > 0
                    ),
                }, env_check)
                goto continue
            end

            if param_key == "boss" then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm
                if pop_param:get_IsBossSpawned() then
                    local boss_leg_prob = pop_param:get_BossLegendaryProbability()
                    iter(md, param_key, {
                        none = boss_leg_prob < 100,
                        legendary = boss_leg_prob > 0,
                        legendary_king = false,
                    }, {
                        none = get_difficulty(pop_param._BossDifficultyParams, legendary.none, boss_leg_prob < 100),
                        legendary = get_difficulty(
                            pop_param._BossDifficultyParams,
                            legendary.legendary,
                            boss_leg_prob > 0
                        ),
                    }, env_check)
                end
                goto continue
            end

            iter(md, param_key, {
                none = leg_prob < 100,
                legendary = leg_prob > 0,
                legendary_king = false,
            }, {
                none = get_difficulty(pop_param._DifficultyParams, legendary.none, leg_prob < 100),
                legendary = get_difficulty(pop_param._DifficultyParams, legendary.legendary, leg_prob > 0),
            }, env_check)
            ::continue::
        end
    end
end

---@param map_data MonsterMapData
---@param battlefield_data MonsterMapData
---@return MonsterMapData
local function merge_map_data(map_data, battlefield_data)
    map_data.param.battlefield_slay = battlefield_data.param.battlefield_slay
    map_data.param.battlefield_repel = battlefield_data.param.battlefield_repel
    map_data.area_by_param.battlefield_repel = battlefield_data.area_by_param.battlefield_repel
    map_data.area_by_param.battlefield_slay = battlefield_data.area_by_param.battlefield_slay
    map_data.env_by_param.battlefield_slay = battlefield_data.env_by_param.battlefield_slay
    map_data.env_by_param.battlefield_repel = battlefield_data.env_by_param.battlefield_repel
    map_data.difficulty_by_param.battlefield_slay = battlefield_data.difficulty_by_param.battlefield_slay
    map_data.difficulty_by_param.battlefield_repel = battlefield_data.difficulty_by_param.battlefield_repel

    for env, param in pairs(battlefield_data.param_by_env) do
        map_data.param_by_env[env].battlefield_slay = param.battlefield_slay
        map_data.param_by_env[env].battlefield_repel = param.battlefield_repel
    end

    for env, param in pairs(battlefield_data.area_by_env_by_param) do
        map_data.area_by_env_by_param[env].battlefield_slay = param.battlefield_slay
        map_data.area_by_env_by_param[env].battlefield_repel = param.battlefield_repel
    end

    for env, param in pairs(battlefield_data.difficulty_by_env_by_param) do
        map_data.difficulty_by_env_by_param[env].battlefield_slay = param.battlefield_slay
        map_data.difficulty_by_env_by_param[env].battlefield_repel = param.battlefield_repel
    end

    return map_data
end

---@param map_data MonsterMapData
---@return MonsterMapData?
local function filter_map_data(map_data)
    for stage, md in pairs(map_data) do
        if table_util.all(md.param, function(o)
            return not o
        end) then
            map_data[stage] = nil
        end
    end

    if not table_util.empty(map_data) then
        return map_data
    end
end

---@param ex_field_param app.user_data.ExFieldParam
---@return MonsterData[]
function this.get_data(ex_field_param)
    local em_ids = {}
    local field_ids = {}
    local lang = util.get_language()

    data_util.get_enum("app.EnemyDef.ID", em_ids)
    data_util.get_enum("app.FieldDef.STAGE", field_ids)

    local ex_em_global_param = ex_field_param:get_ExEnemyGlobalParam()
    local type = rl(ace_data.enum.ex_event, "POP_EM")
    ---@type table<app.EnemyDef.ID, MonsterData>
    local cache = {}

    for em_id, _ in pairs(em_ids) do
        if not util.isEmValid:call(nil, em_id) or not util.isBossID:call(nil, em_id) then
            goto continue
        end

        local battlefield_data = get_battlefield_data(em_id, field_ids)
        local map_data = {}
        local area_move_info_by_em = ex_em_global_param:getAreaMoveInfo(em_id)
        if area_move_info_by_em then
            map_data = get_stage_data(area_move_info_by_em)
        end

        local name_guid = util.getEnemyNameGuid:call(nil, em_id)
        local monster_data = MonsterData:new(
            em_id,
            util.get_message_local(name_guid, 1),
            util.get_message_local(name_guid, lang, true),
            type
        )

        local map_data_param, battlefield_data_param, all_data_param
        if not table_util.empty(map_data) then
            get_param_data(em_id, map_data)
            map_data_param = filter_map_data(map_data)
        end

        if not table_util.empty(battlefield_data) then
            get_param_data(em_id, battlefield_data)
            battlefield_data_param = filter_map_data(battlefield_data)
        end

        if map_data_param and battlefield_data_param then
            all_data_param = merge_map_data(map_data_param, battlefield_data_param)
        else
            all_data_param = map_data_param or battlefield_data_param
        end

        if all_data_param then
            monster_data.map = all_data_param
            cache[em_id] = monster_data
        end

        ::continue::
    end

    ---@type MonsterData[]
    local ret = {}
    for _, struct in pairs(cache) do
        table.insert(ret, struct)
    end
    return ret
end

return this
