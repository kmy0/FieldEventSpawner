---@class (exact) MonsterParamModifier
---@field legendary boolean
---@field none boolean
---@field legendary_king boolean

---@class (exact) MonsterSizeData
---@field min integer
---@field max integer

---@class (exact) MonsterCrown
---@field small integer
---@field large integer
---@field king integer

---@class (exact) MonsterSize
---@field legendary table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>
---@field none table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>
---@field legendary_king table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>

---@class (exact) MonsterDifficulty
---@field legendary table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
---@field none table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
---@field legendary_king table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?

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
---@field pop_many2 MonsterParamModifier?

---@class (exact) MonsterMapData : MapData
---@field param MonsterParam
---@field param_by_env table<app.EnvironmentType.ENVIRONMENT, MonsterParam>
---@field area_by_param table<string, integer[]>
---@field area_by_env_by_param table<app.EnvironmentType.ENVIRONMENT, table<string, integer[]>>
---@field difficulty_by_param table<string, MonsterDifficulty>
---@field difficulty_by_env_by_param table<app.EnvironmentType.ENVIRONMENT, table<string, MonsterDifficulty>>
---@field env_by_param table<string, app.EnvironmentType.ENVIRONMENT[]>
---@field size_by_param_mod MonsterSize

---@class (exact) MonsterData : AreaEventData
---@field id app.EnemyDef.ID
---@field map table<app.FieldDef.STAGE, MonsterMapData>
---@field crown MonsterCrown
---@field monster_map_data_ctor fun(stage: app.FieldDef.STAGE, is_battlefield: boolean?): MonsterMapData

