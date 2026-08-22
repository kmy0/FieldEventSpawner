---@class (exact) HookState
---@field flags HookFlags
---@field actions HookActions
---@field cheat {message: string, timer: Timer}
---@field em_exit {check: Timer, ems: {[app.cExFieldEvent_PopEnemy]: Timer}}

---@class (exact) HookFlags
---@field rebuild boolean
---@field clear boolean
---@field spawn boolean
---@field done boolean
---@field spoffer boolean
---@field ex_instant boolean
---@field reward_max boolean

---@class (exact) HookActions
---@field repop_gm CachedEvent?
---@field force_size integer?
---@field force_spoffer {pop_index_first: integer, pop_index_second: integer, rewards: EditedRewardData?}?
---@field force_area HookForceArea
---@field force_village_boost boolean
---@field force_spoffer_swarm {rewards: EditedRewardData?, pop_index: integer[], request: boolean}?

---@class (excat) HookForceArea
---@field once {pop_index: integer, area: integer}?
---@field ongoing table<integer, Timer>

local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
local e = require("FieldEventSpawner.util.game.enum")
local event_cache = require("FieldEventSpawner.schedule.event_cache")
local helpers = require("FieldEventSpawner.data.helpers")
local m = require("FieldEventSpawner.util.ref.methods")
local mod = require("FieldEventSpawner.data.mod")
local s = require("FieldEventSpawner.util.ref.singletons")
local special_offer = require("FieldEventSpawner.events.special_offer")
local timer = require("FieldEventSpawner.util.misc.timer")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {
    ---@type HookState
    state = {
        flags = {
            rebuild = false,
            clear = false,
            spawn = false,
            done = false,
            spoffer = false,
            ex_instant = false,
            reward_max = false,
        },
        actions = {
            force_area = { ongoing = {} },
            force_village_boost = false,
        },
        cheat = {
            message = "",
            timer = timer:new(config.display_cheat_timer),
        },
        em_exit = {
            check = timer:new(10, { auto_update = true }),
            ems = {},
        },
    },
}
local state = this.state
local flags = state.flags
local actions = state.actions
local reward = ace.reward

---@param gimmick_fixed app.ExDef.GIMMICK_EVENT_Fixed
---@param area integer
local function repop_gimmick(gimmick_fixed, area)
    local gimmick_event = e.to_enum("app.ExDef.GIMMICK_EVENT", gimmick_fixed)
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
            gimmick_base:changeState(e.get("ace.GimmickDef.BASE_STATE").ENABLE)
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

---@param retval integer
---@return {
--- em_infos: app.ExQuestRewardUtil.EM_INFO_FOR_REWARD[],
--- is_yummy: boolean,
--- is_spoffer: boolean,
--- item: app.savedata.cItemWork,
--- }?
local function get_extra_reward_args(retval)
    local args = util_ref.thread_get()
    if not args then
        return
    end

    local limited_array = sdk.to_managed_object(args[3]) --[[@as ace.cLimitedArray<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>]]
    local item = sdk.to_managed_object(retval) --[[@as app.savedata.cItemWork]]
    return {
        em_infos = util_game.system_array_to_lua(limited_array._Array),
        is_yummy = util_ref.to_bool(args[7]),
        is_spoffer = util_ref.to_bool(args[8]),
        item = item,
    }
end

---@param retval integer
---@param reward_type RewardType
local function make_num_reward_max_extra(retval, reward_type)
    local args = get_extra_reward_args(retval)
    if not args then
        return
    end

    reward.item.make_item_num_max(
        reward_type,
        args.item,
        args.em_infos,
        args.is_yummy,
        args.is_spoffer
    )
end

---@param val boolean
function this.set_spawn_flag(val)
    flags.spawn = val
end

---@param val boolean
function this.set_ex_instant_flag(val)
    flags.ex_instant = val
end

---@param val boolean
function this.set_clear_flag(val)
    flags.clear = val
end

---@param val boolean
function this.set_rebuild_flag(val)
    flags.rebuild = val
