local ace = require("FieldEventSpawner.data.ace.init")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")
---@module "FieldEventSpawner.data.mod"
local mod = util_misc.lazy_require("FieldEventSpawner.data.mod")

local this = {}

---@param pop_em app.cExFieldEvent_PopEnemy
---@return string
function this.get_monster_name(pop_em)
    local id = pop_em:get_EmID()
    local role_id = pop_em:get_RoleID()
    local legendary_id = pop_em:get_LegendaryID()
    local guid = m.getEnemyName(id, role_id, legendary_id)
    return game_lang.get_message_local(guid, game_lang.get_language(), true)
end

---@param first app.QuestDef.EM_REWARD_RANK
---@param second app.QuestDef.EM_REWARD_RANK
---@return boolean
function this.is_spoffer_pair(first, second)
    local key = util_table.sort({ first, second })
    local ret = ace.map.spoffer_pairings[string.format("%s,%s", table.unpack(key))]
    return ret or ret == nil
end

---@param query string
---@return table<string, string>
function this.filter_item_rewards(query)
    local ret = {}

    if query == "" then
        return ace.map.item_key_to_name_local
    end

    local number = tonumber(query)
    local predicate = function(key)
        if number then
            return ace.item.by_key[key].id_not_fixed == number
        end

        local query_lower = query:lower()
        local name_lower = ace.item.by_key[key].name_local:lower()
        return name_lower:find(query_lower) ~= nil
    end

    for k, v in pairs(ace.map.item_key_to_name_local) do
        if predicate(k) then
            ret[k] = v
        end
    end

    return ret
end

---@param guid System.Guid
---@return app.user_data.EmParamDifficulty2.cDifficultyRate
function this.get_difficulty_rate(guid)
    local enemyman = s.get("app.EnemyManager")
    local em_setting = enemyman:get_Setting()
    local diff2 = em_setting:get_Difficulty2()
    return diff2:getDifficultyRate(guid)
end

---@param pop_em app.cExFieldEvent_PopEnemy
---@return boolean
function this.is_invalid_em(pop_em)
    local em_id = pop_em:get_EmID()
    if ace.map.bad_monsters[em_id] then
        return true
    end

    local em_data = this.get_monster_data(em_id)
    if not em_data then
        return false
    end

    local map = em_data.map[mod.state.stage] --[[@as MonsterMapData?]]
    if not map then
        return false
    end

    local role = pop_em:get_RoleID()
    local guid = pop_em:get_DifficultyID()
    return em_data:is_difficulty_invalid(guid, mod.state.stage, role)
end

---@param em_id app.EnemyDef.ID
---@return MonsterData?
function this.get_monster_data(em_id)
    for _, em in pairs(ace.event.by_type.monster) do
        if em.id == em_id then
            return em
        end
    end
end

---@param em MonsterData
---@param difficulty System.Guid?
---@param role app.EnemyDef.ROLE_ID?
---@return boolean
function this.is_invalid_em2(em, difficulty, role)
    if ace.map.bad_monsters[em.id] then
        return true
    end

    if not difficulty or not role then
        return false
    end

    return em:is_difficulty_invalid(difficulty, mod.state.stage, role)
end

return this