local data_ace = require("FieldEventSpawner.data.ace.ace")
local data_event = require("FieldEventSpawner.data.ace.event.event")
local data_gui = require("FieldEventSpawner.data.gui")
local game_data = require("FieldEventSpawner.util.game.data")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_game = require("FieldEventSpawner.util.game.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {}
---@class MonsterData
local MonsterData = {}
---@diagnostic disable-next-line: inject-field
MonsterData.__index = MonsterData
setmetatable(MonsterData, { __index = data_event })

local rl = game_data.reverse_lookup

---@param id app.EnemyDef.ID
---@param name_english string
---@param name_local string
---@param type app.EX_FIELD_EVENT_TYPE
---@param crown MonsterCrown
---@return MonsterData
function MonsterData:new(id, name_english, name_local, type, crown)
    local o = data_event.new(self, name_english, name_local, type)
    setmetatable(o, self)
    ---@cast o MonsterData
    o.id = id
    o.crown = crown
    return o
end

---@param stage app.FieldDef.STAGE
---@return MonsterMapData
function MonsterData.monster_map_data_ctor(stage)
    local ret = data_event.map_data_ctor(stage)
    ---@cast ret MonsterMapData
    ret.param = {}
    ret.param_by_env = {}
    ret.difficulty_by_param = {}
    ret.difficulty_by_env_by_param = {}
    ret.area_by_param = {}
    ret.area_by_env_by_param = {}
    ret.env_by_param = {}
    ---@diagnostic disable-next-line: missing-fields
    ret.size_by_param_mod = {}
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
        return util_table.get_nested_value(map.area_by_env_by_param, { environ, em_param })
    end
    return map.area_by_param[em_param]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@param em_param string
---@param em_param_mod string
---@return table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
function MonsterData:get_difficulty_table(stage, environ, em_param, em_param_mod)
    local map = self.map[stage]
    if not map then
        return
    end

    if environ then
        return util_table.get_nested_value(
            map.difficulty_by_env_by_param,
            { environ, em_param, em_param_mod }
        )
    end

    local t = map.difficulty_by_param[em_param] or {}
    return t[em_param_mod]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@param em_param string
---@param em_param_mod string
---@param em_difficulty integer
---@return table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>?
function MonsterData:get_difficulty_rank_table(
    stage,
    environ,
    em_param,
    em_param_mod,
    em_difficulty
)
    local difficulty_table = self:get_difficulty_table(stage, environ, em_param, em_param_mod)

    if not difficulty_table then
        return
    end

    return difficulty_table[em_difficulty]
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
    local field_layout = data_ace.ex_field_param:getFieldLayout(stage)
    if not field_layout then
        return
    end
    local pop_param_by_hr = field_layout:getEmPopParamByHR(999, pop_em_type)
    local field_name = data_ace.map.pop_em_to_param_field[data_ace.enum.pop_em_fixed[pop_em_type]]
    local type_param_array = pop_param_by_hr:get_field(field_name)
    ---@cast type_param_array  System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base>
    return field_layout:getPopParamByEmID(em_id, type_param_array)
end

---@param em_id app.EnemyDef.ID
---@param field_ids app.FieldDef.STAGE[]
---@return table<app.FieldDef.STAGE, MonsterMapData>
local function get_battlefield_data(em_id, field_ids)
    local ret = {}
    local pop_em_type = rl(data_ace.enum.pop_em_fixed, "BATTLEFIELD")
    for stage, _ in pairs(field_ids) do
        local pop_param = get_pop_param(em_id, stage, pop_em_type)
        if not pop_param then
            goto continue
        end
        ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
        local belonging_array = pop_param._PopBelongingStageParam
        ret[stage] = MonsterData.monster_map_data_ctor(stage)

        if belonging_array:get_Count() > 0 then
            local belonging_enum = util_game.get_array_enum(belonging_array)
            while belonging_enum:MoveNext() do
                local belonging = belonging_enum:get_Current()
                ---@cast belonging app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam
                local area = belonging:get_AreaNo()
                for environ_type, _ in pairs(data_ace.enum.environ) do
                    util_table.insert_nested_value(
                        ret[stage],
                        { "area_by_env", environ_type },
                        area
                    )
                end
                table.insert(ret[stage].area, area)
            end
        else
            local area = -1
            for environ_type, _ in pairs(data_ace.enum.environ) do
                util_table.insert_nested_value(ret[stage], { "area_by_env", environ_type }, area)
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
    local enum = util_game.get_array_enum(area_move_info_array)
    ---@type table<app.FieldDef.STAGE, MonsterMapData>
    local ret = {}

    while enum:MoveNext() do
        local area_move_info = enum:get_Current()
        ---@cast area_move_info app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo
        local stage = area_move_info:get_Stage()
        local param_area_info_by_env = area_move_info._AreaInfoByEnv
        local by_env_enum = util_game.get_array_enum(param_area_info_by_env._EnvParams)
        local map_data = MonsterData.monster_map_data_ctor(stage)

        while by_env_enum:MoveNext() do
            local area_info_by_env = by_env_enum:get_Current()
            ---@cast area_info_by_env app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv
            local environ = area_info_by_env:get_EnvType()
            local area_array = area_info_by_env:get_AreaNoArray()

            if area_array:get_Count() == 0 then
                goto continue
            end

            local area_enum = util_game.get_array_enum(area_array)
            ---@type integer[]
            local areas = {}
            while area_enum:MoveNext() do
                table.insert(areas, area_enum:get_Current())
            end

            table.sort(areas)
            map_data.area_by_env[environ] = areas
            map_data.area = util_table.merge(map_data.area, areas)
            ::continue::
        end

        if not util_table.empty(map_data.area) then
            map_data.area = util_table.unique(map_data.area)
            table.sort(map_data.area)
            ret[stage] = map_data
        end
    end
    return ret
end

---@param difficulty_params System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@return table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
local function get_difficulty(difficulty_params, legendary_id)
    local enemyman = s.get("app.EnemyManager")
    local em_setting = enemyman:get_Setting()
    local diff2 = em_setting:get_Difficulty2()

    ---@type table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>
    local ret = {}
    for i = 0, difficulty_params:get_Count() - 1 do
        local weight = difficulty_params:get_Item(i)
        ---@cast weight app.user_data.ExFieldParam_LayoutData.cDifficultyWeight
        local guid = weight:call("getDifficultyRankID(app.EnemyDef.LEGENDARY_ID)", legendary_id)
        local rate = diff2:getDifficultyRate(guid)
        util_table.insert_nested_value(ret, {
            rate:get_RewardGrade(),
            game_data.fixed_to_enum("app.QuestDef.EM_REWARD_RANK", rate:get_RewardRank()),
        }, guid)
    end

    for grade, ranks in pairs(ret) do
        for rank, guids in pairs(ranks) do
            ranks[rank] = util_table.unique(guids, function(o)
                return util_game.format_guid(o)
            end)
        end
    end

    return ret
end

---@param pop_param_by_env app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base?
---@param environ app.EnvironmentType.ENVIRONMENT
---@return boolean
local function environment_check(pop_param_by_env, environ)
    if not pop_param_by_env then
        return true
    end

    local param_by_env_base = pop_param_by_env:getParamByEnv(environ)
    if not param_by_env_base then
        return false
    end

    return param_by_env_base:get_RandomWeight() > 0
end

---@param md MonsterMapData
---@param key string
---@param em_param MonsterParamModifier
---@param pop_param_by_env app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base?
---@param diff_array System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
local function add_params(md, key, em_param, pop_param_by_env, diff_array)
    local legendary = {
        none = rl(data_ace.enum.legendary, "NONE"),
        legendary = rl(data_ace.enum.legendary, "NORMAL"),
        legendary_king = rl(data_ace.enum.legendary, "KING"),
    }

    local em_difficulty = {}
    for param_key, bool in pairs(em_param) do
        if bool then
            em_difficulty[param_key] = get_difficulty(diff_array, legendary[param_key])
        end
    end

    for env, areas in pairs(md.area_by_env) do
        if not environment_check(pop_param_by_env, env) then
            goto continue
        end

        util_table.set_nested_value(md.param_by_env, { env, key }, em_param)
        util_table.set_nested_value(md.area_by_env_by_param, { env, key }, areas)
        util_table.set_nested_value(md.difficulty_by_env_by_param, { env, key }, em_difficulty)
        md.env_by_param = util_table.insert_nested_value(md.env_by_param, { key }, env)
        md.env_by_param[key] = util_table.unique(md.env_by_param[key])
        md.area_by_param[key] =
            util_table.unique(util_table.merge_t(md.area_by_param[key] or {}, areas))
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

---@param em_id app.EnemyDef.ID
---@param map_data table<app.FieldDef.STAGE, MonsterMapData>
local function get_param_data(em_id, map_data)
    for stage, md in pairs(map_data) do
        for param_key, pop_em in pairs(data_gui.map.em_param_to_pop_em) do
            local pop_em_type = rl(data_ace.enum.pop_em_fixed, pop_em)
            local pop_param = get_pop_param(em_id, stage, pop_em_type)

            if not pop_param then
                goto continue
            end

            local leg_prob = pop_param:get_LegendaryProbability()
            local em_param = {
                none = leg_prob < 100,
                legendary = leg_prob > 0,
                legendary_king = false,
            }
            local diff_array = pop_param._DifficultyParams

            if param_key == "legendary" then
                em_param.none = false
                em_param.legendary = true
            elseif param_key == "battlefield_repel" then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
                diff_array = pop_param._DifficultyParams_PopBelonging
            elseif param_key == "boss" then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm
                leg_prob = pop_param:get_BossLegendaryProbability()
                em_param.none = leg_prob < 100
                em_param.legendary = leg_prob > 0
                diff_array = pop_param._BossDifficultyParams
            end

            add_params(md, param_key, em_param, pop_param._ParamsByEnv, diff_array)
            ::continue::
        end

        -- as of TU2, Lagi only
        if md.param.normal or md.param.swarm then
            md.param.pop_many2 = nil
        end
    end
end

---@param md table<app.FieldDef.STAGE, MonsterMapData>
---@param battlefield_data table<app.FieldDef.STAGE, MonsterMapData>
---@return table<app.FieldDef.STAGE, MonsterMapData>
local function merge_map_data(md, battlefield_data)
    for stage, mmd in pairs(battlefield_data) do
        local map_data = md[stage]
        for _, key in pairs({ "param", "area_by_param", "env_by_param", " difficulty_by_param" }) do
            map_data[key] = mmd[key].battlefield_slay
            map_data[key] = mmd[key].battlefield_repel
        end

        for env, param in pairs(mmd.param_by_env) do
            map_data.param_by_env[env].battlefield_slay = param.battlefield_slay
            map_data.param_by_env[env].battlefield_repel = param.battlefield_repel
        end

        for env, param in pairs(mmd.area_by_env_by_param) do
            map_data.area_by_env_by_param[env].battlefield_slay = param.battlefield_slay
            map_data.area_by_env_by_param[env].battlefield_repel = param.battlefield_repel
        end

        for env, param in pairs(mmd.difficulty_by_env_by_param) do
            map_data.difficulty_by_env_by_param[env].battlefield_slay = param.battlefield_slay
            map_data.difficulty_by_env_by_param[env].battlefield_repel = param.battlefield_repel
        end
    end

    return md
end

---@param map_data table<app.FieldDef.STAGE, MonsterMapData>
---@return table<app.FieldDef.STAGE, MonsterMapData>?
local function filter_map_data(map_data)
    for stage, md in pairs(map_data) do
        if util_table.all(md.param, function(o)
            return not o
        end) then
            map_data[stage] = nil
        end
    end

    if not util_table.empty(map_data) then
        return map_data
    end
end

---@return table<app.EnemyDef.ID, {crown: MonsterCrown, sizes: MonsterSize}>
local function get_size_data()
    local legendary = {
        [rl(data_ace.enum.legendary, "NONE")] = "none",
        [rl(data_ace.enum.legendary, "NORMAL")] = "legendary",
        [rl(data_ace.enum.legendary, "KING")] = "legendary_king",
    }
    ---@type table<app.EnemyDef.ID, {crown: MonsterCrown, sizes: MonsterSize}>
    local ret = {}
    local enemyman = s.get("app.EnemyManager")
    local em_setting = enemyman:get_Setting()
    local em_rand_size = em_setting:get_RandomSize()
    local em_size = em_setting:get_Size()
    local em_tbl_data = em_rand_size._EnemyRandomSizeTblArray

    util_game.do_something(em_tbl_data, function(_, _, tbl_data)
        local em_size_tbl = tbl_data._SizeTable
        local param = legendary[tbl_data:get_LegendaryId()]
        local em_id = game_data.fixed_to_enum("app.EnemyDef.ID", tbl_data:get_EmIdFixed())

        if not ret[em_id] then
            local size_data = em_size:getSizeData(em_id)
            ret[em_id] = {
                sizes = {
                    none = {},
                    legendary = {},
                    legendary_king = {},
                },
                crown = {
                    small = size_data:get_CrownSize_Small(),
                    large = size_data:get_CrownSize_Big(),
                    king = size_data:get_CrownSize_King(),
                },
            }
        end

        util_game.do_something(em_size_tbl, function(_, _, size_tbl)
            ---@type {[integer]: boolean}
            local sizes = {}
            for i = 1, 5 do
                local rand_size_tbl_guid = size_tbl:call("getSizeTableId(System.Int32)", i)
                local guid = rand_size_tbl_guid.Value
                local rand_size_tbl = em_rand_size:getRandomSizeTblData(guid)
                local prob_data_tbl = rand_size_tbl._ProbDataTbl

                util_game.do_something(prob_data_tbl, function(_, _, prob_tbl)
                    if prob_tbl:get_Prob() > 0 then
                        sizes[prob_tbl:get_Scale()] = true
                    end
                end)
            end

            local lower_bound =
                game_data.fixed_to_enum("app.QuestDef.EM_REWARD_RANK", size_tbl:get_RewardRank_L())
            local upper_bound =
                game_data.fixed_to_enum("app.QuestDef.EM_REWARD_RANK", size_tbl:get_RewardRank_U())
            local sizes_arr = util_table.keys(sizes)
            local size_max = math.max(table.unpack(sizes_arr))
            local size_min = math.min(table.unpack(sizes_arr))

            for i = lower_bound, upper_bound do
                util_table.set_nested_value(
                    ret[em_id],
                    { "sizes", param, i },
                    { min = size_min, max = size_max }
                )
            end
        end)
    end)

    return ret
end

---@param ex_field_param app.user_data.ExFieldParam
---@return MonsterData[]
function this.get_data(ex_field_param)
    local em_ids = {}
    local field_ids = {}
    local lang = game_lang.get_language()
    local size_data = get_size_data()

    game_data.get_enum("app.EnemyDef.ID", em_ids)
    game_data.get_enum("app.FieldDef.STAGE", field_ids)

    local ex_em_global_param = ex_field_param:get_ExEnemyGlobalParam()
    local type = rl(data_ace.enum.ex_event, "POP_EM")
    ---@type table<app.EnemyDef.ID, MonsterData>
    local cache = {}

    for em_id, _ in pairs(em_ids) do
        if not m.isEmValid(em_id) or not m.isBossID(em_id) or not size_data[em_id] then
            goto continue
        end

        local battlefield_data = get_battlefield_data(em_id, field_ids)
        local map_data = {}
        local area_move_info_by_em = ex_em_global_param:getAreaMoveInfo(em_id)
        if area_move_info_by_em then
            map_data = get_stage_data(area_move_info_by_em)
        end

        local name_guid = m.getEnemyNameGuid(em_id)
        local monster_data = MonsterData:new(
            em_id,
            game_lang.get_message_local(name_guid, 1),
            game_lang.get_message_local(name_guid, lang, true),
            type,
            size_data[em_id].crown
        )

        local map_data_param, battlefield_data_param, all_data_param
        if not util_table.empty(map_data) then
            get_param_data(em_id, map_data)
            map_data_param = filter_map_data(map_data)
        end

        if not util_table.empty(battlefield_data) then
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

            for _, md in pairs(monster_data.map) do
                md.size_by_param_mod = size_data[em_id].sizes
            end
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
