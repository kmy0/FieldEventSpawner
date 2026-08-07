---@class (exact) MonsterParamModifier
---@field legendary boolean?
---@field none boolean?
---@field legendary_king boolean?

---@class (exact) MonsterSizeData
---@field min integer
---@field max integer

---@class (exact) MonsterCrown
---@field small integer
---@field large integer
---@field king integer

---@class (exact) MonsterSize
---@field legendary table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>?
---@field none table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>?
---@field legendary_king table<app.QuestDef.EM_REWARD_RANK, MonsterSizeData>?

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
---@field invalid MonsterParamModifier?

---@class (exact) MonsterMapData : MapData
---@field param MonsterParam
---@field param_by_env table<app.EnvironmentType.ENVIRONMENT, MonsterParam>
---@field area_by_param table<string, integer[]>
---@field area_by_env_by_param table<app.EnvironmentType.ENVIRONMENT, table<string, integer[]>>
---@field difficulty_by_param table<string, MonsterDifficulty>
---@field difficulty_by_env_by_param table<app.EnvironmentType.ENVIRONMENT, table<string, MonsterDifficulty>>
---@field env_by_param table<string, app.EnvironmentType.ENVIRONMENT[]>
---@field size_by_param_mod MonsterSize
---@field difficulty_unique table<string, boolean> unique_key
---@field difficulty_invalid table<app.EnemyDef.ROLE_ID, table<string, boolean>> guid_str
---@field role_by_param table<string, app.EnemyDef.ROLE_ID[]>

---@class (exact) MonsterData : AreaEventData
---@field id app.EnemyDef.ID
---@field spoofed_id app.EnemyDef.ID?
---@field spoofed_id_for_route app.EnemyDef.ID?
---@field map table<app.FieldDef.STAGE, MonsterMapData>
---@field crown MonsterCrown
---@field is_exclusive boolean
---@field option_tag table<integer, string>

local area_event_base = require("FieldEventSpawner.data.def.area_event_base")
local helpers = require("FieldEventSpawner.data.ace.event.helpers")
---@module"FieldEventSpawner.data.mod"
local mod = require("FieldEventSpawner.util.misc.init").lazy_require("FieldEventSpawner.data.mod")
local util_game = require("FieldEventSpawner.util.game.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class MonsterData
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = area_event_base })

---@param id app.EnemyDef.ID
---@param name_english string
---@param name_local string
---@param type app.EX_FIELD_EVENT_TYPE
---@param crown MonsterCrown
---@param is_exclusive boolean
---@param option_tag table<integer, string>
---@return MonsterData
function this:new(id, name_english, name_local, type, crown, is_exclusive, option_tag)
    local o = area_event_base.new(self, name_english, name_local, type)
    setmetatable(o, self)
    ---@cast o MonsterData
    o.id = id
    o.crown = crown
    o.is_exclusive = is_exclusive
    o.map = {}
    o.option_tag = option_tag
    o.__type = "__MonsterData"
    return o
end

---@param serialized_class table
---@return MonsterData
function this:new_from_serial(serialized_class)
    local o = area_event_base.new_from_serial(self, serialized_class)
    return setmetatable(o, self) --[[@as MonsterData]]
end

---@param stage app.FieldDef.STAGE
---@param args {
--- area_by_env: table<app.EnvironmentType.ENVIRONMENT, integer[]>?,
--- area: integer[]?,
--- area_by_param: table<string, integer[]>?,
--- area_by_env_by_param: table<app.EnvironmentType.ENVIRONMENT, table<string, integer[]>>?,
--- }?
function this:add_map(stage, args)
    if self.map[stage] then
        return self.map[stage]
    end

    args = args or {}
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.map[stage] = area_event_base.add_map(self, stage, args)
    self.map[stage].area_by_param = args.area_by_param or {}
    self.map[stage].area_by_env_by_param = args.area_by_env_by_param or {}
    self.map[stage].param = {}
    self.map[stage].param_by_env = {}
    self.map[stage].difficulty_by_param = {}
    self.map[stage].difficulty_by_env_by_param = {}
    self.map[stage].env_by_param = {}
    self.map[stage].size_by_param_mod = {}
    self.map[stage].difficulty_unique = {}
    self.map[stage].difficulty_invalid = {}
    self.map[stage].role_by_param = {}

    return self.map[stage]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@param em_param string
