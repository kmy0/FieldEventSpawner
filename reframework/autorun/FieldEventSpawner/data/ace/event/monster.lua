local ace = require("FieldEventSpawner.data.ace.ace")
local cache = require("FieldEventSpawner.util.misc.cache")
local e = require("FieldEventSpawner.util.game.enum")
local game_lang = require("FieldEventSpawner.util.game.lang")
local gui = require("FieldEventSpawner.data.gui")
local monster = require("FieldEventSpawner.data.def.monster")
---@module "FieldEventSpawner.data.helpers"
local data_helpers =
    require("FieldEventSpawner.util.misc.init").lazy_require("FieldEventSpawner.data.helpers")
local helpers = require("FieldEventSpawner.data.ace.event.helpers")
local m = require("FieldEventSpawner.util.ref.methods")
local s = require("FieldEventSpawner.util.ref.singletons")
local types = require("FieldEventSpawner.util.ref.types")
local util_game = require("FieldEventSpawner.util.game.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {}

---@param map_data MonsterMapData
---@param roles app.EnemyDef.ROLE_ID[]
---@param guid_str string
local function mark_invalid_for_roles(map_data, roles, guid_str)
    for _, role in pairs(roles) do
        util_table.set_nested_value(map_data.difficulty_invalid, { role, guid_str }, true)
    end
end

---@param id app.MissionIDList.ID
---@return app.cActiveQuestData?
local function get_active_quest_data(id)
    local missman = s.get("app.MissionManager")
    local quest_data = missman:getQuestData(id)
    if not quest_data then
        return
    end

    local ret = util_ref.ctor("app.cActiveQuestData", true)
    local is_recommended = false
    ret:call(".ctor(app.user_data.QuestData, System.Boolean)", quest_data, is_recommended)

    return ret
end

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param param_mod string
---@param grade integer
---@param rank app.QuestDef.EM_REWARD_RANK
---@param guid System.Guid
---@param role app.EnemyDef.ROLE_ID
---@param envs app.EnvironmentType.ENVIRONMENT[]?
---@return string?
local function add_invalid_difficulty(monster_data, stage, param_mod, grade, rank, guid, role, envs)
    if monster_data:is_difficulty_invalid(guid, stage, role) then
        return
    end

    ---@type string
    local ret
    local map_data = monster_data.map[stage]
    for _, env in pairs(envs or map_data.env_by_param.invalid) do
        ret = monster_data:add_difficulty("invalid", param_mod, stage, env, grade, rank, guid, role)
        mark_invalid_for_roles(map_data, { role }, ret)
    end

    return ret
end

local function param_key_to_role(param_key)
    return e.get("app.EnemyDef.ROLE_ID")[gui.map.em_param_to_role[param_key]]
end

local function merge_all_roles_invalid(monster_data, stage)
    local map_data = monster_data.map[stage]
    for _, md in pairs(monster_data.map) do
        for _, roles in pairs(md.role_by_param) do
            map_data.role_by_param.invalid =
                util_table.array_merge(map_data.role_by_param.invalid or {}, roles)
        end
    end

    map_data.role_by_param.invalid = util_table.unique(map_data.role_by_param.invalid)

    local by_param_mod = map_data.difficulty_by_param.invalid or {}
    for _, _, _, guid in monster_data:iter_difficulties(by_param_mod) do
        local guid_str = util_game.format_guid(guid)
        mark_invalid_for_roles(map_data, map_data.role_by_param.invalid, guid_str)
    end
end

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
local function add_invalid_param(monster_data, stage)
    if monster_data.map[stage].param.invalid then
        return
    end

    local param_preference = {
        "normal",
        "pop_many2",
        "nushi",
        "boss",
        "legendary",
        "frenzy",
        "swarm",
        "cocoon",
        "battlefield_slay",
        "battlefield_repel",
    }
    local param_key = "normal"
    for _, param_pref in ipairs(param_preference) do
        if monster_data.map[stage].param[param_pref] then
            param_key = param_pref
            break
        end
    end

    for env, by_param in pairs(monster_data.map[stage].area_by_env_by_param) do
        local areas = by_param[param_key]
        if areas then
            helpers.add_param_areas(monster_data, "invalid", stage, env, areas)
        end
    end

    merge_all_roles_invalid(monster_data, stage)
end

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
local function make_all_params_invalid(monster_data, stage)
    local map_data = monster_data.map[stage]

    add_invalid_param(monster_data, stage)

    local function clear_except_invalid(t)
        for key, _ in pairs(t) do
            if key ~= "invalid" then
                t[key] = nil
            end
        end
    end

    clear_except_invalid(map_data.area_by_param)
    clear_except_invalid(map_data.param)
    clear_except_invalid(map_data.role_by_param)

    for _, by_param in pairs(map_data.area_by_env_by_param) do
        clear_except_invalid(by_param)
    end

    for _, mon_param in pairs(map_data.param_by_env) do
        clear_except_invalid(mon_param)
    end

    for _, by_param in pairs(map_data.difficulty_by_env_by_param) do
        clear_except_invalid(by_param)
    end

    for param_key, mon_dif in pairs(map_data.difficulty_by_param) do
        local role = param_key_to_role(param_key)

        for param_mod, grade, rank, guid in monster_data:iter_difficulties(mon_dif) do
            add_invalid_difficulty(monster_data, stage, param_mod, grade, rank, guid, role)
        end
    end

    clear_except_invalid(map_data.difficulty_by_param)
end

---@param em_id app.EnemyDef.ID
---@param stage app.FieldDef.STAGE
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@return app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base?
local function get_pop_param(em_id, stage, pop_em_type)
    local field_layout = ace.ex_field_param:getFieldLayout(stage)
    if not field_layout then
        return
    end
    local pop_param_by_hr = field_layout:getEmPopParamByHR(999, pop_em_type)
    local field_name =
        ace.map.pop_em_to_param_field[e.get("app.ExDef.POP_EM_TYPE_Fixed")[pop_em_type]]
    local type_param_array = pop_param_by_hr:get_field(field_name)
    ---@cast type_param_array  System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base>
    return field_layout:getPopParamByEmID(em_id, type_param_array)
end

---@param monster_data MonsterData
local function add_battlefield_data(monster_data)
    local pop_em_type = e.get("app.ExDef.POP_EM_TYPE_Fixed").BATTLEFIELD
    for _, stage in e.iter("app.FieldDef.STAGE") do
        local pop_param = get_pop_param(monster_data.id, stage, pop_em_type)
        if not pop_param then
            goto continue
        end
        ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
        local belonging_array = pop_param._PopBelongingStageParam
        local map_data = monster_data:add_map(stage)

        ---@type integer[]
        local areas
        if belonging_array:get_Count() > 0 then
            local belonging_enum = util_game.get_array_enum(belonging_array)
            areas = util_game.enumerator_to_table(belonging_enum, function(o)
                return o:get_AreaNo()
            end)
        else
            areas = { ace.map.dummy_area }
        end

        ---@type integer[]
        local all_areas = {}
        ---@type table<app.EnvironmentType.ENVIRONMENT, integer[]>
        local area_by_env = {}
        for _, area in ipairs(areas) do
            table.insert(all_areas, area)
            for _, environ_type in e.iter("app.EnvironmentType.ENVIRONMENT") do
                util_table.insert_nested_value(area_by_env, { environ_type }, area)
            end
        end

        helpers.merge_map_areas(map_data, all_areas, area_by_env)
        ::continue::
    end
end

---@param monster_data MonsterData
---@param area_move_info_by_em app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfoByEm
local function add_stage_data(monster_data, area_move_info_by_em)
    local area_move_info_array = area_move_info_by_em:get_AllAreaMoveInfoArray()
    local enum = util_game.get_array_enum(area_move_info_array)

    while enum:MoveNext() do
        local area_move_info = enum:get_Current()
        ---@cast area_move_info app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo
        local stage = area_move_info:get_Stage()
        local param_area_info_by_env = area_move_info._AreaInfoByEnv
        local by_env_enum = util_game.get_array_enum(param_area_info_by_env._EnvParams)
        local map_data = monster_data:add_map(stage)
        ---@type integer[]
        local all_areas = {}
        ---@type table<app.EnvironmentType.ENVIRONMENT, integer[]>
        local area_by_env = {}

        while by_env_enum:MoveNext() do
            local area_info_by_env = by_env_enum:get_Current()
            ---@cast area_info_by_env app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv
            local environ = area_info_by_env:get_EnvType()
            local area_array = area_info_by_env:get_AreaNoArray()

            if area_array:get_Count() == 0 then
                goto continue
            end

            local area_enum = util_game.get_array_enum(area_array)
            local areas = util_game.enumerator_to_table(area_enum)

            area_by_env[environ] = areas
            all_areas = util_table.merge(all_areas, areas)
            ::continue::
        end

        helpers.merge_map_areas(map_data, all_areas, area_by_env)
    end
end

---@param difficulty_params System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@return table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
local function get_difficulty(difficulty_params, legendary_id)
    ---@type table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>
    local ret = {}
    for i = 0, difficulty_params:get_Count() - 1 do
        local weight = difficulty_params:get_Item(i)
        ---@cast weight app.user_data.ExFieldParam_LayoutData.cDifficultyWeight
        local guid = weight:call("getDifficultyRankID(app.EnemyDef.LEGENDARY_ID)", legendary_id)
        local rate = data_helpers.get_difficulty_rate(guid)
        util_table.insert_nested_value(ret, {
            rate:get_RewardGrade(),
            e.to_enum("app.QuestDef.EM_REWARD_RANK", rate:get_RewardRank()),
        }, guid)
    end

    for _, ranks in pairs(ret) do
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

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param param_key string
---@param em_param MonsterParamModifier
---@param pop_param_by_env app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base?
---@param diff_array System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
local function add_params(monster_data, stage, param_key, em_param, pop_param_by_env, diff_array)
    ---@type table<string, table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>>
    local em_difficulty = {}
    for param_mod, bool in pairs(em_param) do
        if bool then
            em_difficulty[param_mod] = get_difficulty(
                diff_array,
                util_table.reverse_lookup(ace.map.legendary_to_key, param_mod)
            )
        end
    end

    local md = monster_data.map[stage]
    local role = param_key_to_role(param_key)
    for env, areas in pairs(md.area_by_env) do
        if not environment_check(pop_param_by_env, env) then
            goto continue
        end

        for param_mod, grade, rank, guid in monster_data:iter_difficulties(em_difficulty) do
            monster_data:add_difficulty(param_key, param_mod, stage, env, grade, rank, guid, role)
        end

        helpers.add_param_areas(monster_data, param_key, stage, env, areas)
        ::continue::
    end
end

---@param monster_data MonsterData
local function add_param_data(monster_data)
    for stage, md in pairs(monster_data.map) do
        for param_key, pop_em in pairs(gui.map.em_param_to_pop_em) do
            if param_key == "invalid" then
                goto continue
            end

            local pop_em_type = e.get("app.ExDef.POP_EM_TYPE_Fixed")[pop_em]
            local pop_param = get_pop_param(monster_data.id, stage, pop_em_type)

            if not pop_param then
                goto continue
            end

            local leg_prob = pop_param:get_LegendaryProbability()
            local em_param = {
                none = leg_prob < 100,
                legendary = leg_prob > 0,
            }
            local diff_array = pop_param._DifficultyParams

            if param_key == "legendary" then
                em_param.none = false
                em_param.legendary = true
            elseif param_key == "battlefield_repel" then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
                if pop_param:get_PopBelongingStageProbability() == 0 then
                    goto continue
                end

                diff_array = pop_param._DifficultyParams_PopBelonging
            elseif param_key == "boss" then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm
                if not pop_param:get_IsBossSpawned() then
                    goto continue
                end

                leg_prob = pop_param:get_BossLegendaryProbability()
                em_param.none = leg_prob < 100
                em_param.legendary = leg_prob > 0
                diff_array = pop_param._BossDifficultyParams
            end

            if param_key == "swarm" or param_key == "alpha" and not md.swarm_pack then
                ---@cast pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm
                local swarm_num = pop_param:get_SwarmNum()
                local max_spoffer = pop_param:get_SpOfferTargetMax()

                md.swarm_pack = {
                    min = pop_param:get_SpawnNumMin(),
                    max = pop_param:get_SpawnNumMax(),
                }
                md.swarm_pack.min_spoffer = math.min(md.swarm_pack.min * swarm_num, max_spoffer)
                md.swarm_pack.max_spoffer = math.min(md.swarm_pack.max * swarm_num, max_spoffer)
            end

            add_params(monster_data, stage, param_key, em_param, pop_param._ParamsByEnv, diff_array)
            ::continue::
        end

        -- as of TU2, Lagi only
        if md.param.normal or md.param.swarm then
            md.param.pop_many2 = nil
        end
    end
end

---@param monster_data MonsterData
---@return boolean
local function filter_map_data(monster_data)
    for stage, md in pairs(monster_data.map) do
        if
            util_table.empty(monster_data.map[stage].area)
            or util_table.all(md.param, function(o)
                return not o
            end)
        then
            monster_data.map[stage] = nil
        end
    end

    if not util_table.empty(monster_data.map) then
        return true
    end

    return false
end

---@return table<app.EnemyDef.ID, {crown: MonsterCrown, sizes: MonsterSize}>
local function get_size_data()
    ---@type table<app.EnemyDef.ID, {crown: MonsterCrown, sizes: MonsterSize}>
    local ret = {}
    local enemyman = s.get("app.EnemyManager")
    local em_setting = enemyman:get_Setting()
    local em_rand_size = em_setting:get_RandomSize()
    local em_size = em_setting:get_Size()
    local em_tbl_data = em_rand_size._EnemyRandomSizeTblArray

    util_game.do_something(em_tbl_data, function(_, _, tbl_data)
        local em_size_tbl = tbl_data._SizeTable
        local legendary_id = tbl_data:get_LegendaryId()
        local param_mod = ace.map.legendary_to_key[legendary_id]
        local em_id_fixed = tbl_data:get_EmIdFixed()
        local em_id = e.to_enum("app.EnemyDef.ID", em_id_fixed)

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
            local lower_bound =
                e.to_enum("app.QuestDef.EM_REWARD_RANK", size_tbl:get_RewardRank_L())
            local upper_bound =
                e.to_enum("app.QuestDef.EM_REWARD_RANK", size_tbl:get_RewardRank_U())

            for i = 1, 5 do
                for reward_rank = lower_bound, upper_bound do
                    local rand_size_tbl = em_rand_size:getRandomSizeTblData_Boss(
                        em_id_fixed,
                        legendary_id,
                        reward_rank,
                        i
                    )
                    local prob_data_tbl = rand_size_tbl._ProbDataTbl

                    util_game.do_something(prob_data_tbl, function(_, _, prob_tbl)
                        if prob_tbl:get_Prob() > 0 then
                            sizes[prob_tbl:get_Scale()] = true
                        end
                    end)
                end
            end

            local sizes_arr = util_table.keys(sizes)
            local size_max = math.max(table.unpack(sizes_arr))
            local size_min = math.min(table.unpack(sizes_arr))

            for reward_rank = lower_bound, upper_bound do
                util_table.set_nested_value(
                    ret[em_id],
                    { "sizes", param_mod, reward_rank },
                    { min = size_min, max = size_max }
                )
            end
        end)
    end)

    for _, d in pairs(ret) do
        for param_mod, sizes in pairs(d.sizes) do
            if util_table.empty(sizes) then
                d.sizes[param_mod] = d.sizes.none
            end
        end
    end

    return ret
