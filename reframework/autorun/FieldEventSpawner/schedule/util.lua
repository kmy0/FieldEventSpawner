local util_game = require("FieldEventSpawner.util.game.init")

local this = {}

---@param events System.Array<app.cExFieldEventBase>
---@return app.cExFieldScheduleExportData.cEventData[]
function this.unpack_events(events)
    local enum = util_game.get_array_enum(events)
    ---@type app.cExFieldScheduleExportData.cEventData[]
    local t = {}
    while enum:MoveNext() do
        local e = enum:get_Current()
        ---@cast e app.cExFieldEventBase
        table.insert(t, e:exportData())
    end
    return t
end

---@return app.cExFieldScheduleExportData.cEventData
function this.create_event_data()
    local ret = sdk.create_instance("app.cExFieldScheduleExportData.cEventData", true):add_ref() --[[@as app.cExFieldScheduleExportData.cEventData]]
    -- valid index can also be 0 which is default value of _UniqueIndex, so to make sure that _UniqueIndex was not set we have to set it to -1
    ret._UniqueIndex = -1
    return ret
end

return this
