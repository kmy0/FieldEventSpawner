local e = require("FieldEventSpawner.util.game.enum")
local m = require("FieldEventSpawner.util.ref.methods")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_table = require("FieldEventSpawner.util.misc.table")
---@module "FieldEventSpawner.data.ace.init"
local ace = util_misc.lazy_require("FieldEventSpawner.data.ace.init")

---@class MissionRewardHelper
local this = {}

---@param item_infos System.Array<app.cSendItemInfo>
---@return GuiRewardData[]
local function get_gui_reward_data(item_infos)
    ---@type GuiRewardData[]
    local ret = {}
    util_game.do_something(item_infos, function(_, _, value)
        local item_id = value:get_ItemId()
        local item = ace.item.by_id[item_id]

        if not item then
            return
        end

        table.insert(ret, { id = item.id, count = value:get_Num(), name = item.name_local })
    end)

    return ret
end

---@param quest_id app.MissionIDList.ID
---@param slots integer
---@return GuiRewardData[]?
function this.get_rewards(quest_id, slots)
    local gui_rewards =
        m.getMissionRewards(quest_id, e.get("app.cQuestDirector.TIME_RANK").RANK_S, 0)
    ---@type table<app.ItemDef.LOG_CATEGORY, System.Array<app.cSendItemInfo>>
    local rewards = {}
    ---@type GuiRewardData[]
    local ret = {}

    util_game.do_something(gui_rewards, function(_, _, value)
        local cat = value:get_Category()
        if
            cat == e.get("app.ItemDef.LOG_CATEGORY").QUEST
            or cat == e.get("app.ItemDef.LOG_CATEGORY").TARGET
        then
            rewards[cat] = value:get_ItemInfoList()
        end
    end)

    if
        util_table.all(rewards, function(o)
            return o:get_Count() == 0
        end) or util_table.empty(rewards)
    then
        return
    end

    while #ret < slots do
        local arr = rewards[e.get("app.ItemDef.LOG_CATEGORY").QUEST]
        if arr:get_Count() == 0 then
            arr = rewards[e.get("app.ItemDef.LOG_CATEGORY").TARGET]
        end

        ret = util_table.array_merge_t(ret, get_gui_reward_data(arr))
    end

    if #ret > slots then
        ret = util_table.slice(ret, 1, slots)
    end

    return ret
end

return this