end

local function get_option_tag(em_id_name)
    local ret = {}
    local letters, digits = em_id_name:match("^(%a+)(%d+)")
    if not letters then
        return ret
    end

    local tdef_name = string.format(
        "app.%sDef.OPTION_TAGBit",
        letters:sub(1, 1):upper() .. letters:sub(2):lower() .. digits
    )
    local tdef = types.get(tdef_name)
    if not tdef then
        return ret
    end

    return util_table.deep_copy(e.get(tdef_name).enum_to_field)
end

---@param monster_data MonsterData[]
---@return string, string
function this.get_lower_upper_difficulties(monster_data)
    local lower_valid_dif = { grade = math.huge, rank = math.huge, guid_str = "" }
    local upper_valid_dif = { grade = -math.huge, rank = -math.huge, guid_str = "" }

    for _, em in pairs(monster_data) do
        for _, map in pairs(em.map) do
            for _, mon_dif in pairs(map.difficulty_by_param) do
                for _, grade, rank, guid in em:iter_difficulties(mon_dif) do
                    if
                        rank < lower_valid_dif.rank
                        or (rank == lower_valid_dif.rank and grade < lower_valid_dif.grade)
                    then
                        lower_valid_dif.grade = grade
                        lower_valid_dif.rank = rank
                        lower_valid_dif.guid_str = util_game.format_guid(guid)
                    end

                    if

                        rank > upper_valid_dif.rank
                        or (rank == upper_valid_dif.rank and grade > upper_valid_dif.grade)
                    then
                        upper_valid_dif.grade = grade
                        upper_valid_dif.rank = rank
                        upper_valid_dif.guid_str = util_game.format_guid(guid)
                    end
                end
            end
        end
    end

    return lower_valid_dif.guid_str, upper_valid_dif.guid_str
