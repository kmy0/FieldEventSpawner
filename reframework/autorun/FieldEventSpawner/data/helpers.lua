local ace = require("FieldEventSpawner.data.ace.init")
local cache = require("FieldEventSpawner.util.misc.cache")
local config = require("FieldEventSpawner.config.init")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
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

---@param guid System.Guid
---@return string
function this.get_difficulty_rate_string(guid)
    local rate = this.get_difficulty_rate(guid)
    return string.format(
        "%s%s   |   %sx %s,  %sx %s,  %sx %s",
        m.getRewardRankFromDifficulty(guid),
        config.lang:tr("misc.text_star"),
        util_misc.round(rate:get_Health(), 2),
        config.lang:tr("misc.text_hp"),
        util_misc.round(rate:get_Attack(), 2),
        config.lang:tr("misc.text_attack"),
        util_misc.round(rate:get_PartsVital(), 2),
        config.lang:tr("misc.text_parts_vital")
    )
end

---@param guid System.Guid
---@return string
function this.get_difficulty_rate_string_with_grade(guid)
    local rate = this.get_difficulty_rate(guid)
    return string.format(
        "%s%s   |   %sx %s,  %sx %s,  %sx %s",
        config.lang:tr("misc.text_star"),
        rate:get_RewardGrade(),
        util_misc.round(rate:get_Health(), 2),
        config.lang:tr("misc.text_hp"),
        util_misc.round(rate:get_Attack(), 2),
        config.lang:tr("misc.text_attack"),
        util_misc.round(rate:get_PartsVital(), 2),
        config.lang:tr("misc.text_parts_vital")
    )
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

---@param quest_data app.cKeepQuestData
---@return boolean, app.QuestCheckUtil.INCORRECT_STATUS
function this.check_ex_quest(quest_data)
    local system_int32 = util_ref.value_type("System.Int32")
    local ret = m.checkExQuest(system_int32:address(), quest_data)
    return ret, system_int32.m_value
end

---@param pop_em app.cExFieldEvent_PopEnemy
---@return boolean, app.QuestCheckUtil.INCORRECT_STATUS
function this.check_ex_quest_pop_em(pop_em)
    local ret, bit = false, 0
    util_misc.try(function()
        local quest_data = m.createActiveQuestData_Instant(pop_em, mod.state.stage)
        local keep_quest_data = quest_data:get_KeepQuestData()
        ret, bit = this.check_ex_quest(keep_quest_data)
    end)

    return ret, bit
end

---@param index integer? by default, 0
---@return boolean, app.QuestCheckUtil.INCORRECT_STATUS
function this.check_ex_quest_spoffer(index)
    index = index or 0
    local field_director = mod.get_field_director()
    local spoffer_factory = field_director._SpOfferFactory
    local spoffer_view_array = spoffer_factory:getSpOfferInfoList(-1, true, mod.state.stage)

    local ret, bit = false, 0
    util_misc.try(function()
        local spoffer_view = spoffer_view_array:get_Item(index)
        local quest_data = spoffer_factory:createSpOfferActiveQuestData(spoffer_view)
        local keep_quest_data = quest_data:get_KeepQuestData()
        ret, bit = this.check_ex_quest(keep_quest_data)
    end)

    return ret, bit
end

---@param index integer? by default, 0
---@return boolean, app.QuestCheckUtil.INCORRECT_STATUS
function this.check_ex_quest_spoffer_swarm(index)
    index = index or 0
    local field_director = mod.get_field_director()
    local spoffer_factory = field_director._SpOfferFactory
    local spoffer_by_stage = spoffer_factory._CurrentSpOfferInfo
    local spoffer_array = spoffer_by_stage:get_SpOfferList()
    local spoffer_more_factory = spoffer_factory._MoreTargetSpOfferFactory
    local spoffer_view_array = spoffer_factory:getSpOfferInfoList(-1, true, mod.state.stage)

    local ret, bit = false, 0
    util_misc.try(function()
        local spoffer_info = spoffer_array:get_Item(index)
        local spoffer_view = spoffer_view_array:get_Item(index)
        local quest_data =
            spoffer_more_factory:createSpOfferActiveQuestData(spoffer_info, spoffer_view)
        local keep_quest_data = quest_data:get_KeepQuestData()
        ret, bit = this.check_ex_quest(keep_quest_data)
    end)

    return ret, bit
end

---@return app.user_data.ExQuestRewardSetting
function this.get_ex_reward_setting()
    local various_data_manager = s.get("app.VariousDataManager")
    local various_data_manager_setting = various_data_manager:get_Setting()
    return various_data_manager_setting:get_ExQuestRewardSetting()
end

---@return app.savedata.cQuestParam
function this.get_last_keep_quest()
    local user_save = util_ref.singletons.get("app.SaveDataManager"):getCurrentUserSaveData()
    local quests = user_save:get_Quest()
    local timestamp = 0
    local ret

    util_game.do_something(quests, function(_, _, value)
        if value.CreatedDate > timestamp and value.CreatedDate ~= -1 and value.RemainingNum > 0 then
            ret = value
            timestamp = value.CreatedDate
        end
    end)

    return ret
end

this.get_ex_reward_setting = cache.memoize(this.get_ex_reward_setting)

return this
