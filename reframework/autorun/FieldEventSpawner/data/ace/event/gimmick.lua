---@class (exact) GimmickData : AreaEventData
---@field id app.ExDef.GIMMICK_EVENT_Fixed
---@field ex_id app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE
---@field id_not_fixed app.ExDef.GIMMICK_EVENT

---@class (exact) NpcData : GimmickData
---@field guid System.Guid

local ace_data = require("FieldEventSpawner.data.ace.ace")
local data_util = require("FieldEventSpawner.data.util")
local event = require("FieldEventSpawner.data.ace.event.event")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local this = {}
local rl = data_util.reverse_lookup

---@param cache table<integer, GimmickData>
---@return GimmickData[]
local function cache_to_ret(cache)
    ---@type GimmickData[]
    local ret = {}
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

---@param cache table<integer, GimmickData>
---@param gimmick_event app.ExDef.GIMMICK_EVENT
---@param ex_id app.cExFieldEvent_GimmickEvent.GIMMICK_EVENT_TYPE
---@param lang via.Language
---@param guid System.Guid?
---@return GimmickData
local function get_event_struct(cache, gimmick_event, ex_id, lang, guid)
    if not cache[gimmick_event] then
        local name_guid = util.getGimmickEventName:call(nil, gimmick_event)
        local type = rl(ace_data.enum.ex_event, "GIMMICK_EVENT")
        local e = event:new(util.get_message_local(name_guid, 1), util.get_message_local(name_guid, lang, true), type)
        ---@cast e GimmickData
        e.id = data_util.enum_to_fixed("app.ExDef.GIMMICK_EVENT_Fixed", gimmick_event)
        e.ex_id = ex_id
        e.id_not_fixed = gimmick_event
        if guid then
            ---@cast e NpcData
            e.guid = guid
        end
        cache[gimmick_event] = e
    end
    return cache[gimmick_event]
end

---@param ex_field_param app.user_data.ExFieldParam
---@param lang via.Language
---@return GimmickData[]
local function get_npc_data(ex_field_param, lang)
    local ex_id = rl(ace_data.enum.ex_gimmick, "ASSIST_NPC")
    local npc_param_array = ex_field_param:get_AssistNpcParams()
    local npc_param_enum = util.get_array_enum(npc_param_array)
    ---@type table<integer, GimmickData>
    local cache = {}

    while npc_param_enum:MoveNext() do
        local npc_param = npc_param_enum:get_Current()
        ---@cast npc_param app.user_data.ExFieldParam.cAssistNpcParam
        local npc_gimmick_array = npc_param._AssistNpcGimmicks
        local npc_gimmick_enum = util.get_array_enum(npc_gimmick_array)
        local guid = npc_param:get_InstanceGuid()

        while npc_gimmick_enum:MoveNext() do
            local npc_gimmick = npc_gimmick_enum:get_Current()
            ---@cast npc_gimmick app.user_data.ExFieldParam.cAssistNpcGimmick
            local event_struct = get_event_struct(cache, npc_gimmick:get_GimmickEvent(), ex_id, lang, guid)
            local area = npc_gimmick:get_AreaNo()
            local stage = npc_gimmick:get_Stage()

            if not event_struct.map[stage] then
                event_struct.map[stage] = event.map_data_ctor(stage)
            end

            for environ_type, _ in pairs(ace_data.enum.environ) do
                if npc_gimmick:checkEnableEnvBit(environ_type) then
                    table_util.insert_nested_value(event_struct.map[stage], { "area_by_env", environ_type }, area)
                end
            end
            table.insert(event_struct.map[stage].area, area)
            table_util.set_nested_value(
                event_struct.map[stage],
                { "area_to_area_fixed", area },
                npc_gimmick:get_AreaID_Fixed()
            )
        end
    end
    return cache_to_ret(cache)
end

--FIXME: coludnt force it to respawn
-- ---@param ex_field_param app.user_data.ExFieldParam
-- ---@param lang via.Language
-- local function get_ancient_coin_data(ex_field_param, lang)
--     local ex_id = rl(ace.enum.ex_gimmick, "ANCIENT_COIN")
--     local id = 59 --63-67
--     local field_layout_array = ex_field_param._FieldLayouts
--     local field_layout_enum = util.get_array_enum(field_layout_array)
--     ---@type table<integer, GimmickData>
--     local cache = {}
--     local event_struct = get_event_struct(cache, id, ex_id, lang)
--     event_struct.name_english = "???"
--     event_struct.name_local = language.tr(string.format("misc.gimmick_event.%s.name", id))

--     while field_layout_enum:MoveNext() do
--         local field_layout = field_layout_enum:get_Current()
--         ---@cast field_layout app.user_data.ExFieldParam_LayoutData
--         local coin_param_array = field_layout._AncientCoinParams
--         local coin_param_enum = util.get_array_enum(coin_param_array)
--         local stage = field_layout:get_Stage()

--         if not event_struct.map[stage] then
--             event_struct.map[stage] = event.map_data_ctor(stage)
--         end

