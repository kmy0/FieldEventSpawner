local cache = require("FieldEventSpawner.schedule.cache")
local config = require("FieldEventSpawner.config")
local data = require("FieldEventSpawner.data")
local special_offer = require("FieldEventSpawner.events.special_offer")
local util = require("FieldEventSpawner.util")

local ace = data.ace
local rt = data.runtime
local rl = data.util.reverse_lookup

local this = {
    state = {
        rebuild_flag = false,
        clear_flag = false,
        force_spawn_flag = false,
        ---@type CachedEvent
        repop_gm = nil,
        ---@type MonsterSpawnEventArgs
        em_args = nil,
        updated = false,
    },
}

---@param gimmick_fixed app.ExDef.GIMMICK_EVENT_Fixed
---@param area integer
local function repop_gimmick(gimmick_fixed, area)
    local gimmick_event = util.get_gimmick_event_id(gimmick_fixed)
    local gimmick_id = util.getGimmickID:call(nil, gimmick_event)
    local gimmick_base_array = rt.get_gimman():findGimmick_ID(gimmick_id)

    if not gimmick_base_array then
        return
    end

    local gimmick_base_enum = util.get_array_enum(gimmick_base_array)
    while gimmick_base_enum:MoveNext() do
        local gimmick_base = gimmick_base_enum:get_Current()
        ---@cast gimmick_base app.GimmickBaseApp
        local gimmick_context = gimmick_base:get_GimmickContext()
        local field_area = gimmick_context:get_FieldAreaInfo()
        if field_area:get_MapAreaNumSafety() == area then
            gimmick_base:changeState(rl(ace.enum.gimmick_state, "ENABLE"))
        end
    end
end

local function destroy_all_em()
    local chars = util.get_all_t("app.EnemyCharacter")
    local enum = util.get_array_enum(chars)
    while enum:MoveNext() do
        local char = enum:get_Current()
        ---@cast char app.EnemyCharacter
        local game_object = char:get_GameObject()
        game_object:destroy(game_object)
    end
end

function this.spawn_check_post(retval)
    if this.state.force_spawn_flag then
        return sdk.to_ptr(true)
    end
    return retval
end

function this.force_em_area_pre(args)
    if
        this.state.force_spawn_flag
        and this.state.em_args
        and this.state.em_args.force_area
        and sdk.to_int64(args[3]) == this.state.em_args.id
    then
        thread.get_hook_storage()["force_area"] = true
    end
end

function this.force_em_area_post(retval)
    if this.state.force_spawn_flag and this.state.em_args and thread.get_hook_storage()["force_area"] then
        return
    end
    return retval
end

function this.ex_director_update_pre(args)
    if this.state.rebuild_flag then
        local field_director = sdk.to_managed_object(args[2])
        ---@cast field_director app.cExFieldDirector
        field_director:rebuildExEventByStage(rt.state.stage, false)
        this.state.rebuild_flag = false
        cache.clear(rt.state.stage)
    elseif this.state.clear_flag then
        local field_director = sdk.to_managed_object(args[2])
        ---@cast field_director app.cExFieldDirector
        field_director:clearExEventByStage(rt.state.stage)
        -- sometimes when there is a lot of stuff on the map (like 80+ monsters), some monsters are not destroted properly
        -- events are gone but you are leftover with zombie monsters that will never leave
        destroy_all_em()
        local exanimalman = rt.get_animalman():get_ExManager()
        -- same story as above
        exanimalman:unloadAllExEventSet()
        this.state.clear_flag = false
    end

    if this.state.force_spawn_flag then
        this.state.updated = true
    end
end

function this.ex_director_save_sched_pre(args)
    local field_director = sdk.to_managed_object(args[2])
    ---@cast field_director app.cExFieldDirector
    if field_director:get_IsRunBackGround() then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end

function this.ex_director_update_post(retval)
    if this.state.updated then
        this.state.force_spawn_flag = false
        this.state.em_args = nil
        this.state.updated = false
    end
    return retval
end

function this.gimmick_execute_post(retval)
    if this.state.force_spawn_flag and this.state.repop_gm then
        repop_gimmick(this.state.repop_gm.id, this.state.repop_gm.area)
        this.state.repop_gm = nil
    end
    return retval
end

function this.on_game_save_post(retval)
    cache.overwrite_saved()
    return retval
end

function this.on_game_load_post(retval)
    cache.overwrite_current()
    return retval
end

function this.create_spoffer_pre(args)
    if this.state.force_spawn_flag and this.state.em_args and this.state.em_args.spoffer then
        local spoffer_stage = sdk.to_managed_object(args[3])
        ---@cast spoffer_stage app.cExSpOfferFactory.cSpOfferByStage
        thread.get_hook_storage()["spoffer_stage"] = spoffer_stage
        local spoffer_array = spoffer_stage:get_SpOfferList()
        spoffer_array:Clear()
    end
