---@class RuntimeData
---@field envman app.EnvironmentManager?
---@field stageman app.MasterFieldManager?
---@field flowman app.GameFlowManager?
---@field gimman app.GimmickManager?
---@field animalman app.AnimalManager?
---@field missionman app.MissionManager?
---@field state State

---@class (exact) SpOfferCandidate
---@field unique_index integer
---@field name string
---@field exec_min integer

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

local ace_data = require("FieldEventSpawner.data.ace")
local data_util = require("FieldEventSpawner.data.util")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local rl = data_util.reverse_lookup

---@class RuntimeData
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
    enum = {},
}

---@enum ScheduleState
this.enum.schedule_state = {
    NO_STAGE = 1,
    OK = 2,
}
---@enum SwarmState
this.enum.swarm_state = {
    SWARM = 1,
    BOSS = 2,
    HAS_BOSS = 3,
}
---@enum SpawnResult
this.enum.spawn_result = {
    OK = 1,
    NO_AREA = 2,
    NO_DIFFICULTY = 3,
    NO_EM_PARAM = 4,
    NO_REWARDS = 5,
}
---@enum BattlefieldState
this.enum.battlefield_state = {
    battlefield_repel = 1,
    battlefield_slay = 2,
}
---@enum EventCollisionFlag
this.enum.event_collision_flag = {
    NONE = 0,
    AREA = 1 << 1,
    ID = 1 << 2,
    TIME = 1 << 3,
    EVENT_TYPE = 1 << 4,
}
---@enum CachedEventType
this.enum.cached_event_type = {
    PARENT = 1,
    CHILD = 2,
}
---@enum SpawnState
this.enum.spawn_button_state = {
    OK = 1,
    EVENT_NOT_AVAILABLE = 2,
    BAD_ENVIRONMENT = 3,
}

---@return app.EnvironmentManager
function this.get_envman()
    if not this.envman then
        local obj = sdk.get_managed_singleton("app.EnvironmentManager")
        ---@cast obj app.EnvironmentManager
        this.envman = obj
    end
    return this.envman
end

---@return app.GameFlowManager
function this.get_flowman()
    if not this.flowman then
        local obj = sdk.get_managed_singleton("app.GameFlowManager")
        ---@cast obj app.GameFlowManager
        this.flowman = obj
    end
    return this.flowman
end

---@return app.MasterFieldManager
function this.get_fieldman()
    if not this.fieldman then
        local obj = sdk.get_managed_singleton("app.MasterFieldManager")
        ---@cast obj app.MasterFieldManager
        this.fieldman = obj
    end
    return this.fieldman
end

---@return app.AnimalManager
function this.get_animalman()
    if not this.animalman then
        local obj = sdk.get_managed_singleton("app.AnimalManager")
        ---@cast obj app.AnimalManager
        this.animalman = obj
    end
    return this.animalman
end

---@return app.GimmickManager
function this.get_gimman()
    if not this.gimman then
        local obj = sdk.get_managed_singleton("app.GimmickManager")
        ---@cast obj app.GimmickManager
        this.gimman = obj
    end
    return this.gimman
end

---@return app.MissionManager
function this.get_missionman()
    if not this.missionman then
        local obj = sdk.get_managed_singleton("app.MissionManager")
        ---@cast obj app.MissionManager
        this.missionman = obj
    end
    return this.missionman
end

---@return boolean
function this.is_in_game()
    if not this.get_flowman() then
        return false
    end
    return this.get_flowman():get_CurrentGameScene() > 0
end

---@return boolean
function this.is_in_quest()
    if not this.get_missionman() then
        return false
    end
    return this.get_missionman():get_IsActiveQuest()
end

---@return app.cExFieldDirector, app.cExFieldDirector.cScheduleTimeline
function this.get_field_director()
    local env = this.get_envman()
    local field_director = env._ExFieldDirector
    local schedule_timeline = field_director._ScheduleTimeline
    return field_director, schedule_timeline
end

---@return app.FieldDef.STAGE
function this.update_stage()
    local fieldman = this.get_fieldman()
    this.state.stage = fieldman:get_CurrentStage()
    return this.state.stage
end

