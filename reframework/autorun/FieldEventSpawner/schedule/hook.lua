---@class (exact) HookState
---@field flags HookFlags
---@field actions HookActions
---@field cheat {message: string, timer: Timer}

---@class (exact) HookFlags
---@field rebuild boolean
---@field clear boolean
---@field spawn boolean
---@field done boolean

---@class (exact) HookActions
---@field repop_gm CachedEvent?
---@field force_size integer?
---@field force_spoffer {pop_index_first: integer, pop_index_second: integer, rewards: EditedRewardData?}?
---@field force_area HookForceArea
---@field force_village_boost boolean

---@class (excat) HookForceArea
---@field once {pop_index: integer, area: integer}?
---@field ongoing table<integer, Timer>

local config = require("FieldEventSpawner.config.init")
local data_ace = require("FieldEventSpawner.data.ace.init")
local data_rt = require("FieldEventSpawner.data.runtime")
local event_cache = require("FieldEventSpawner.schedule.event_cache")
local game_data = require("FieldEventSpawner.util.game.data")
local m = require("FieldEventSpawner.util.ref.methods")
local s = require("FieldEventSpawner.util.ref.singletons")
local special_offer = require("FieldEventSpawner.events.special_offer")
local timer = require("FieldEventSpawner.util.misc.timer")
local util_game = require("FieldEventSpawner.util.game.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local rl = game_data.reverse_lookup

local this = {
    ---@type HookState
    state = {
        flags = {
            rebuild = false,
            clear = false,
            spawn = false,
            done = false,
        },
        actions = {
            force_area = { ongoing = {} },
            force_village_boost = false,
        },
        cheat = {
            message = "",
            timer = timer:new(config.display_cheat_timer),
        },
    },
}
local state = this.state
local flags = state.flags
local actions = state.actions

---@param gimmick_fixed app.ExDef.GIMMICK_EVENT_Fixed
---@param area integer
local function repop_gimmick(gimmick_fixed, area)
    local gimmick_event = game_data.fixed_to_enum("app.ExDef.GIMMICK_EVENT", gimmick_fixed)
    local gimmick_id = m.getGimmickID(gimmick_event)
    local gimmick_base_array = s.get("app.GimmickManager"):findGimmick_ID(gimmick_id)

    if not gimmick_base_array then
        return
    end

    local gimmick_base_enum = util_game.get_array_enum(gimmick_base_array)
    while gimmick_base_enum:MoveNext() do
        local gimmick_base = gimmick_base_enum:get_Current()
        ---@cast gimmick_base app.GimmickBaseApp
        local gimmick_context = gimmick_base:get_GimmickContext()
        local field_area = gimmick_context:get_FieldAreaInfo()
        if field_area:get_MapAreaNumSafety() == area then
            gimmick_base:changeState(rl(data_ace.enum.gimmick_state, "ENABLE"))
        end
    end
end

local function destroy_all_em()
    local chars = util_game.get_all_components("app.EnemyCharacter")
    local enum = util_game.get_array_enum(chars)
    while enum:MoveNext() do
        local char = enum:get_Current()
        ---@cast char app.EnemyCharacter
        local game_object = char:get_GameObject()
        game_object:destroy(game_object)
    end
end

---@param val boolean
function this.set_spawn_flag(val)
    flags.spawn = val
end

---@param val boolean
function this.set_clear_flag(val)
    flags.clear = val
end

---@param val boolean
function this.set_rebuild_flag(val)
    flags.rebuild = val
end

---@param event CachedEvent
function this.repop_gimmick(event)
    actions.repop_gm = event
end

---@param em_args MonsterSpawnEventArgs
function this.set_em_args(em_args)
    if em_args.spoffer then
        actions.force_spoffer = {
            pop_index_first = em_args.unique_index,
            pop_index_second = em_args.spoffer,
            rewards = em_args.spoffer_rewards,
        }
    end

    if em_args.area then
        actions.force_area.once = {
            area = em_args.area,
            pop_index = em_args.unique_index,
        }
    end

    if em_args.village_boost then
        actions.force_village_boost = true
    end

    if em_args.size then
        actions.force_size = em_args.size
    end
end

---@return string?
function this.get_cheat_message()
    if state.cheat.timer:active() then
        return state.cheat.message
    end
end

function this.spawn_check_post(retval)
    if flags.spawn then
        flags.done = true
        return sdk.to_ptr(true)
    end
end

function this.ex_director_update_pre(args)
    if flags.rebuild then
        local field_director = sdk.to_managed_object(args[2])
        ---@cast field_director app.cExFieldDirector
        field_director:rebuildExEventByStage(data_rt.state.stage, false)
        flags.rebuild = false
        event_cache.clear(data_rt.state.stage)
    elseif flags.clear then
        local field_director = sdk.to_managed_object(args[2])
        ---@cast field_director app.cExFieldDirector
        field_director:clearExEventByStage(data_rt.state.stage)
        -- sometimes when there is a lot of stuff on the map (like 80+ monsters), some monsters are not destroted properly
        -- events are gone but you are leftover with zombie monsters that will never leave
        destroy_all_em()
        local exanimalman = s.get("app.AnimalManager"):get_ExManager()
        -- same story as above
        exanimalman:unloadAllExEventSet()
        flags.clear = false
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
    if flags.done then
        flags.spawn = false
        flags.done = false
        actions.force_area.once = nil
        actions.force_spoffer = nil
        actions.force_size = nil
        actions.force_village_boost = false
        actions.repop_gm = nil
    end
end

function this.gimmick_execute_post(retval)
    if flags.spawn and actions.repop_gm then
        repop_gimmick(actions.repop_gm.id, actions.repop_gm.area)
    end
end

function this.on_game_save_post(retval)
    event_cache.overwrite_saved()
end

function this.on_game_load_post(retval)
    event_cache.overwrite_current()
end

function this.create_spoffer_pre(args)
    if flags.spawn and actions.force_spoffer then
        local spoffer_stage = sdk.to_managed_object(args[3])
        ---@cast spoffer_stage app.cExSpOfferFactory.cSpOfferByStage
        thread.get_hook_storage()["spoffer_stage"] = spoffer_stage
        local spoffer_array = spoffer_stage:get_SpOfferList()
        spoffer_array:Clear()
    end
end

function this.create_spoffer_post(retval)
    if flags.spawn and actions.force_spoffer and actions.force_spoffer.rewards then
        local spoffer_stage = thread.get_hook_storage()["spoffer_stage"]
        local spoffer_array = spoffer_stage:get_SpOfferList() --[[@as System.Array<app.cExSpOfferFactory.SpOfferInfo>]]
        if spoffer_array:get_Count() == 1 then
            local spoffer_info = spoffer_array:get_Item(0)
            ---@cast spoffer_info app.cExSpOfferFactory.SpOfferInfo
            special_offer.swap_rewards(spoffer_info, actions.force_spoffer.rewards)
        end
    end
end

function this.force_check_spoffer_pre(args)
    if flags.spawn and actions.force_spoffer then
        local spoffer_stage = sdk.to_managed_object(args[3])
        ---@cast spoffer_stage app.cExSpOfferFactory.cSpOfferByStage
        spoffer_stage:set_LotCreateSpOfferGameMinute(0)
        spoffer_stage:set_IsReserveCreateSpOffer(false)
    end
end

function this.force_lot_spoffer_post(retval)
    if flags.spawn and actions.force_spoffer then
        return sdk.to_ptr(true)
    end
end

function this.force_spoffer_array_post(retval)
    if flags.spawn and actions.force_spoffer then
        local _, schedule_timeline = data_rt.get_field_director()
        local pop_em_array = sdk.to_managed_object(retval)
        ---@cast pop_em_array System.Array<app.cExFieldEvent_PopEnemy>
        pop_em_array:Clear()
        local pop_em =
            schedule_timeline:findKeyFromUniqueIndex(actions.force_spoffer.pop_index_second)
        local main_pop_em =
            schedule_timeline:findKeyFromUniqueIndex(actions.force_spoffer.pop_index_first)
        pop_em_array:AddWithResize(main_pop_em)
        pop_em_array:AddWithResize(pop_em)
    end
end

function this.spoffer_village_boost_post(retval)
    if flags.spawn and actions.force_spoffer and actions.force_village_boost then
        return sdk.to_ptr(true)
    end
end

function this.allow_invalid_quests_pre(args)
    local config_mod = config.current.mod

    if config_mod.is_allow_invalid_quest then
        local ptr = sdk.to_int64(args[2])
        fes_util.write_qword(ptr, 0)

        return sdk.PreHookResult.SKIP_ORIGINAL
    end

    if config_mod.display_cheat_errors then
        thread.get_hook_storage()["bit"] = args[2]
    end
end

function this.allow_invalid_quests_post(retval)
    local config_mod = config.current.mod

    if config_mod.is_allow_invalid_quest then
        return sdk.to_ptr(true)
    end

    if config_mod.display_cheat_errors then
        ---@diagnostic disable-next-line: param-type-mismatch
        local bit = util_ref.deref_ptr(thread.get_hook_storage()["bit"])

        if bit ~= 0 and not util_ref.to_bool(retval) then
            local keys = util_table.sort(util_table.keys(data_ace.enum.incorrect_status))
            ---@type string[]
            local errors = {}
            for i = 0, #keys do
                local status = keys[i]
                local status_bit = m.getIncorrectStatusBit(status)
                if bit & status_bit == status_bit then
                    table.insert(errors, data_ace.enum.incorrect_status[status])
                end
            end

            state.cheat.timer:restart()
            state.cheat.message = table.concat(errors, "\n")
        else
            state.cheat.timer:abort()
        end
    end
end

function this.force_pop_many_spawn_pre(args)
    if flags.spawn then
        local storage = thread.get_hook_storage() --[[@as table]]
        storage["out"] = args[3]
        storage["in"] = args[4]
    end
end

--FIXME: Forcing monster that we actually want to spawn, this is Lagiacrus only,
-- for whatever reason he has only one EmPopParam, POP_MANY_2, in which he has 75% chance to spawn.....
-- not sure if its by design or an oversight
function this.force_pop_many_spawn_post(retval)
    if this.state.flags.spawn then
        local storage = thread.get_hook_storage() --[[@as table]]
        local out_pop_em = sdk.to_managed_object(util_ref.deref_ptr(storage["out"])) --[[@as app.cExFieldEvent_PopEnemy?]]
        local in_pop_em = sdk.to_managed_object(storage["in"]) --[[@as app.cExFieldEvent_PopEnemy]]

        if out_pop_em then
            out_pop_em:call(
                "importData(app.cExFieldScheduleExportData.cEventData)",
                in_pop_em:exportData()
            )
        end
    end
end

function this.force_pop_many_reward_pre(args)
    if flags.spawn then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end

function this.force_context_area_pre(args)
    if flags.spawn and actions.force_area.once then
        local context_args = sdk.to_managed_object(args[3]) --[[@as app.cContextCreateArg_Enemy]]
        context_args:set_AreaNo(actions.force_area.once.area)
        actions.force_area.ongoing[actions.force_area.once.pop_index] =
            timer:new(config.force_area_timer, nil, true)
    end
end

function this.stop_em_combat_pre(args)
    if not util_table.empty(actions.force_area.ongoing) then
        local storage = thread.get_hook_storage() --[[@as table]]
        storage["ctx_holder1"] = args[3]
        storage["ctx_holder2"] = args[6]
    end
end

function this.stop_em_combat_post(retval)
    if not util_table.empty(actions.force_area.ongoing) then
        for index, t in pairs(actions.force_area.ongoing) do
            if t:finished() then
                actions.force_area.ongoing[index] = nil
            end
        end

        local storage = thread.get_hook_storage() --[[@as table]]
        local ctx_holder1 = sdk.to_managed_object(storage["ctx_holder1"]) --[[@as app.cEnemyContextHolder?]]
        local ctx_holder2 = sdk.to_managed_object(storage["ctx_holder2"]) --[[@as app.cEnemyContextHolder?]]
        if not util_table.empty(actions.force_area.ongoing) and ctx_holder1 and ctx_holder2 then
            local _, schedule_timeline = data_rt.get_field_director()
            local ctx1 = ctx_holder1:get_Em()
            local ctx2 = ctx_holder2:get_Em()

            for index, _ in pairs(actions.force_area.ongoing) do
                local pop_em = schedule_timeline:findKeyFromUniqueIndex(index) --[[@as app.cExFieldEvent_PopEnemy]]
                if not pop_em then
                    actions.force_area.ongoing[index] = nil
                    goto continue
                end

                local pop_em_ctx_holder = pop_em:call("findEm()") --[[@as app.cEnemyContextHolder]]

                if not pop_em_ctx_holder then
                    actions.force_area.ongoing[index] = nil
                    goto continue
                end

                local pop_em_ctx = pop_em_ctx_holder:get_Em()

                if pop_em_ctx.Area:get_IsTargetArrival() then
                    actions.force_area.ongoing[index] = nil
                    goto continue
                end

                if ctx1 == pop_em_ctx or ctx2 == pop_em_ctx then
                    return sdk.to_ptr(false)
                end

                ::continue::
            end
        end
    end
end

function this.force_em_size_post(retval)
    --FIXME: for whatever reason game does not call lotteryModelRandomSize for the last member of the swarm
    -- when leader is an alpha...
    if flags.spawn and actions.force_size then
        return sdk.to_ptr(actions.force_size)
    end
end

return this