end

function this.create_spoffer_post(retval)
    if
        this.state.force_spawn_flag
        and this.state.em_args
        and this.state.em_args.spoffer
        and this.state.em_args.spoffer_rewards
    then
        local spoffer_stage = thread.get_hook_storage()["spoffer_stage"]
        local spoffer_array = spoffer_stage:get_SpOfferList() --[[@as System.Array<app.cExSpOfferFactory.SpOfferInfo>]]
        if spoffer_array:get_Count() == 1 then
            local spoffer_info = spoffer_array:get_Item(0)
            ---@cast spoffer_info app.cExSpOfferFactory.SpOfferInfo
            special_offer.swap_rewards(spoffer_info, this.state.em_args.spoffer_rewards)
        end
    end
    return retval
end

function this.force_check_spoffer_pre(args)
    if this.state.force_spawn_flag and this.state.em_args and this.state.em_args.spoffer then
        local spoffer_stage = sdk.to_managed_object(args[3])
        ---@cast spoffer_stage app.cExSpOfferFactory.cSpOfferByStage
        spoffer_stage:set_LotCreateSpOfferGameMinute(0)
        spoffer_stage:set_IsReserveCreateSpOffer(false)
    end
end

function this.force_lot_spoffer_post(retval)
    if this.state.force_spawn_flag and this.state.em_args and this.state.em_args.spoffer then
        return sdk.to_ptr(true)
    end
    return retval
end

function this.force_spoffer_array_post(retval)
    if this.state.force_spawn_flag and this.state.em_args and this.state.em_args.spoffer then
        local _, schedule_timeline = rt.get_field_director()
        local pop_em_array = sdk.to_managed_object(retval)
        ---@cast pop_em_array System.Array<app.cExFieldEvent_PopEnemy>
        pop_em_array:Clear()
        local pop_em = schedule_timeline:findKeyFromUniqueIndex(this.state.em_args.spoffer)
        local main_pop_em = schedule_timeline:findKeyFromUniqueIndex(this.state.em_args.unique_index)
        pop_em_array:AddWithResize(main_pop_em)
        pop_em_array:AddWithResize(pop_em)
    end
    return retval
end

function this.spoffer_village_boost_post(retval)
    if
        this.state.force_spawn_flag
        and this.state.em_args
        and this.state.em_args.spoffer
        and this.state.em_args.village_boost
    then
        return sdk.to_ptr(true)
    end
    return retval
end

function this.allow_invalid_quests_pre(args)
    if config.current.mod.is_allow_invalid_quest then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end

function this.allow_invalid_quests_post(retval)
    if config.current.mod.is_allow_invalid_quest then
        return sdk.to_ptr(true)
    end

    return retval
end

function this.force_pop_many_spawn_pre(args)
    if this.state.force_spawn_flag then
        thread.get_hook_storage()["out"] = args[3]
        thread.get_hook_storage()["in"] = args[4]
    end
end

--FIXME: Forcing monster that we actually want to spawn, this is Lagiacrus only,
-- for whatever reason he has only one EmPopParam, POP_MANY_2, in which he has 75% chance to spawn.....
-- not sure if its by design or an oversight
function this.force_pop_many_spawn_post(retval)
    if this.state.force_spawn_flag then
        local out_pop_em = sdk.to_managed_object(util.deref_ptr(thread.get_hook_storage()["out"])) --[[@as app.cExFieldEvent_PopEnemy?]]
        local in_pop_em = sdk.to_managed_object(thread.get_hook_storage()["in"]) --[[@as app.cExFieldEvent_PopEnemy]]

        if out_pop_em then
            out_pop_em._FreeValue0 = in_pop_em._FreeValue0
            out_pop_em._FreeValue1 = in_pop_em._FreeValue1
            out_pop_em._FreeValue2 = in_pop_em._FreeValue2
            out_pop_em._FreeValue3 = in_pop_em._FreeValue3
            out_pop_em._FreeValue4 = in_pop_em._FreeValue4
            out_pop_em._FreeValue5 = in_pop_em._FreeValue5
            out_pop_em._FreeMiniValue0 = in_pop_em._FreeMiniValue0
            out_pop_em._FreeMiniValue1 = in_pop_em._FreeMiniValue1
            out_pop_em._FreeMiniValue2 = in_pop_em._FreeMiniValue2
            out_pop_em._FreeMiniValue3 = in_pop_em._FreeMiniValue3
            out_pop_em._FreeMiniValue4 = in_pop_em._FreeMiniValue4
            out_pop_em._FreeMiniValue5 = in_pop_em._FreeMiniValue5
            out_pop_em._FreeMiniValue6 = in_pop_em._FreeMiniValue6
            out_pop_em._UniqueIndex = in_pop_em._UniqueIndex
        end
    end

    return retval
end

return this
