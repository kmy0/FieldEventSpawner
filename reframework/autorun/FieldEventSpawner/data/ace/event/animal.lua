---@class (exact) AnimalData : AreaEventData
---@field id app.ExDef.ANIMAL_EVENT_Fixed

local ace_data = require("FieldEventSpawner.data.ace.ace")
local data_util = require("FieldEventSpawner.data.util")
local event = require("FieldEventSpawner.data.ace.event.event")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local this = {}
local rl = data_util.reverse_lookup

---@param ex_field_param app.user_data.ExFieldParam
---@return AnimalData[]
function this.get_data(ex_field_param)
    local lang = util.get_language()

    local field_layout_array = ex_field_param._FieldLayouts
    local field_layout_enum = util.get_array_enum(field_layout_array)
    ---@type table<integer, AnimalData>
    local cache = {}
    ---@type AnimalData[]
    local ret = {}

    local function get_event_struct(animal_event)
        if not cache[animal_event] then
            local name_guid = util.getAnimalEventName:call(nil, animal_event)
            local type = rl(ace_data.enum.ex_event, "ANIMAL_EVENT")
            local e =
                event:new(util.get_message_local(name_guid, 1), util.get_message_local(name_guid, lang, true), type)
            ---@cast e AnimalData
            e.id = data_util.enum_to_fixed("app.ExDef.ANIMAL_EVENT_Fixed", animal_event)
            cache[animal_event] = e
        end
        return cache[animal_event]
    end

    while field_layout_enum:MoveNext() do
        local field_layout = field_layout_enum:get_Current()
        ---@cast field_layout app.user_data.ExFieldParam_LayoutData
        local stage = field_layout:get_Stage()
        local env_param_array = field_layout:get_EnvEventLayoutByArea()
        local env_param_enum = util.get_array_enum(env_param_array)

        while env_param_enum:MoveNext() do
            local env_param = env_param_enum:get_Current()
            ---@cast env_param app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea
            local area = env_param:get_AreaNo()
            local area_fixed = env_param:get_AreaID_Fixed()
            local animal_param_array = env_param:get_AnimalEvents()
            local animal_param_enum = util.get_array_enum(animal_param_array)

            while animal_param_enum:MoveNext() do
                local animal_param = animal_param_enum:get_Current()
                ---@cast animal_param app.user_data.ExFieldParam_LayoutData.cAnimalEventParam
                local event_struct = get_event_struct(animal_param:get_AnimalEvent())

                if not event_struct.map[stage] then
                    event_struct.map[stage] = event.map_data_ctor(stage)
                end

                for environ_type, _ in pairs(ace_data.enum.environ) do
                    if animal_param:getRandomWeight(stage, environ_type) then
                        table_util.insert_nested_value(event_struct.map[stage], { "area_by_env", environ_type }, area)
                    end
                end
                table.insert(event_struct.map[stage].area, area)
                table_util.set_nested_value(event_struct.map[stage], { "area_to_area_fixed", area }, area_fixed)
            end
        end
    end

    for _, struct in pairs(cache) do
        for _, map_data in pairs(struct.map) do
            if not table_util.empty(map_data.area) then
                map_data.area = table_util.set(map_data.area)
                table.sort(map_data.area)
            end
        end
        table.insert(ret, struct)
    end
    return ret
end

return this