--         while coin_param_enum:MoveNext() do
--             local coin_param = coin_param_enum:get_Current()
--             ---@cast coin_param app.user_data.ExFieldParam_LayoutData.cAncientCoinParam
--             local area = coin_param:get_AreaNo()

--             for environ_type, _ in pairs(data.ace_environ_enum) do
--                 if coin_param:isContainEnvType(environ_type) then
--                     table_util.insert_nested_value(event_struct.map[stage], { "area_by_env", environ_type }, area)
--                 end
--             end
--             table.insert(event_struct.map[stage].area, area)
--             table_util.set_nested_value(event_struct.map[stage], { "area_to_area_fixed", area },
--                 coin_param:get_AreaID_Fixed())
--         end
--     end
--     return cache_to_ret(cache)
-- end

---@param ex_field_param app.user_data.ExFieldParam
---@param lang via.Language
local function get_tokusan_data(ex_field_param, lang)
    local ex_id = rl(ace_data.enum.ex_gimmick, "RARE_TOKUSAN")
    local field_layout_array = ex_field_param._FieldLayouts
    local field_layout_enum = util.get_array_enum(field_layout_array)
    ---@type table<integer, GimmickData>
    local cache = {}

    while field_layout_enum:MoveNext() do
        local field_layout = field_layout_enum:get_Current()
        ---@cast field_layout app.user_data.ExFieldParam_LayoutData
        local stage = field_layout:get_Stage()
        local tokusan_param_array = field_layout._RareTokusanParams
        local tokusan_param_enum = util.get_array_enum(tokusan_param_array)

        while tokusan_param_enum:MoveNext() do
            local tokusan_param = tokusan_param_enum:get_Current()
            ---@cast tokusan_param app.user_data.ExFieldParam_LayoutData.cRareTokusanParam
            local area = tokusan_param:get_AreaNo()
            local area_fixed = tokusan_param:get_AreaID_Fixed()
            local param_area_info_by_env = tokusan_param:get_ParamsByEnv()
            local by_env_enum = util.get_array_enum(param_area_info_by_env._EnvParams)
            local event_struct = get_event_struct(cache, tokusan_param:get_GimmickEvent(), ex_id, lang)

            if not event_struct.map[stage] then
                event_struct.map[stage] = event.map_data_ctor(stage)
            end

            while by_env_enum:MoveNext() do
                local tokusan_param_by_env = by_env_enum:get_Current()
                ---@cast tokusan_param_by_env app.user_data.ExFieldParam_LayoutData.cRareTokusanParamByEnv
                if tokusan_param_by_env:get_Weight() == 0 then
                    goto continue
                end

                local environ = tokusan_param_by_env:get_EnvType()
                table_util.insert_nested_value(event_struct.map[stage], { "area_by_env", environ }, area)
                ::continue::
            end
            table.insert(event_struct.map[stage].area, area)
            table_util.set_nested_value(event_struct.map[stage], { "area_to_area_fixed", area }, area_fixed)
        end
    end
    return cache_to_ret(cache)
end

---@param ex_field_param app.user_data.ExFieldParam
---@param lang via.Language
---@return GimmickData[]
local function get_env_data(ex_field_param, lang)
    local ex_id = rl(ace_data.enum.ex_gimmick, "NONE")
    local field_layout_array = ex_field_param._FieldLayouts
    local field_layout_enum = util.get_array_enum(field_layout_array)
    ---@type table<integer, GimmickData>
    local cache = {}

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
            local gimmick_param_array = env_param:get_GimmickEvents()
            local gimmick_param_enum = util.get_array_enum(gimmick_param_array)

            while gimmick_param_enum:MoveNext() do
                local gimmick_param = gimmick_param_enum:get_Current()
                ---@cast gimmick_param app.user_data.ExFieldParam_LayoutData.cGimmickEventParam
                local event_struct = get_event_struct(cache, gimmick_param:get_GimmickEvent(), ex_id, lang)
                if not event_struct.map[stage] then
                    event_struct.map[stage] = event.map_data_ctor(stage)
                end

                for environ_type, _ in pairs(ace_data.enum.environ) do
                    if gimmick_param:getRandomWeight(stage, environ_type) then
                        table_util.insert_nested_value(event_struct.map[stage], { "area_by_env", environ_type }, area)
                    end
                end
                table.insert(event_struct.map[stage].area, area)
                table_util.set_nested_value(event_struct.map[stage], { "area_to_area_fixed", area }, area_fixed)
            end
        end
    end
    return cache_to_ret(cache)
end

---@param ex_field_param app.user_data.ExFieldParam
---@return GimmickData[]
function this.get_data(ex_field_param)
    local lang = util.get_language()

    return table_util.array_merge(
        get_npc_data(ex_field_param, lang),
        get_env_data(ex_field_param, lang),
        get_tokusan_data(ex_field_param, lang)
        -- ,get_ancient_coin_data(ex_field_param, lang)
    )
end

return this
