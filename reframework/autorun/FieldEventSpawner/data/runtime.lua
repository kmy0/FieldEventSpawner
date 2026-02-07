---@class ModData
---@field state State
---@field initialized boolean
---@field enum ModEnum

---@class (exact) SpOfferCandidate
---@field unique_index integer
---@field name string
---@field exec_min integer
---@field rank app.QuestDef.EM_REWARD_RANK

---@class (exact) State
---@field schedule ScheduleState
---@field stage app.FieldDef.STAGE?
---@field environ app.EnvironmentType.ENVIRONMENT?
---@field spoffer table<integer, SpOfferCandidate>
---@field is_background boolean?
---@field feature_unlock FeatureUnlock

---@class (exact) FeatureUnlock
---@field village_boost table<app.FieldDef.STAGE, boolean>
---@field spoffer table<app.FieldDef.STAGE, boolean>
---@field monster table<app.FieldDef.STAGE, table<app.EnemyDef.ID, table<app.ExDef.POP_EM_TYPE_Fixed, boolean>>>
---@field npc table<app.ExDef.GIMMICK_EVENT, boolean>

---@class (exact) ModEnum
---@field schedule_state ScheduleState.*
---@field swarm_state SwarmState.*
---@field spawn_result SpawnResult.*
---@field battlefield_state BattlefieldState.*
---@field event_collision_flag EventCollisionFlag.*
---@field cached_event_type CachedEventType.*
---@field spawn_button_state SpawnState.*