end

---@param monster_data MonsterData[]
---@param merge_rewards boolean
function this.add_invalid_rewards(monster_data, merge_rewards)
    local various_data_manager = s.get("app.VariousDataManager")
    local various_data_manager_setting = various_data_manager:get_Setting()
    local quest_reward_setting = various_data_manager_setting:get_QuestRewardSetting()
    local common_reward_data = various_data_manager_setting:get_CommonQuestRewardData()

    local by_em = util_table.map_array(monster_data, function(o)
        return o.id
    end) --[[@as table<app.EnemyDef.ID, MonsterData>]]
    local ids = util_table.keys(e.get_noexact("app.MissionIDList.ID").enum_to_field)
    table.sort(ids)

    for _, id in ipairs(ids) do
        local quest_data = get_active_quest_data(id)

        if not quest_data then
            goto continue
        end

        local title_msg = quest_data:get_TitleText()
        local title_str = m.createQuestTitleMessage(title_msg)
        local title = game_lang.replace_tags(title_str)
        local quest_reward_data =
            quest_reward_setting:getDataByFixedId(e.to_fixed("app.MissionIDList.ID_Fixed", id))

        if not quest_reward_data then
            goto continue
        end

        local table_id = quest_reward_data:get_commonRewardTableId()
        local lot_data = m.getRewardItemDataList(common_reward_data, table_id)
        ---@type {
        ---    id: app.ItemDef.ID,
        ---    num: integer,
        ---    prob: number,
        ---    name: string,
        ---  }[]
        local items = {}

        util_game.do_something(lot_data:get_RewardLotsDatas(), function(_, _, value)
            local item_id = value:get_ItemId()

            table.insert(items, {
                id = item_id,
                num = value:get_RewardNum(),
                prob = value:get_Probability(),
                name = ace.item.by_id[item_id].name_local,
            })
        end)

        table.sort(items, function(a, b)
            if a.name ~= b.name then
                return a.name < b.name
            end

            if a.num ~= b.num then
                return a.num < b.num
            end

            return a.prob < b.prob
        end)

        if merge_rewards then
            for _, em in pairs(monster_data) do
                em.invalid_rewards[id] = {
                    title = title,
                    rank = quest_data:getQuestLv(),
                    items = util_table.deep_copy(items),
                }
            end
        else
            util_game.do_something(quest_data:getTargetEmId(), function(_, _, em_id)
                local mon_data = by_em[em_id]
                if not mon_data then
                    return
                end

                mon_data.invalid_rewards[id] = {
                    title = title,
                    rank = quest_data:getQuestLv(),
                    items = util_table.deep_copy(items),
                }
            end)
        end

        ::continue::
    end
