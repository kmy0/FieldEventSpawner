---@class RewardFactory
---@field reward_array GuiRewardData[]
---@field stage app.FieldDef.STAGE
---@field protected _schedule_timeline app.cExFieldDirector.cScheduleTimeline
---@field protected __index RewardFactory

---@class (exact) RewardData
---@field reward_array System.Array<app.cExFieldEvent_EmReward>
---@field reward_id1 integer
---@field reward_id2 integer

---@class (exact) EditedRewardData : RewardData
---@field reward_array app.cExFieldScheduleExportData.cEventData[]

--[[ app.cExFieldEvent_EmReward
    _FreeValue0 = app.ItemDef.ID_Fixed
    _FreeValue1 = app.ItemDef.ID_Fixed
    _FreeValue2 = app.ItemDef.ID_Fixed
    _FreeValue3 = app.ItemDef.ID_Fixed
    _FreeValue4 = app.ItemDef.ID_Fixed
    _FreeValue5 = unused
    _FreeMiniValue0 = Item Count
    _FreeMiniValue1 = Item Count
    _FreeMiniValue2 = Item Count
    _FreeMiniValue3 = Item Count
    _FreeMiniValue4 = Item Count
    _FreeMiniValue5 = unused
    _FreeMiniValue6 = Bit array, eg. if there is an item in _FreeValue3, you set bit 3 to 1 etc.
]]

local data = require("FieldEventSpawner.data")
local sched = require("FieldEventSpawner.schedule")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local rl = data.util.reverse_lookup
local rt = data.runtime
local ace = data.ace

---@class RewardFactory
local this = {}
this.__index = this

---@param reward_array GuiRewardData[]
---@param stage app.FieldDef.STAGE
---@return RewardFactory
function this:new(reward_array, stage)
    local o = {
        reward_array = reward_array,
        stage = stage,
    }
    setmetatable(o, self)
    _, o._schedule_timeline = rt.get_field_director()
    return o
end

---@return EditedRewardData?
function this:build()
    ---@type app.cExFieldScheduleExportData.cEventData[]
    local packs = {}
    for _, pack in ipairs({
        table_util.slice(self.reward_array, 1, 5, true),
        table_util.slice(self.reward_array, 6, 10, true),
    }) do
        if pack then
            table.insert(packs, self:_build(pack))
        end
    end

    if table_util.empty(packs) then
        return
    end

    ---@type EditedRewardData
    local ret = {
        reward_array = packs,
        reward_id1 = -1,
        reward_id2 = -1,
    }
    for i = 1, #packs do
        ret[string.format("reward_id%s", i)] = packs[i]._UniqueIndex
    end
    return ret
end

---@protected
---@param reward_array GuiRewardData[]
---@return app.cExFieldScheduleExportData.cEventData
function this:_build(reward_array)
    local byte_array = 0
    local event_data = sched.util.create_event_data()
    event_data._EventType = rl(ace.enum.ex_event, "EM_REWARD")

    for i = 1, #reward_array do
        local reward = reward_array[i]
        if reward then
            event_data:set_field("_FreeValue" .. i - 1, reward.id)
            event_data:set_field("_FreeMiniValue" .. i - 1, reward.count)
            byte_array = byte_array | (1 << (i - 1))
        end
    end
    event_data._FreeMiniValue6 = byte_array
    event_data._UniqueIndex = self._schedule_timeline:newEventUniqueIndex(self.stage)
    return event_data
end

return this