---@return integer[]?
function this:get_area_array(stage, environ, em_param)
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
---@param em_param string
---@return app.EnemyDef.ROLE_ID[]?
function this:get_role_array(stage, em_param)
    local map = self.map[stage]
    if not map then
        return
    end

    return map.role_by_param[em_param]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@param em_param string
---@param em_param_mod string
---@return table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
function this:get_difficulty_table(stage, environ, em_param, em_param_mod)
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
function this:get_difficulty_rank_table(stage, environ, em_param, em_param_mod, em_difficulty)
    local difficulty_table = self:get_difficulty_table(stage, environ, em_param, em_param_mod)

    if not difficulty_table then
        return
    end

    return difficulty_table[em_difficulty]
end

---@param stage app.FieldDef.STAGE
---@param environ app.EnvironmentType.ENVIRONMENT?
---@return MonsterParam?
function this:get_param_struct(stage, environ)
    local map = self.map[stage]
    if not map then
        return
    end

    if environ then
        return map.param_by_env[environ]
    end
    return map.param
end

---@param difficulty System.Guid
---@param stage app.FieldDef.STAGE?
---@return boolean
function this:has_difficulty(difficulty, stage)
    local unique_key = helpers.get_unique_difficulty_key(difficulty)
    if not stage then
        for _, map in pairs(self.map) do
            if map.difficulty_unique[unique_key] then
                return true
            end
        end
    end

    local map = self.map[stage]
    if not map then
        return false
    end

    return false
end

---@param difficulty System.Guid
---@param stage app.FieldDef.STAGE
---@param role app.EnemyDef.ROLE_ID
---@return boolean
function this:is_difficulty_invalid(difficulty, stage, role)
    local map = self.map[stage]

    if not map then
        return false
    end

    local by_role = map.difficulty_invalid[role]
    if not by_role then
        return false
    end

    return by_role[util_game.format_guid(difficulty)]
end

---@param param_key string
---@param param_mod string
---@param stage app.FieldDef.STAGE
---@param env app.EnvironmentType.ENVIRONMENT
---@param grade integer
---@param rank app.QuestDef.EM_REWARD_RANK
---@param difficulty System.Guid
---@param role app.EnemyDef.ROLE_ID?
---@return string -- guid_str
function this:add_difficulty(param_key, param_mod, stage, env, grade, rank, difficulty, role)
    util_table.set_nested_value(
        self.map[stage],
        { "param_by_env", env, param_key, param_mod },
        true
    )
    util_table.insert_nested_value_unique(self.map[stage], { "env_by_param", param_key }, env)
    util_table.insert_nested_value(
        self.map[stage],
        { "difficulty_by_env_by_param", env, param_key, param_mod, grade, rank },
        difficulty
    )
    util_table.insert_nested_value_unique(
        self.map[stage],
        { "difficulty_by_param", param_key, param_mod, grade, rank },
        difficulty
    )
    util_table.set_nested_value(self.map[stage], { "param", param_key, param_mod }, true)

    if role then
        util_table.insert_nested_value_unique(self.map[stage], { "role_by_param", param_key }, role)
    end

    self.map[stage].difficulty_unique[helpers.get_unique_difficulty_key(difficulty)] = true
    return util_game.format_guid(difficulty)
end

---@return boolean
function this:is_battlefield()
    local is_battlefield = false
    local is_normal = false
    for _, map_data in pairs(self.map) do
        for param_key, _ in pairs(map_data.param) do
            if param_key == "invalid" then
                goto continue
            end

            if param_key == "battlefield_repel" or param_key == "battlefield_slay" then
                is_battlefield = true
            else
                is_normal = true
            end

            ::continue::
        end
    end

    return is_battlefield and not is_normal
end

---@return boolean
function this:is_battlefield_current_stage()
    local map_data = self.map[mod.state.stage]
    if not map_data then
        return false
    end

    for param_key, _ in pairs(map_data.param) do
        if param_key == "invalid" then
            goto continue
        end

        if param_key == "battlefield_repel" or param_key == "battlefield_slay" then
            return true
        end

        ::continue::
    end

    return false
end

---@param mon_dif MonsterDifficulty
---@return fun(): string, integer, app.QuestDef.EM_REWARD_RANK, System.Guid
function this:iter_difficulties(mon_dif)
    return coroutine.wrap(function()
        for param_mod, by_grade in pairs(mon_dif) do
            for grade, by_rank in pairs(by_grade) do
                for rank, guids in pairs(by_rank) do
                    for _, guid in pairs(guids) do
                        coroutine.yield(param_mod, grade, rank, guid)
                    end
                end
            end
        end
    end)
end

return this
