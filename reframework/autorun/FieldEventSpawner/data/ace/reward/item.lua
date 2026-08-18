---@class ItemRewardHelper
---@field enum RewardType.*
---@field field_name_by_reward_type table<RewardType, string>

local cache = require("FieldEventSpawner.util.misc.cache")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
---@module "FieldEventSpawner.data.helpers"
local helpers = util_misc.lazy_require("FieldEventSpawner.data.helpers")

---@class ItemRewardHelper
local this = {}

---@enum RewardType
this.enum = { ---@class RewardType.*
    SkillGem = 1,
    Artian = 2,
    Amulet = 3,
    Monster = 4,
}
this.field_name_by_reward_type = {
    [this.enum.SkillGem] = "_SkillGemReward",
    [this.enum.Artian] = "_ArtianReward",
    [this.enum.Amulet] = "_AmuletReward",
    [this.enum.Monster] = "_EmReward",
}

---@param tbl_name "_SkillGemReward" | "_ArtianReward" | "_AmuletReward"
---@param em_id app.EnemyDef.ID
---@param role_id app.EnemyDef.ROLE_ID
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param difficulty_guid System.Guid
---@param rank app.QuestDef.EM_REWARD_RANK
---@param is_spoffer boolean
---@return app.user_data.ExQuestRewardSetting.cExRewardDataParam[]
local function get_reward_table_extra(
    tbl_name,
    em_id,
    role_id,
    legendary_id,
    difficulty_guid,
    rank,
    is_spoffer
)
    ---@type app.user_data.ExQuestRewardSetting.cExRewardDataParam[]
    local ret
    local ex_reward_setting = helpers.get_ex_reward_setting()
    local tbl_by_em = ex_reward_setting[tbl_name .. "TblByEm"] --[==[@as app.user_data.ExQuestRewardSetting.SkillGemRewardParamByEm[] | app.user_data.ExQuestRewardSetting.ArtianRewardParamByEm[] | app.user_data.ExQuestRewardSetting.AmuletRewardParamByEm]==]

    util_game.do_something(tbl_by_em, function(_, _, tbl_candidate)
        if tbl_candidate:isMatch(em_id, role_id, legendary_id, difficulty_guid, rank) then
            if is_spoffer and tbl_candidate:get_IsUseSpOfferTbl() then
                ret = tbl_candidate:get_field(tbl_name .. "Tbl_SpOffer")
            else
                ret = tbl_candidate:get_field(tbl_name .. "Tbl")
            end
            return false
        end
    end)

    if not ret then
        ret = ex_reward_setting:get_field(tbl_name .. "Tbl")
    end

    return ret
end

---@param tbl_name "_EmReward"
---@param em_id app.EnemyDef.ID
---@param role_id app.EnemyDef.ROLE_ID
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param difficulty_guid System.Guid
---@param rank app.QuestDef.EM_REWARD_RANK
---@param is_yummy boolean
---@return app.user_data.ExQuestRewardSetting.cExEmRewardDataParam[]
local function get_reward_table_em(
    ---@diagnostic disable-next-line: unused-local
    tbl_name,
    em_id,
    role_id,
    legendary_id,
    difficulty_guid,
    rank,
    is_yummy
)
    ---@type app.user_data.ExQuestRewardSetting.cExEmRewardDataParam[]
    local ret
    local ex_reward_setting = helpers.get_ex_reward_setting()

    util_game.do_something(ex_reward_setting._EmRewardTblByEm, function(_, _, tbl_candidate)
        if tbl_candidate:isMatch(em_id, role_id, legendary_id, difficulty_guid, rank) then
            if is_yummy then
                ret = tbl_candidate._EmRewardTbl_Yummy
            else
                ret = tbl_candidate._EmRewardTbl
            end
            return false
        end
    end)

    if not ret then
        util_game.do_something(ex_reward_setting._EmRewardTblByRank, function(_, _, tbl_candidate)
            if tbl_candidate:get_Rank() > rank then
                return false
            end

            if is_yummy then
                ret = tbl_candidate._EmRewardTbl_Yummy
            else
                ret = tbl_candidate._EmRewardTbl
            end
        end)
    end

    return ret
end