end

---@param monster_data MonsterData[]
---@param merge_difficulties boolean
function this.add_invalid_difficulties(monster_data, merge_difficulties)
    ---@param mon_data MonsterData
    ---@param difficulty System.Guid
    ---@param param_mod string
    local function add_difficulty(mon_data, difficulty, param_mod)
        if mon_data:has_difficulty(difficulty) then
            return
        end

        local rate = data_helpers.get_difficulty_rate(difficulty)
        local rank = e.to_enum("app.QuestDef.EM_REWARD_RANK", rate:get_RewardRank())
        local grade = rate:get_RewardGrade()

        if not rank or not grade then
            return
        end

        local role = param_key_to_role("invalid")
        for stage, map in pairs(mon_data.map) do
            add_invalid_param(mon_data, map.stage)
            local guid_str =
                add_invalid_difficulty(mon_data, stage, param_mod, grade, rank, difficulty, role)

            if guid_str then
                mark_invalid_for_roles(map, map.role_by_param.invalid, guid_str)
            end
        end
    end

    local by_em = util_table.map_array(monster_data, function(o)
        return o.id
    end) --[[@as table<app.EnemyDef.ID, MonsterData>]]
    local missman = s.get("app.MissionManager")
    local ids = util_table.keys(e.get_noexact("app.MissionIDList.ID").enum_to_field)
    table.sort(ids)

    for _, id in ipairs(ids) do
        local layout_data = missman:getBossZakoLayoutData(id)
        if not layout_data then
            goto continue
        end

        util_game.do_something(layout_data:get_MainTargetDataList(), function(_, _, value)
            local em_id = e.to_enum("app.EnemyDef.ID", value:get_FixedEmID())
            local mon_data = by_em[em_id]

            if not mon_data then
                return
            end

            local guid = value:get_DifficultyRankId()
            local param_mod = ace.map.legendary_to_key[value:get_LegendaryID()]
            if merge_difficulties then
                for _, mon_data in pairs(monster_data) do
                    add_difficulty(mon_data, guid, param_mod)
                end
            else
                add_difficulty(mon_data, guid, param_mod)
            end
        end)

        ::continue::
    end

    for _, mon_data in pairs(monster_data) do
        for stage in pairs(mon_data.map) do
            merge_all_roles_invalid(mon_data, stage)
        end
    end