---@return app.EnvironmentType.ENVIRONMENT
function this.update_environ()
    local stage = this.state.stage
    if not stage then
        stage = this.update_stage()
    end
    this.state.environ = this.get_environ(stage)
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

function this.is_ok()
    local field_director = this.get_field_director()
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
    local envman = this.get_envman()
    local env_layer = envman:getEnvActiveLayer(stage)
    local env_option = envman:getOption(env_layer, false, true, true, false)
    local ret = envman:getEnvironmentType(stage, env_option)
    return ret ~= -1 and ret or 0
end

function this.update_spoffer()
    if not this.is_spoffer_unlocked(this.state.stage) then
        table_util.clear(this.state.spoffer)
        return
    end

    local field_director, schedule_timeline = this.get_field_director()
    local pop_em_array = field_director:findExecutedPopEms(false)
    local pop_em_enum = util.get_array_enum(pop_em_array)

    ---@type integer[]
    local active_pop_ems = {}
    while pop_em_enum:MoveNext() do
        local pop_em = pop_em_enum:get_Current()
        ---@cast pop_em app.cExFieldEvent_PopEnemy

        if
            not pop_em:get_EnableSpOfferTarget()
            or not pop_em:get_EnableKeepQuestTarget()
            or pop_em:get_IsBattlefieldEm()
            or pop_em:get_PopEmType() == rl(ace_data.enum.pop_em_fixed, "POP_MANY_2")
        then
            goto continue
        end

        local unique_index = pop_em._UniqueIndex
        table.insert(active_pop_ems, unique_index)
        if not this.state.spoffer[unique_index] then
            this.state.spoffer[unique_index] = {
                unique_index = unique_index,
                name = ace_data.get_monster_name(pop_em),
                exec_min = pop_em._ExecMinute,
            }
        end

        ::continue::
    end

    for unique_index, _ in pairs(this.state.spoffer) do
        if not table_util.table_contains(active_pop_ems, unique_index) then
            this.state.spoffer[unique_index] = nil
        end
    end
end

---@param stage app.FieldDef.STAGE
---@return boolean
function this.is_spoffer_unlocked(stage)
    if this.state.feature_unlock.spoffer[stage] == nil then
        this.state.feature_unlock.spoffer[stage] = ace_data.ex_field_param:isOpenedSpOffer(stage)
    end
    return this.state.feature_unlock.spoffer[stage]
end

---@param stage app.FieldDef.STAGE
---@return boolean
function this.is_village_boost_unlocked(stage)
    if this.state.feature_unlock.village_boost[stage] == nil then
        this.state.feature_unlock.village_boost[stage] = ace_data.ex_field_param:isOpenedVillageBoost(stage)
    end
    return this.state.feature_unlock.village_boost[stage]
end

---@param stage app.FieldDef.STAGE
---@param em_id app.EnemyDef.ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@return boolean
function this.is_monster_banned(stage, em_id, pop_em_type)
    local ret = table_util.get_nested_value(this.state.feature_unlock.monster, { stage, em_id, pop_em_type })
    if ret == nil then
        local layout_data = ace_data.ex_field_param:getFieldLayout(this.state.stage)
        ret = layout_data:isBanned(em_id, 999, pop_em_type)
        table_util.set_nested_value(this.state.feature_unlock.monster, { stage, em_id, pop_em_type }, ret)
    end
    return ret
end

---@param gimmick_event app.ExDef.GIMMICK_EVENT
---@return boolean
function this.is_npc_unlocked(gimmick_event)
    if this.state.feature_unlock.npc[gimmick_event] == nil then
        this.state.feature_unlock.npc[gimmick_event] = ace_data.ex_field_param:isOpenedAssisNpc(gimmick_event)
            and not ace_data.ex_field_param:isDisableAssistNpc(gimmick_event)
    end
    return this.state.feature_unlock.npc[gimmick_event]
end

function this.clear_feature_unlock()
    table_util.clear(this.state.feature_unlock.spoffer)
    table_util.clear(this.state.feature_unlock.village_boost)
    table_util.clear(this.state.feature_unlock.monster)
    table_util.clear(this.state.feature_unlock.npc)
end

return this
