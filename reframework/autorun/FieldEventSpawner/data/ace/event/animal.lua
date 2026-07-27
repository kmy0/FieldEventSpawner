---@class (exact) AnimalData : AnimalGimmickData
---@field id app.ExDef.ANIMAL_EVENT_Fixed

local animal_gimmick = require("FieldEventSpawner.data.def.animal_gimmick")
local e = require("FieldEventSpawner.util.game.enum")
local game_lang = require("FieldEventSpawner.util.game.lang")
local helpers = require("FieldEventSpawner.data.ace.event.helpers")
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

    local function get_animal_data(animal_event)
        if not cache[animal_event] then
            local name_guid = m.getAnimalEventName(animal_event)
            local type = e.get("app.EX_FIELD_EVENT_TYPE").ANIMAL_EVENT
            local animal_data = animal_gimmick:new(
                game_lang.get_message_local(name_guid, 1),
                game_lang.get_message_local(name_guid, lang, true),
                type
            ) --[[@as AnimalData]]
            animal_data.id = e.to_fixed("app.ExDef.ANIMAL_EVENT_Fixed", animal_event)
            cache[animal_event] = animal_data
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
                local animal_data = get_animal_data(animal_param:get_AnimalEvent())
                local map_data = animal_data:add_map(stage)

                for _, environ_type in e.iter("app.EnvironmentType.ENVIRONMENT") do
                    if animal_param:getRandomWeight(stage, environ_type) then
                        helpers.merge_map_areas(map_data, { area }, { [environ_type] = { area } })
                    end
                end

                map_data.area_to_area_fixed[area] = area_fixed
            end
        end
    end

    return util_table.values(cache)
end

return this