end

---@param monster_data MonsterData[]
---@param to_spoof app.EnemyDef.ID
---@param to_copy app.EnemyDef.ID
---@param maps app.FieldDef.STAGE[]
function this.spoof_monster(monster_data, to_spoof, to_copy, maps)
    local spoof_data = util_table.deep_copy(util_table.value(monster_data, function(_, value)
        return value.id == to_copy
    end) --[[@as MonsterData]])
    local name_guid = m.getEnemyNameGuid(to_spoof)
    local lang = game_lang.get_language()

    spoof_data.id = to_spoof
    spoof_data.name_english = game_lang.get_message_local(name_guid, 1)
    spoof_data.name_local = game_lang.get_message_local(name_guid, lang, true)
    spoof_data.spoofed_id = to_copy
    spoof_data.option_tag = get_option_tag(e.get("app.EnemyDef.ID")[to_spoof])

    for _, stage in pairs(maps) do
        make_all_params_invalid(spoof_data, stage)
    end

    for stage, map_data in pairs(spoof_data.map) do
        if not util_table.contains(maps, stage) then
            spoof_data.map[stage] = nil
        else
            map_data.size_by_param_mod = get_size_data()[to_spoof].sizes
        end
    end

    table.insert(monster_data, spoof_data)
end

---@param monster_data MonsterData[]
---@param to_spoof app.FieldDef.STAGE
---@param monsters app.EnemyDef.ID[]
---@param battlefield_ok boolean?
function this.spoof_map(monster_data, to_spoof, monsters, battlefield_ok)
    battlefield_ok = battlefield_ok or false

    ---@type integer[]
    local areas
    for _, em in pairs(monster_data) do
        for stage, map_data in pairs(em.map) do
            if stage == to_spoof then
                areas = util_table.deep_copy(map_data.area)
                break
            end
        end
    end

    for _, em in pairs(monsters) do
        local em_data = util_table.value(monster_data, function(_, value)
            return value.id == em
        end) --[[@as MonsterData]]

        if em_data.map[to_spoof] or (not battlefield_ok and em_data:is_battlefield()) then
            goto next_em
        end

        em_data:add_map(to_spoof)
        em_data.map[to_spoof].spoofed_id_for_route = e.get("app.EnemyDef.ID").EM0160_00_0 -- arkveld
        for _, env in e.iter("app.EnvironmentType.ENVIRONMENT") do
            helpers.add_param_areas(em_data, "invalid", to_spoof, env, areas)
        end

        for stage, map_data in pairs(em_data.map) do
            if stage == to_spoof then
                goto next_stage
            end

            for param_key, mon_dif in pairs(map_data.difficulty_by_param) do
                local role = param_key_to_role(param_key)

                for param_mod, grade, rank, guid in em_data:iter_difficulties(mon_dif) do
                    if not em_data:has_difficulty(guid, to_spoof) then
                        add_invalid_difficulty(
                            em_data,
                            to_spoof,
                            param_mod,
                            grade,
                            rank,
                            guid,
                            role,
                            map_data.env_by_param[param_key]
                        )
                    end
                end
            end

            em_data.map[to_spoof].size_by_param_mod = get_size_data()[em].sizes
            ::next_stage::
        end

        ::next_em::
    end