end

---@param val boolean
function this.set_reward_max_flag(val)
    flags.reward_max = val
end

---@param event CachedEvent
function this.repop_gimmick(event)
    actions.repop_gm = event
end

---@param em_args MonsterSpawnEventArgs
function this.set_em_args(em_args)
    if em_args.spoffer_unique_index then
        actions.force_spoffer = {
            pop_index_first = em_args.unique_index,
            pop_index_second = em_args.spoffer_unique_index,
            rewards = em_args.spoffer_rewards,
        }
    end

    if em_args.area then
        actions.force_area.once = {
            area = em_args.area,
            pop_index = em_args.unique_index,
        }
    end

    if em_args.is_spoffer_village_boost then
        actions.force_village_boost = true
    end

    if em_args.size then
        actions.force_size = em_args.size
    end

    if em_args.spoffer_swarm then
        actions.force_spoffer_swarm = {
            rewards = em_args.spoffer_rewards,
            pop_index = em_args.swarm_indexes,
            request = true,
        }
    end
end

---@return string?
function this.get_cheat_message()
    if state.cheat.timer:active() then
        return state.cheat.message
    end
end

function this.spawn_check_post(_)
    if flags.spawn then
        flags.done = true
        return true
    end
end

function this.ex_director_update_pre(args)
    if flags.rebuild then
        local field_director = sdk.to_managed_object(args[2])
        ---@cast field_director app.cExFieldDirector
        field_director:rebuildExEventByStage(mod.state.stage, false)
        flags.rebuild = false
        event_cache.clear(mod.state.stage)
    elseif flags.clear then
        local field_director = sdk.to_managed_object(args[2])
        ---@cast field_director app.cExFieldDirector
        field_director:clearExEventByStage(mod.state.stage)
        -- sometimes when there is a lot of stuff on the map (like 80+ monsters), some monsters are not destroted properly
        -- events are gone but you are leftover with zombie monsters that will never leave
        destroy_all_em()
        local exanimalman = s.get("app.AnimalManager"):get_ExManager()
        -- same story as above
        exanimalman:unloadAllExEventSet()
        flags.clear = false
    elseif actions.force_spoffer_swarm and actions.force_spoffer_swarm.request then
        local field_director, schedule_timeline = mod.get_field_director()
        local pop_em = schedule_timeline:findKeyFromUniqueIndex(
            util_table.pick_random_value(actions.force_spoffer_swarm.pop_index)
        ) --[[@as app.cExFieldEvent_PopEnemy]]
        local spoffer_fac = field_director._SpOfferFactory
        local spoffer_more_fac = spoffer_fac._MoreTargetSpOfferFactory

        spoffer_more_fac:requestSwarmSpOffer(mod.state.stage, pop_em)
        actions.force_spoffer_swarm.request = false
    end
end

function this.ex_director_save_sched_pre(args)
    local field_director = sdk.to_managed_object(args[2])
    ---@cast field_director app.cExFieldDirector
    if field_director:get_IsRunBackGround() then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end

function this.ex_director_update_post(_)
    if flags.done then
        flags.spawn = false
        flags.done = false
        flags.reward_max = false
        actions.force_area.once = nil
        actions.force_spoffer = nil
        actions.force_size = nil
        actions.force_village_boost = false
        actions.repop_gm = nil
        actions.force_spoffer_swarm = nil
    end

    if state.em_exit.check:active() or not mod.initialized then
        return
    end

    -- monsters that cannot spawn normally on the current map linger forever after their event ends
    local _, schedule_timeline = mod.get_field_director()
    local events = schedule_timeline._KeyList

    util_game.do_something(events, function(_, _, event)
        if util_ref.is_a(event, "app.cExFieldEvent_PopEnemy") then
            ---@cast event app.cExFieldEvent_PopEnemy

            if
                helpers.is_invalid_em(event)
                and not state.em_exit.ems[event]
                and event:get_IsRequestedExit()
            then
                state.em_exit.ems[event] = timer:new(config.max_em_exit_time, {
                    callback = function()
                        util_misc.try(function()
                            local ctx_holder = event:call("findEm()") --[[@as app.cEnemyContextHolder]]
                            if ctx_holder and not ctx_holder:get_IsHealthZero() then
                                local game_object = ctx_holder:get_Object()

                                if game_object then
                                    game_object:destroy(game_object)
                                end
                            end
                        end)

                        state.em_exit.ems[event] = nil
                    end,
                    auto_start = true,
                    auto_update = true,
                })
            end
        end
    end)

    state.em_exit.check:restart()