---@param reward_type RewardType
---@param em_id app.EnemyDef.ID
---@param role_id app.EnemyDef.ROLE_ID
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param difficulty_str string
---@param rank app.QuestDef.EM_REWARD_RANK
---@param is_yummy boolean
---@param is_spoffer boolean
---@return app.user_data.ExQuestRewardSetting.cExRewardDataParam[] | app.user_data.ExQuestRewardSetting.cExEmRewardDataParam[]
local function get_reward_table(
    reward_type,
    em_id,
    role_id,
    legendary_id,
    difficulty_str,
    rank,
    is_yummy,
    is_spoffer
)
    local tbl_name = this.field_name_by_reward_type[reward_type]
    local difficulty_guid = util_game.parse_guid(difficulty_str)

    if reward_type == this.enum.Monster then
        return get_reward_table_em(
            tbl_name,
            em_id,
            role_id,
            legendary_id,
            difficulty_guid,
            rank,
            is_yummy
        )
    end

    return get_reward_table_extra(
        tbl_name,
        em_id,
        role_id,
        legendary_id,
        difficulty_guid,
        rank,
        is_spoffer
    )
end

---@param reward_table app.user_data.ExQuestRewardSetting.cExEmRewardDataParam[]
---@param item_id app.ItemDef.ID
---@return integer
local function get_max_item_em(reward_table, item_id)
    local ret = 0

    util_game.do_something(reward_table, function(_, _, value)
        if value:get_Weight() <= 0 or value:getRewardDummyItem() ~= item_id then
            return
        end

        local num = value:get_SlotNum()
        ret = num > ret and num or ret
    end)
    return ret
end

---@param reward_table app.user_data.ExQuestRewardSetting.cExRewardDataParam[]
---@param item_id app.ItemDef.ID
---@param rank app.QuestDef.EM_REWARD_RANK,
---@param is_yummy boolean
---@return integer
local function get_max_item_extra(reward_table, item_id, rank, is_yummy)
    local ret = 0

    util_game.do_something(reward_table, function(_, _, value)
        local weight = 0

        if value:get_Rank() ~= rank or value:get_RewardItem() ~= item_id then
            return
        end

        if is_yummy then
            weight = value:get_Weight_Yummy()
        else
            weight = value:get_Weight_Normal()
        end

        if weight > 0 then
            local num = value:get_Num()
            ret = num > ret and num or ret
        end
    end)
    return ret
end

---@param reward_type RewardType
---@param item app.savedata.cItemWork
---@param em_infos app.ExQuestRewardUtil.EM_INFO_FOR_REWARD[]
---@param is_yummy boolean
---@param is_spoffer boolean
function this.make_item_num_max(reward_type, item, em_infos, is_yummy, is_spoffer)
    local max_num = item.Num
    local item_id = item:get_ItemId()

    for _, em_info in pairs(em_infos) do
        local em_id = em_info["<EmID>k__BackingField"]
        local role_id = em_info["<RoleID>k__BackingField"]
        local legendary_id = em_info["<LegendaryID>k__BackingField"]
        local difficulty_str = util_game.format_guid(em_info["<DifficultyRankID>k__BackingField"])
        local rank = em_info["<Rank>k__BackingField"]

        local tbl = get_reward_table(
            reward_type,
            em_id,
            role_id,
            legendary_id,
            difficulty_str,
            rank,
            is_yummy,
            is_spoffer
        )

        local num = 0
        if reward_type == this.enum.Monster then
            num = get_max_item_em(tbl, item_id)
        else
            num = get_max_item_extra(tbl, item_id, rank, is_yummy)
        end

        max_num = num > max_num and num or max_num
    end

    item.Num = max_num
end

---@param reward_table app.user_data.ExQuestRewardSetting.cRewardItemTable
---@param items System.Array<app.savedata.cItemWork>
function this.make_item_num_max_spoffer_swarm(reward_table, items)
    ---@type table<app.ItemDef.ID, integer>
    local max_nums = {}

    util_game.do_something(items, function(_, _, item)
        local item_id = item:get_ItemId()

        if max_nums[item_id] then
            item.Num = max_nums[item_id]
            return
        end

        local max_num = item.Num
        util_game.do_something(reward_table._RewardItemTbl, function(_, _, value)
            if value:get_Weight() <= 0 or value:get_RewardItem() ~= item_id then
                return
            end

            local num = value:get_Num()
            max_num = num > max_num and num or max_num
        end)

        item.Num = max_num
        max_nums[item_id] = max_num
    end)
end

get_reward_table = cache.memoize(get_reward_table, nil, { do_hash = true })
get_max_item_em = cache.memoize(get_max_item_em, nil, { do_hash = true })
get_max_item_extra = cache.memoize(get_max_item_extra, nil, { do_hash = true })

return this
