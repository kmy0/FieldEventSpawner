local util_misc = require("FieldEventSpawner.util.misc.init")
---@module "FieldEventSpawner.data.helpers"
local helpers = util_misc.lazy_require("FieldEventSpawner.data.helpers")
local util_game = require("FieldEventSpawner.util.game.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@type table<string, string>
local difficulty_keys = {}
local this = {}

---@param guid System.Guid
---@return string
local function make_unique_difficulty_key(guid)
    local difficulty = helpers.get_difficulty_rate(guid)
    local tdef = util_ref.types.get("app.user_data.EmParamDifficulty2.cDifficultyRate")
    local dif_fields = tdef:get_fields()
    ---@type number[]
    local values = {}

    for _, field in ipairs(dif_fields) do
        local field_type = field:get_type() --[[@as RETypeDefinition]]
        if field_type:is_a("System.Int32") or field_type:is_a("System.Single") then
            table.insert(values, field:get_data(difficulty))
        end

        if field_type:is_a("app.user_data.EmParamDifficulty2.cBadConditionRate") then
            local bad_cond = field:get_data(difficulty)
            if bad_cond then
                table.insert(values, bad_cond:get_DefaultLimit())
                table.insert(values, bad_cond:get_AddAndMaxLimit())
            end
        end

        if field_type:is_a("app.QuestDef.EM_REWARD_RANK_Serializable") then
            local ser = field:get_data(difficulty)
            if ser then
                table.insert(values, ser:get_Value())
            end
        end
    end

    return util_misc.fnv1a(table.concat(values, "|"))
end

---@param guid System.Guid
---@return string
function this.get_unique_difficulty_key(guid)
    local guid_str = util_game.format_guid(guid)
    local ret = difficulty_keys[guid_str]

    if not ret then
        ret = make_unique_difficulty_key(guid)
        difficulty_keys[guid_str] = ret
    end

    return ret
end

---@param map_data MapData
---@param area integer[]
---@param area_by_env table<app.EnvironmentType.ENVIRONMENT, integer[]>
function this.merge_map_areas(map_data, area, area_by_env)
    map_data.area = util_table.unique(util_table.merge_t(map_data.area, area))
    for env, areas in pairs(area_by_env) do
        if not map_data.area_by_env[env] then
            map_data.area_by_env[env] = areas
        else
            map_data.area_by_env[env] =
                util_table.unique(util_table.merge_t(map_data.area_by_env[env], areas))
        end
    end
end

---@param monster_data MonsterData
---@param param_key string
---@param stage app.FieldDef.STAGE
---@param env app.EnvironmentType.ENVIRONMENT
---@param areas integer[]
function this.add_param_areas(monster_data, param_key, stage, env, areas)
    util_table.set_nested_value(
        monster_data.map[stage].area_by_env_by_param,
        { env, param_key },
        areas
    )
    monster_data.map[stage].area_by_param[param_key] = util_table.unique(
        util_table.merge_t(monster_data.map[stage].area_by_param[param_key] or {}, areas)
    )
    util_table.insert_nested_value_unique(
        monster_data.map[stage],
        { "env_by_param", param_key },
        env
    )
end

return this