end

---@param monster_data MonsterData
---@param role_id app.EnemyDef.ROLE_ID[]
---@param maps app.FieldDef.STAGE[]?
function this.add_invalid_role_id(monster_data, role_id, maps)
    maps = maps or util_table.keys(monster_data.map)
    for _, stage in pairs(maps) do
        add_invalid_param(monster_data, stage)
        local map_data = monster_data.map[stage]
        map_data.role_by_param.invalid = {}

        for _, mon_dif in pairs(map_data.difficulty_by_param) do
            for _, role in pairs(role_id) do
                for param_mod, grade, rank, guid in monster_data:iter_difficulties(mon_dif) do
                    add_invalid_difficulty(monster_data, stage, param_mod, grade, rank, guid, role)
                end
            end
        end
    end
end

---@param ex_field_param app.user_data.ExFieldParam
---@return MonsterData[]
function this.get_data(ex_field_param)
    local lang = game_lang.get_language()
    local size_data = get_size_data()
    local ex_em_global_param = ex_field_param:get_ExEnemyGlobalParam()
    local type = e.get("app.EX_FIELD_EVENT_TYPE").POP_EM
    ---@type MonsterData[]
    local ret = {}

    for em_id_name, em_id in e.iter("app.EnemyDef.ID") do
        if not m.isEmValid(em_id) or not m.isBossID(em_id) or not size_data[em_id] then
            goto continue
        end

        local name_guid = m.getEnemyNameGuid(em_id)
        local monster_data = monster:new(
            em_id,
            game_lang.get_message_local(name_guid, 1),
            game_lang.get_message_local(name_guid, lang, true),
            type,
            size_data[em_id].crown,
            ex_em_global_param:isExclusiveEm(em_id),
            get_option_tag(em_id_name)
        )

        local area_move_info_by_em = ex_em_global_param:getAreaMoveInfo(em_id)
        if area_move_info_by_em then
            add_stage_data(monster_data, area_move_info_by_em)
        end

        add_battlefield_data(monster_data)
        add_param_data(monster_data)

        if filter_map_data(monster_data) then
            for _, md in pairs(monster_data.map) do
                md.size_by_param_mod = size_data[em_id].sizes
            end

            table.insert(ret, monster_data)
        end

        ::continue::
    end

    return ret
end

get_size_data = cache.memoize(get_size_data)

return this