end

function this.gimmick_execute_post(_)
    if flags.spawn and actions.repop_gm then
        repop_gimmick(actions.repop_gm.id, actions.repop_gm.area)
    end
end

function this.on_game_save_post(_)
    event_cache.overwrite_saved()
end

function this.on_game_load_post(_)
    event_cache.overwrite_current()
end

function this.create_spoffer_pre(args)
    flags.spoffer = true

    if flags.spawn and actions.force_spoffer then
        local spoffer_stage = sdk.to_managed_object(args[3]) --[[@as app.cExSpOfferFactory.cSpOfferByStage]]
        local spoffer_array = spoffer_stage:get_SpOfferList()
        spoffer_array:Clear()
    end
end

function this.create_spoffer_post(_)
    if flags.spawn and actions.force_spoffer then
        if actions.force_spoffer.rewards then
            special_offer.swap_rewards(actions.force_spoffer.rewards)
        end

        if config.current.mod.display_cheat_errors then
            helpers.check_ex_quest_spoffer()
        end
    end

    flags.spoffer = false
end

function this.create_spoffer_swarm_post(_)
    if flags.spawn and actions.force_spoffer_swarm then
        if actions.force_spoffer_swarm.rewards then
            special_offer.swap_rewards(actions.force_spoffer_swarm.rewards)
        end

        if config.current.mod.display_cheat_errors then
            helpers.check_ex_quest_spoffer_swarm()
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

function this.force_lot_spoffer_post(_)
    if flags.spawn and actions.force_spoffer then
        return true
    end
end

function this.force_lot_spoffer_swarm_post(_)
    if flags.spawn and actions.force_spoffer_swarm then
        return true
    end
end

function this.exclusive_em_check_post(_)
    local config_mod = config.current.mod
    if ace.initialized and config_mod.is_allow_exclusive_em then
        return false
    end
end

function this.force_spoffer_array_post(retval)
    if flags.spawn and actions.force_spoffer then
        local _, schedule_timeline = mod.get_field_director()
        local pop_em_array = sdk.to_managed_object(retval)
        ---@cast pop_em_array System.Array<app.cExFieldEvent_PopEnemy>
        pop_em_array:Clear()
        local pop_em =
            schedule_timeline:findKeyFromUniqueIndex(actions.force_spoffer.pop_index_second) --[[@as app.cExFieldEvent_PopEnemy]]
        local main_pop_em =
            schedule_timeline:findKeyFromUniqueIndex(actions.force_spoffer.pop_index_first) --[[@as app.cExFieldEvent_PopEnemy]]
        pop_em_array:AddWithResize(main_pop_em)
        pop_em_array:AddWithResize(pop_em)
    end
end

function this.filter_spoffer_array_post(retval)
    if flags.spoffer and not actions.force_spoffer then
        local ret = sdk.to_managed_object(retval) --[==[@as System.Array<app.cExFieldEvent_PopEnemy>]==]
        local filtered = {}

        util_game.do_something(ret, function(_, _, em)
            if not helpers.is_invalid_em(em) then
                table.insert(filtered, em)
            end
        end)

        ret:Clear()
        for _, em in pairs(filtered) do
            ret:AddWithResize(em)
        end
    end
end

function this.spoffer_village_boost_post(_)
    if flags.spawn and actions.force_spoffer and actions.force_village_boost then
        return true
    end
end

