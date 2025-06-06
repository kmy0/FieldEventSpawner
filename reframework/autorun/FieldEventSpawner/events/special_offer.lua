--[[ app.cExFieldEvent_SpecialOffer
    _FreeValue0 = app.cExFieldEvent_EmReward ID1 getSpOfferRewardUniqueIdx(spoffer._UniqueIndex, 1) or spoffer._UniqueIndex - 1
    _FreeValue1 = app.cExFieldEvent_EmReward ID2 getSpOfferRewardUniqueIdx(spoffer._UniqueIndex, 2) or spoffer._UniqueIndex - 2
    _FreeValue2 = app.cExFieldEvent_PopEnemy ID1
    _FreeValue3 = app.cExFieldEvent_PopEnemy ID2
    _FreeValue4 = app.FieldDef.STAGE_Fixed
    _FreeValue5 = GameMinute + some time, end time possibly?
    _FreeMiniValue0 = isVIllageBoost
    _FreeMiniValue1 = app.cKeepQuestData._Index, 255 if quest is not saved, it seems to be also used by EmRewardAllocate0 ?
    _FreeMiniValue2 = EmRewardAllocate1, number of monster part rewards in sceond reward array
        not sure what those are for, first one straight up get overwritten by app.cKeepQuestData._Index,
        changing second one doesnt seem to do anything, both of those are created at reward creation
    _FreeMiniValue3 = unused
    _FreeMiniValue4 = unused
    _FreeMiniValue5 = unused
    _FreeMiniValue6 = unused
    _UniqueIndex = getSpOfferUniqueIdx(<SpOfferList>k__BackingField size i believe) or <SpOfferList>k__BackingField size * -100

    app.cExFieldEvent_EmReward
    unused item id slots are filled with 1 for whatever reason
]]

local data = require("FieldEventSpawner.data")
local util = require("FieldEventSpawner.util")
---@module "FieldEventSpawner.schedule"
local sched

local ace = data.ace
local rl = data.util.reverse_lookup

local this = {}

---@param original_reward app.cExFieldEvent_EmReward
---@param edited_reward_data app.cExFieldScheduleExportData.cEventData?
---@return app.cExFieldEvent_EmReward
local function swap_rewards(original_reward, edited_reward_data)
    -- lovely circulars :))
    if not sched then
        sched = require("FieldEventSpawner.schedule")
    end

    local unique_index = original_reward._UniqueIndex
    if not edited_reward_data then
        edited_reward_data = sched.util.create_event_data()
        edited_reward_data._EventType = rl(ace.enum.ex_event, "EM_REWARD")
    end

    edited_reward_data._UniqueIndex = unique_index
    local edited_reward = util.createEventInstance:call(nil, edited_reward_data) --[[@as app.cExFieldEvent_EmReward]]
    for i = 0, 5 do
        local field = string.format("_FreeValue%s", i)
        if edited_reward:get_field(field) == 0 then
            edited_reward:set_field(field, 1)
        end
    end
    return edited_reward
end

---@param spoffer_info app.cExSpOfferFactory.SpOfferInfo
---@param edited_reward_data EditedRewardData
function this.swap_rewards(spoffer_info, edited_reward_data)
    ---for whatever reason app.cExSpOfferFactory.SpOfferInfo ValueType offsets are wrong
    local reward_array = spoffer_info:get_field("<SpOfferRewardArray>k__BackingField")._Array
    ---@cast reward_array System.Array<app.cExFieldEvent_EmReward>
    local reward1 = swap_rewards(reward_array:get_Item(0), edited_reward_data.reward_array[1])
    local reward2 = swap_rewards(reward_array:get_Item(1), edited_reward_data.reward_array[2])
    reward_array:set_Item(0, reward1)
    reward_array:set_Item(1, reward2)
end

return this
