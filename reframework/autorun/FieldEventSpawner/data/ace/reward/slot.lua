local cache = require("FieldEventSpawner.util.misc.cache")
local e = require("FieldEventSpawner.util.game.enum")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
---@module "FieldEventSpawner.data.helpers"
local helpers = util_misc.lazy_require("FieldEventSpawner.data.helpers")

---@class SlotRewardHelper
local this = {}

---@param role_id app.EnemyDef.ROLE_ID
---@param rank app.QuestDef.EM_REWARD_RANK
---@return app.user_data.ExQuestRewardSetting.cExRewardSlotParam[]
local function get_slot_table_em(role_id, rank)
    local ex_reward_setting = helpers.get_ex_reward_setting()
    ---@type app.user_data.ExQuestRewardSetting.cExRewardSlotParam[]
    local ret

    if role_id == e.get("app.EnemyDef.ROLE_ID").FRENZY then
        ret = ex_reward_setting._RewardSlotTbl_Frenzy
    else
        local tbl_by_rank = ex_reward_setting._RewardSlotTblByRank
        util_game.do_something(tbl_by_rank, function(_, _, tbl_candidate)
            if tbl_candidate:get_Rank() > rank then
                return false
            end

            ret = tbl_candidate._RewardSlotTbl
        end)
    end

    return ret
end

---@param quest_rank app.QuestDef.EM_REWARD_RANK
---@param lowest_em_rank app.QuestDef.EM_REWARD_RANK
---@return app.user_data.ExQuestRewardSetting.cExRewardSlotParam[]
local function get_slot_table_spoffer(quest_rank, lowest_em_rank)
    local ex_reward_setting = helpers.get_ex_reward_setting()
    ---@type app.user_data.ExQuestRewardSetting.cExRewardSlotParam[]
    local ret

    local tbl_by_rank = ex_reward_setting._RewardSlotTblByRank
    util_game.do_something(tbl_by_rank, function(_, _, tbl_candidate)
        if tbl_candidate:get_Rank() > quest_rank then
            return false
        end

        util_game.do_something(
            tbl_candidate._RewardSlotTbl_SpOfferByLowerRank,
            function(_, _, tbl_candidate2)
                if tbl_candidate2:get_LowerRank() > lowest_em_rank then
                    return false
                end

                ret = tbl_candidate2._RewardSlotTbl_SpOffer
            end
        )
    end)

    return ret
end

---@param em_infos app.ExQuestRewardUtil.EM_INFO_FOR_REWARD[]
---@param rank app.QuestDef.EM_REWARD_RANK
---@param is_spoffer boolean
---@return app.user_data.ExQuestRewardSetting.cExRewardSlotParam[]
local function get_slot_table(em_infos, rank, is_spoffer)
    if #em_infos == 1 or not is_spoffer then
        local role_id = em_infos[1]["<RoleID>k__BackingField"]
        return get_slot_table_em(role_id, rank)
    end

    local lowest_rank = math.huge
    for _, em_info in pairs(em_infos) do
        local em_rank = em_info["<Rank>k__BackingField"]
        lowest_rank = em_rank < lowest_rank and em_rank or lowest_rank
    end

    return get_slot_table_spoffer(rank, lowest_rank)
end

---@param slot_table app.user_data.ExQuestRewardSetting.cExRewardSlotParam[]
---@param grade integer
---@param is_yummy boolean
---@return integer
local function get_max_slot(slot_table, grade, is_yummy)
    local ret = 0
    util_game.do_something(slot_table, function(_, _, value)
        if value:get_Grade() ~= grade then
            return
        end

        local weight = 0

        if is_yummy then
            weight = value:get_Weight_Yummy()
        else
            weight = value:get_Weight_Normal()
        end

        if weight > 0 then
            local num = value:get_LotNum()
            ret = num > ret and num or ret
        end
    end)

    return ret
end

---@param em_infos app.ExQuestRewardUtil.EM_INFO_FOR_REWARD[]
---@param rank app.QuestDef.EM_REWARD_RANK
---@param is_yummy boolean
---@param is_spoffer boolean
---@return integer
function this.get_slot_num_max(em_infos, rank, is_yummy, is_spoffer)
    local tbl = get_slot_table(em_infos, rank, is_spoffer)
    local grade = 0

    for _, em_info in pairs(em_infos) do
        local em_grade = em_info["<Grade>k__BackingField"]
        grade = em_grade > grade and em_grade or grade
    end

    return get_max_slot(tbl, grade, is_yummy)
end

---@param slot_table app.user_data.ExQuestRewardSetting.cRewardSlotTable
---@return integer
function this.get_slot_num_max_spoffer_swarm(slot_table)
    local tbl = slot_table._RewardSlotTbl
    local ret = 0

    util_game.do_something(tbl, function(_, _, value)
        if value:get_Weight() > 0 then
            local num = value:get_SlotNum()
            ret = num > ret and num or ret
        end
    end)

    return ret
end

get_max_slot = cache.memoize(get_max_slot, nil, { do_hash = true })
get_slot_table_em = cache.memoize(get_slot_table_em, nil, { do_hash = true })
get_slot_table_spoffer = cache.memoize(get_slot_table_spoffer, nil, { do_hash = true })

return this