function this.allow_invalid_quests_pre(args)
    local config_mod = config.current.mod

    if config_mod.is_allow_invalid_quest then
        local ptr = util_ref.to_address(args[2])
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
        return true
    end

    if config_mod.display_cheat_errors then
        ---@diagnostic disable-next-line: param-type-mismatch
        local bit = util_ref.deref_ptr(thread.get_hook_storage()["bit"])

        if bit ~= 0 and not util_ref.to_bool(retval) then
            local keys = util_table.sort(
                util_table.keys(e.get("app.QuestCheckUtil.INCORRECT_STATUS").enum_to_field)
            )
            ---@type string[]
            local errors = {}
            for i = 0, #keys do
                local status = keys[i]
                local status_bit = m.getIncorrectStatusBit(status)
                if bit & status_bit == status_bit then
                    table.insert(errors, e.get("app.QuestCheckUtil.INCORRECT_STATUS")[status])
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
        util_ref.thread_store(args)
    end
end

--FIXME: Forcing monster that we actually want to spawn, this is Lagiacrus only,
-- for whatever reason he has only one EmPopParam, POP_MANY_2, in which he has 75% chance to spawn.....
-- not sure if its by design or an oversight
function this.force_pop_many_spawn_post(_)
    if flags.spawn then
        local args = util_ref.thread_get()
        local out_pop_em = sdk.to_managed_object(util_ref.deref_ptr(args[3])) --[[@as app.cExFieldEvent_PopEnemy?]]
        local in_pop_em = sdk.to_managed_object(args[4]) --[[@as app.cExFieldEvent_PopEnemy]]

        if out_pop_em then
            out_pop_em:call(
                "importData(app.cExFieldScheduleExportData.cEventData)",
                in_pop_em:exportData()
            )
        end
    end
end

function this.force_pop_many_reward_pre(_)
    if flags.spawn then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end

function this.force_context_area_pre(args)
    if flags.spawn and actions.force_area.once then
        local context_args = sdk.to_managed_object(args[3]) --[[@as app.cContextCreateArg_Enemy]]
        context_args:set_AreaNo(actions.force_area.once.area)
        actions.force_area.ongoing[actions.force_area.once.pop_index] =
            timer:new(config.force_area_timer, { auto_start = true })
    end
end

function this.stop_em_combat_pre(args)
    if not util_table.empty(actions.force_area.ongoing) then
        util_ref.thread_store(args)
    end
end

function this.stop_em_combat_post(_)
    if not util_table.empty(actions.force_area.ongoing) then
        for index, t in pairs(actions.force_area.ongoing) do
            if t:finished() then
                actions.force_area.ongoing[index] = nil
            end
        end

        local args = util_ref.thread_get()
        local ctx_holder1 = sdk.to_managed_object(args[3]) --[[@as app.cEnemyContextHolder?]]
        local ctx_holder2 = sdk.to_managed_object(args[6]) --[[@as app.cEnemyContextHolder?]]
        if not util_table.empty(actions.force_area.ongoing) and ctx_holder1 and ctx_holder2 then
            local _, schedule_timeline = mod.get_field_director()
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
                    return false
                end

                ::continue::
            end
        end
    end
end

function this.force_em_size_post(_)
    if flags.spawn and actions.force_size then
        return actions.force_size
    end
end

