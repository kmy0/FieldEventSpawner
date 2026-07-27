local animal_gimmick = require("FieldEventSpawner.data.def.animal_gimmick")
local monster = require("FieldEventSpawner.data.def.monster")
local serializer = require("FieldEventSpawner.util.misc.json_serializer")
local util_game = require("FieldEventSpawner.util.game.init")

---@class EventDataSerializer : JsonSerializer
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = serializer })

function this:new()
    local o = serializer.new(self)
    o.serializers = {
        ["System.Guid"] = function(obj)
            ---@cast obj System.Guid
            return {
                guid = util_game.format_guid(obj),
                __type = "System.Guid",
            }
        end,
    }
    o.deserializers = {
        ["System.Guid"] = function(obj)
            ---@diagnostic disable-next-line: undefined-field
            return util_game.parse_guid(obj.guid)
        end,
        ["__MonsterData"] = function(obj)
            return monster:new_from_serial(obj)
        end,
        ["__AnimalGimmickData"] = function(obj)
            return animal_gimmick:new_from_serial(obj)
        end,
    }
    return setmetatable(o, self)
end

---@param obj REManagedObject
function this:get_type_name(obj)
    local tdef = obj:get_type_definition() --[[@as RETypeDefinition]]
    return tdef:get_full_name()
end

return this
