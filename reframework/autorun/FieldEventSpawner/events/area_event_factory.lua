---@class (exact) AreaEventFactory
---@field event_data AreaEventData
---@field stage app.FieldDef.STAGE
---@field time integer
---@field area integer?
---@field protected _area_array integer[]?
---@field build fun(): SpawnResult, SpawnEvent?

local data_rt = require("FieldEventSpawner.data.runtime")
local sched = require("FieldEventSpawner.schedule.init")
local util_game = require("FieldEventSpawner.util.game.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class AreaEventFactory
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this

---@param event_data AreaEventData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param area integer?
---@return AreaEventFactory
function this:new(event_data, stage, time, area)
    local o = {
        event_data = event_data,
        stage = stage,
        area = area,
        time = time,
    }
    setmetatable(o, self)
    ---@cast o AnimalEventFactory
    return o
end

---@return SpawnResult
function this:spawn()
    if not self._area_array then
        return data_rt.enum.spawn_result.NO_AREA
    end

    local res, event = self:build()
    if event then
        sched.add(self.stage, event)
    end

    return res
end

---@protected
---@param areas integer[]
---@param other_events app.cExFieldEventBase[]
---@return integer
function this:_get_area(other_events, areas)
    ---@type integer[]
    local candidates = util_table.deep_copy(areas)
    for _, event in pairs(other_events) do
        if not event:get_IsWorking() then
            goto continue
        end

        local area = event:get_AreaNo()
        local index = util_table.index(candidates, area)
        if index ~= nil then
            table.remove(candidates, index)
        end

        if util_table.empty(candidates) then
            break
        end
        ::continue::
    end

    if not util_table.empty(candidates) then
        return candidates[math.random(#candidates)]
    end
    return areas[math.random(#areas)]
end

---@protected
---@param predicate fun(event:app.cExFieldEventBase): boolean
---@return app.cExFieldEventBase[]
function this:_get_other_events(predicate)
    local _, schedule_timeline = data_rt.get_field_director()
    local event_array = schedule_timeline:get_KeyList()
    local event_enum = util_game.get_array_enum(event_array)
    ---@type app.cExFieldEventBase[]
    local ret = {}

    while event_enum:MoveNext() do
        local event = event_enum:get_Current()
        ---@cast event app.cExFieldEventBase
        if predicate(event) then
            table.insert(ret, event)
        end
    end
    return ret
end

return this
