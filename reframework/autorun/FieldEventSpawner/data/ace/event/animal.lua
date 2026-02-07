---@class (exact) AnimalData : AreaEventData
---@field id app.ExDef.ANIMAL_EVENT_Fixed

local data_event = require("FieldEventSpawner.data.ace.event.event")
local e = require("FieldEventSpawner.util.game.enum")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")
local util_game = require("FieldEventSpawner.util.game.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {}

---@param ex_field_param app.user_data.ExFieldParam
---@return AnimalData[]
function this.get_data(ex_field_param)
    local lang = game_lang.get_language()

    local field_layout_array = ex_field_param._FieldLayouts
    local field_layout_enum = util_game.get_array_enum(field_layout_array)
    ---@type table<integer, AnimalData>
    local cache = {}
    ---@type AnimalData[]
    local ret = {}

    local function get_event_struct(animal_event)
        if not cache[animal_event] then
            local name_guid = m.getAnimalEventName(animal_event)
            local type = e.get("app.EX_FIELD_EVENT_TYPE").ANIMAL_EVENT
            local ev = data_event:new(
                game_lang.get_message_local(name_guid, 1),
                game_lang.get_message_local(name_guid, lang, true),
                type
            )
            ---@cast ev AnimalData
            ev.id = e.to_fixed("app.ExDef.ANIMAL_EVENT_Fixed", animal_event)
            cache[animal_event] = ev
        end
        return cache[animal_event]
    end

    while field_layout_enum:MoveNext() do
        local field_layout = field_layout_enum:get_Current()
        ---@cast field_layout app.user_data.ExFieldParam_LayoutData
        local stage = field_layout:get_Stage()
        local env_param_array = field_layout:get_EnvEventLayoutByArea()
        local env_param_enum = util_game.get_array_enum(env_param_array)

        while env_param_enum:MoveNext() do
            local env_param = env_param_enum:get_Current()
            ---@cast env_param app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea
            local area = env_param:get_AreaNo()
            local area_fixed = env_param:get_AreaID_Fixed()
            local animal_param_array = env_param:get_AnimalEvents()
            local animal_param_enum = util_game.get_array_enum(animal_param_array)

            while animal_param_enum:MoveNext() do
                local animal_param = animal_param_enum:get_Current()
                ---@cast animal_param app.user_data.ExFieldParam_LayoutData.cAnimalEventParam
                local event_struct = get_event_struct(animal_param:get_AnimalEvent())

                if not event_struct.map[stage] then
                    event_struct.map[stage] = data_event.map_data_ctor(stage)
                end

                for _, environ_type in e.iter("app.EnvironmentType.ENVIRONMENT") do
                    if animal_param:getRandomWeight(stage, environ_type) then
                        util_table.insert_nested_value(
                            event_struct.map[stage],
                            { "area_by_env", environ_type },
                            area
                        )
                    end
                end
                table.insert(event_struct.map[stage].area, area)
                util_table.set_nested_value(
                    event_struct.map[stage],
                    { "area_to_area_fixed", area },
                    area_fixed
                )
            end
        end
    end

    for _, struct in pairs(cache) do
        for _, map_data in pairs(struct.map) do
            if not util_table.empty(map_data.area) then
                map_data.area = util_table.unique(map_data.area)
                table.sort(map_data.area)
            end
        end
        table.insert(ret, struct)
    end
    return ret
end

return this