function this.save_spoffer_em_sizes_post(_)
    if not config.current.mod.is_spoffer_size_save then
        return
    end

    local quest_param = helpers.get_last_keep_quest()
    local ctx_save_keep = quest_param:get_ContextSaveParam()
    if ctx_save_keep.Boss_SavedCount > 0 or quest_param.StageType ~= mod.state.stage then
        return
    end

    local _, schedule_timeline = mod.get_field_director()
    local boss_ctx_save = ctx_save_keep:get_Boss_ContextSaveParam()
    local ctx_save_helper = util_ref.ctor("app.cBossContextSaver_KeepQuest")
    local ex_field = quest_param:get_ExField()
    local index = 0
    local index_max = boss_ctx_save:get_Count() - 1
    ---@type table<integer, boolean>
    local targets = {}
    ---@type table<integer, app.cEnemyContextHolder>
    local ctxs = {}

    util_game.do_something(quest_param.EmSet_UniqueIndex, function(_, _, value)
        if value ~= -1 then
            targets[value] = true
        end
    end)

    util_game.do_something(ex_field:get_EventList(), function(_, _, value)
        if value.EventType ~= e.get("app.EX_FIELD_EVENT_TYPE").POP_EM then
            return
        end

        local pop_em = schedule_timeline:findKeyFromUniqueIndex(value.UniqueIndex) --[[@as app.cExFieldEvent_PopEnemy]]
        local ctx_holder = pop_em:call("findEm()") --[[@as app.cEnemyContextHolder?]]
        if not ctx_holder then
            return
        end

        ctxs[value.UniqueIndex] = ctx_holder
    end)

    local keys = util_table.keys(ctxs)
    table.sort(keys, function(a, b)
        if targets[a] and not targets[b] then
            return true
        elseif targets[b] and not targets[a] then
            return false
        end

        return false
    end)

    for _, unique_index in ipairs(keys) do
        local ctx_holder = ctxs[unique_index]

        local ctx_keep = m.createBossContextSaveParam_Keep()
        ctx_keep:add_ref_permanent()
        ctx_save_helper:save(ctx_holder, ctx_keep:get_address())

        boss_ctx_save:set_Item(index, ctx_keep)
        index = index + 1

        if index > index_max then
            break
        end
    end

    ctx_save_keep.Boss_SavedCount = boss_ctx_save:get_Count()
end

function this.pause_schedule_pre(args)
    if config.current.mod.pause_schedule and config.gui.current.gui.main.is_opened then
        args[7] = sdk.float_to_ptr(0.0)
    end
end

function this.get_keep_quest_post(retval)
    -- invalid low rank difficulties
    if util_ref.to_int(retval) == 99999999 then
        return 700
    end
end

function this.get_accept_hr_post(retval)
    -- invalid tempered and arch-tempered difficulties
    if util_ref.to_int(retval) == 0 then
        return 30
    end
end

function this.is_enable_execute_instant_post(_)
    -- battlefield_slay events with invalid difficulty display Quest Creation Unavailable message instead of rewards
    if flags.ex_instant then
        flags.ex_instant = false
        return true
    end
end

function this.reward_max_get_args_pre(args)
    if flags.reward_max then
        util_ref.thread_store(args)
    end
end

function this.reward_max_artian_post(retval)
    make_num_reward_max_extra(retval, reward.item.enum.Artian)
end

function this.reward_max_amulet_post(retval)
    make_num_reward_max_extra(retval, reward.item.enum.Amulet)
end

function this.reward_max_skillgem_post(retval)
    make_num_reward_max_extra(retval, reward.item.enum.SkillGem)
end

function this.reward_ax_emreward_post(_)
    local args = util_ref.thread_get()
    if not args then
        return
    end

    local items = sdk.to_managed_object(util_ref.deref_ptr(args[2])) --[[@as System.Array<app.savedata.cItemWork>]]
    local em_infos = { sdk.to_valuetype(args[6], "app.ExQuestRewardUtil.EM_INFO_FOR_REWARD") }
    local is_yummy = util_ref.to_bool(args[7])
    local is_spoffer = util_ref.to_bool(args[8])

    util_game.do_something(items, function(_, _, item)
        reward.item.make_item_num_max(
            reward.item.enum.Monster,
            item,
            em_infos,
            is_yummy,
            is_spoffer
        )
    end)
end

function this.reward_max_slot_post(_)
    local args = util_ref.thread_get()
    if not args then
        return
    end

    local limited_array = sdk.to_managed_object(args[3]) --[[@as ace.cLimitedArray<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>]]
    local em_infos = util_game.system_array_to_lua(limited_array._Array)
    local is_yummy = util_ref.to_bool(args[5])
    local is_spoffer = util_ref.to_bool(args[6])
    local rank = util_ref.to_byte(args[7])
    local ret = reward.slot.get_slot_num_max(em_infos, rank, is_yummy, is_spoffer)

    if ret > 0 then
        return ret
    end