local data_ace = require("FieldEventSpawner.data.ace.init")
local e = require("FieldEventSpawner.util.game.enum")
local helpers = require("FieldEventSpawner.data.helpers")
local s = require("FieldEventSpawner.util.ref.singletons")
local util_game = require("FieldEventSpawner.util.game.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@module "FieldEventSpawner.gui.item.init"
local gui_items

---@class ModData
local this = {
    state = {
        schedule = 1,
        spoffer = {},
        feature_unlock = {
            village_boost = {},
            spoffer = {},
            monster = {},
            npc = {},
        },
    },
    ---@diagnostic disable-next-line: missing-fields
    enum = {},
    initialized = false,
}

---@enum ScheduleState
this.enum.schedule_state = { ---@class ScheduleState.*
    NO_STAGE = 1,
    OK = 2,
}
---@enum SwarmState
this.enum.swarm_state = { ---@class SwarmState.*
    SWARM = 1,
    BOSS = 2,
    HAS_BOSS = 3,
}
---@enum SpawnResult
this.enum.spawn_result = { ---@class SpawnResult.*
    OK = 1,
    NO_AREA = 2,
    NO_DIFFICULTY = 3,
    NO_EM_PARAM = 4,
    NO_REWARDS = 5,
}
---@enum BattlefieldState
this.enum.battlefield_state = { ---@class BattlefieldState.*
    battlefield_repel = 1,
    battlefield_slay = 2,
}
---@enum EventCollisionFlag
this.enum.event_collision_flag = { ---@class EventCollisionFlag.*
    NONE = 0,
    AREA = 1 << 1,
    ID = 1 << 2,
    TIME = 1 << 3,
    EVENT_TYPE = 1 << 4,
}
---@enum CachedEventType
this.enum.cached_event_type = { ---@class CachedEventType.*
    PARENT = 1,
    CHILD = 2,
}
---@enum SpawnState
this.enum.spawn_button_state = { ---@class SpawnState.*
    OK = 1,
    EVENT_NOT_AVAILABLE = 2,
    BAD_ENVIRONMENT = 3,
}

---@return boolean
function this.is_in_game()
    local flowman = s.get("app.GameFlowManager")
    if not flowman then
        return false
    end
    return flowman:get_CurrentGameScene() > 0
end

---@return boolean
function this.is_in_quest()
    local misman = s.get("app.MissionManager")
    if not misman then
        return false
    end
    return misman:get_IsActiveQuest()
end

---@return app.cExFieldDirector, app.cExFieldDirector.cScheduleTimeline
function this.get_field_director()
    local env = s.get("app.EnvironmentManager")
    local field_director = env._ExFieldDirector
    local schedule_timeline = field_director._ScheduleTimeline
    return field_director, schedule_timeline
end

---@return app.FieldDef.STAGE
function this.update_stage()
    local fieldman = s.get("app.MasterFieldManager")
    if fieldman then
        this.state.stage = fieldman:get_CurrentStage()
    else
        this.state.stage = -1
    end

    return this.state.stage
end

---@return app.EnvironmentType.ENVIRONMENT
function this.update_environ()
    if not this.state.stage then
        this.update_stage()
    end

    this.state.environ = this.get_environ(this.state.stage)
    return this.state.environ
end

---@return boolean, boolean
function this.update_background()
    local field_director = this.get_field_director()
    local is_background = field_director:get_IsRunBackGround()
    local changed = this.state.is_background ~= nil and this.state.is_background ~= is_background
    this.state.is_background = is_background
    return is_background, changed
end

---@return boolean
function this.is_ok()
    if not this.initialized or not s.get("app.EnvironmentManager") then
        return false
    end

    local field_director = this.get_field_director()
    ---@diagnostic disable-next-line: return-type-mismatch
    return this.is_in_game()
        and this.state.stage
        and field_director
        and field_director:isExEnableStage(this.state.stage)
        and field_director:get_IsRun()
        and field_director:get_LoadedStage()
end

---@param stage app.FieldDef.STAGE
---@return app.EnvironmentType.ENVIRONMENT
function this.get_environ(stage)
    local envman = s.get("app.EnvironmentManager")
    local env_layer = envman:getEnvActiveLayer(stage)
    local env_option = envman:getOption(env_layer, false, true, true, false)
    local ret = envman:getEnvironmentType(stage, env_option)
    return ret ~= -1 and ret or 0
end

function this.update_spoffer()
    if not this.is_spoffer_unlocked(this.state.stage) then
        util_table.clear(this.state.spoffer)
        return
    end

    local ranks = gui_items.get_difficulties()
    if not ranks then
        util_table.clear(this.state.spoffer)
        return
    end

    local field_director, _ = this.get_field_director()
    local pop_em_array = field_director:findExecutedPopEms(false, false)
    local pop_em_enum = util_game.get_array_enum(pop_em_array)
    local em_global_param = data_ace.ex_field_param:get_ExEnemyGlobalParam()

    ---@type integer[]
    local active_pop_ems = {}
    while pop_em_enum:MoveNext() do
        local pop_em = pop_em_enum:get_Current()
        ---@cast pop_em app.cExFieldEvent_PopEnemy

        if
            em_global_param:isExclusiveEm(pop_em:get_EmID())
            or not pop_em:get_EnableSpOfferTarget()
            or not pop_em:get_EnableKeepQuestTarget()
            or pop_em:get_IsBattlefieldEm()
        then
            goto continue
        end

        local second_rank = pop_em:get_Rank()
        if
            not util_table.any(ranks, function(key, _)
                return helpers.is_spoffer_pair(key, second_rank)
            end)
        then
            goto continue
        end

        local unique_index = pop_em._UniqueIndex
        table.insert(active_pop_ems, unique_index)
        if not this.state.spoffer[unique_index] then
            this.state.spoffer[unique_index] = {
                unique_index = unique_index,
                name = helpers.get_monster_name(pop_em),
                exec_min = pop_em._ExecMinute,
                rank = second_rank,
            }
        end

        ::continue::
    end

    for unique_index, _ in pairs(this.state.spoffer) do
        if not util_table.contains(active_pop_ems, unique_index) then
            this.state.spoffer[unique_index] = nil
        end
    end
end

---@param stage app.FieldDef.STAGE
---@return boolean
function this.is_spoffer_unlocked(stage)
    if this.state.feature_unlock.spoffer[stage] == nil then
        this.state.feature_unlock.spoffer[stage] = data_ace.ex_field_param:isOpenedSpOffer(stage)
    end
    return this.state.feature_unlock.spoffer[stage]
end

---@param stage app.FieldDef.STAGE
---@return boolean
function this.is_village_boost_unlocked(stage)
    if this.state.feature_unlock.village_boost[stage] == nil then
        this.state.feature_unlock.village_boost[stage] =
            data_ace.ex_field_param:isOpenedVillageBoost(stage)
    end
    return this.state.feature_unlock.village_boost[stage]
end

---@param stage app.FieldDef.STAGE
---@param em_id app.EnemyDef.ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@return boolean
function this.is_monster_banned(stage, em_id, pop_em_type)
    local ret = util_table.get_nested_value(
        this.state.feature_unlock.monster,
        { stage, em_id, pop_em_type }
    )
    if ret == nil then
        local layout_data = data_ace.ex_field_param:getFieldLayout(this.state.stage)
        ret = layout_data:isBanned(em_id, 999, pop_em_type)
        util_table.set_nested_value(
            this.state.feature_unlock.monster,
            { stage, em_id, pop_em_type },
            ret
        )
    end
    return ret
end

---@param gimmick_event app.ExDef.GIMMICK_EVENT
---@return boolean
function this.is_npc_unlocked(gimmick_event)
    if this.state.feature_unlock.npc[gimmick_event] == nil then
        this.state.feature_unlock.npc[gimmick_event] = data_ace.ex_field_param:isOpenedAssisNpc(
            gimmick_event
        ) and not data_ace.ex_field_param:isDisableAssistNpc(gimmick_event)
    end
    return this.state.feature_unlock.npc[gimmick_event]
end

---@param event_type app.EX_FIELD_EVENT_TYPE | string?
---@param event_id app.EnemyDef.ID_Fixed | app.ExDef.ANIMAL_EVENT_Fixed | app.ExDef.GIMMICK_EVENT_Fixed?
function this.print_events(event_type, event_id)
    ---@type string?
    local event_type_name
    ---@type app.EX_FIELD_EVENT_TYPE?
    local event_type_id
    ---@type string?
    local event_id_field

    if type(event_type) == "string" then
        event_type_name = event_type
        event_type_id = e.get("app.EX_FIELD_EVENT_TYPE")[event_type]
    elseif event_type then
        event_type_name = e.get("app.EX_FIELD_EVENT_TYPE")[event_type]
        event_type_id = event_type
    end

    if event_id and event_type_name then
        if event_type_name == "POP_EM" then
            event_id_field = "_FreeValue0"
        else
            event_id_field = "_FreeValue1"
        end
    end

    local _, schedule_timeline = this.get_field_director()
    local events = schedule_timeline._KeyList

    util_game.do_something(events, function(_, _, value)
        local event_data = value:exportData()
        if
            (not event_type_id or event_type_id == event_data:get_EventType())
            and (not event_id_field or event_data:get_field(event_id_field) == event_id)
        then
            util_ref.print_fields(event_data)
        end
    end)
end

function this.clear_feature_unlock()
    util_table.clear(this.state.feature_unlock.spoffer)
    util_table.clear(this.state.feature_unlock.village_boost)
    util_table.clear(this.state.feature_unlock.monster)
    util_table.clear(this.state.feature_unlock.npc)
end

---@return boolean
function this.init()
    gui_items = require("FieldEventSpawner.gui.item.init")
    this.initialized = true
    return true
end

return this