end

function this.random_max_slot_spoffer_swarm_post(_)
    local args = util_ref.thread_get()
    if not args then
        return
    end

    local slot_table = sdk.to_managed_object(args[2]) --[[@as app.user_data.ExQuestRewardSetting.cRewardSlotTable]]
    local ptr = util_ref.to_address(args[3])
    local num = reward.slot.get_slot_num_max_spoffer_swarm(slot_table)

    fes_util.write_byte(ptr, num)
    return true
end

function this.reward_max_reward_spoffer_swarm_post(_)
    local args = util_ref.thread_get()
    if not args then
        return
    end

    local reward_table = sdk.to_managed_object(args[2]) --[[@as app.user_data.ExQuestRewardSetting.cRewardItemTable]]
    local limited_array = sdk.to_managed_object(util_ref.deref_ptr(args[3])) --[[@as ace.cLimitedArray<app.savedata.cItemWork>]]
    reward.item.make_item_num_max_spoffer_swarm(reward_table, limited_array._Array)
end

function this.force_spoffer_swarm_em_post(retval)
    if flags.spawn and actions.force_spoffer_swarm and actions.force_spoffer_swarm.pop_index then
        ---@type app.cExFieldEvent_PopEnemy[]
        local pop_ems = {}
        local array = sdk.to_managed_object(retval) --[[@as System.Array<app.cExFieldEvent_PopEnemy>]]

        util_game.do_something(array, function(_, _, value)
            if util_table.contains(actions.force_spoffer_swarm.pop_index, value._UniqueIndex) then
                table.insert(pop_ems, value)
            end
        end)

        array:Clear()

        for _, pop_em in pairs(pop_ems) do
            array:AddWithResize(pop_em)
        end
    end
end
--TODO: flag spoffer more and run those hooks only when its spawning
-- app.cExMoreTargetSpOfferFactory.tryCreateSwarmSpOfferProc(app.cExFieldEvent_SpOfferMore, app.cExFieldEvent_SpOfferMore_Target, ace.cLimitedArray`1<app.cExFieldEvent_EmReward>, ace.cLimitedArray`1<app.cExFieldEvent_PopEnemy>, ace.cLimitedArray`1<app.savedata.cItemWork>, System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Int32, app.EnemyDef.ID, app.FieldDef.STAGE)
m.hook(
    "app.user_data.ExFieldParam_LayoutData.getLegendaryPopParam(app.EnemyDef.ID, app.user_data.ExFieldParam_LayoutData.cEmPopParam_Legendary[])",
    function(args)
        -- util_ref.thread_store(args)
        -- print(util_ref.to_byte(args[3]))
        args[3] = sdk.to_ptr(16)
    end,
    function(retval)
        -- if flags.spawn then
        --     local args = util_ref.thread_get()
        --     local o = sdk.to_managed_object(args[2])
        --     return sdk.to_ptr(o._SwarmPopParamsByHR)
        -- end
    end
)
m.hook("app.user_data.ExFieldParam.getFieldLayout(app.FieldDef.STAGE)", function(args)
    args[3] = sdk.to_ptr(0)
end)
m.hook(
    "app.user_data.ExQuestRewardSetting.tryGetSwarmSpOfferRewardByEm(app.user_data.ExQuestRewardSetting.cSwarmSpOfferRewardByEm, app.EnemyDef.ID)",
    function(args)
        print(1)
        args[4] = sdk.to_ptr(16)
    end
)

m.hook(
    "app.user_data.ExQuestRewardSetting.cRewardItemTable.tryGetWeightedRewardItem(ace.cLimitedArray`1<app.savedata.cItemWork>, ace.cLimitedArray`1<System.Boolean>, System.Byte[], ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, System.Byte)",
    nil,
    function(retval)
        return true
    end
)

return this
