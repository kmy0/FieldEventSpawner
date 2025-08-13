---@class (exact) BattlefieldEventFactory : MonsterEventFactory
---@field battlefield_state BattlefieldState

--[[
    app.cExFieldEvent_PopEnemy
    _FreeValue0 = app.EnemyDef.ID_Fixed
    _FreeValue1 = app.cEmParamGuid_Difficulty2_DifficultyRate.Value Hash, found at app.user_data.ExFieldParam_LayoutData.cDifficultyWeight._DifficultyRank
    _FreeValue2 = app.FieldDef.STAGE_Fixed
    _FreeValue3 = unused
    _FreeValue4 = app.cExFieldEvent_EmReward ID1, from app.cExFieldDirector:createExEmRewardEvent(...) at index 0
    _FreeValue5 = app.cExFieldEvent_EmReward ID2, from app.cExFieldDirector:createExEmRewardEvent(...) at index 1, -1 if it does not exist
    _FreeMiniValue0 = if pop_belonging then 0 else 0x1C | (is_yummy and 1 or 0)
    _FreeMiniValue1 = app.EnvironmentType.ENVIRONMENT | (0x10 * app.ExDef.POP_EM_TYPE_Fixed)
    _FreeMiniValue2 = if pop_belonging then 0 else app.EnemyDef.ROLE_ID | (0x10 * LEGENDARY_ID)
    _FreeMiniValue3 = Area number
    _FreeMiniValue4 = 0x10 * getOptionTagIdx(option)
        if pop_belonging then
            option = app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam:get_OptionTagValue
        else
            option = 0
        end
    _FreeMiniValue5 = Countdown starting point in minutes
    _FreeMiniValue6 = app.cKeepQuestData._Index, 255 if quest is not saved


    app.cExFieldEvent_Battlefield
    _FreeValue0 = app.FieldDef.STAGE_Fixed current map
    _FreeValue1 = app.FieldDef.STAGE_Fixed _QuestStage
    _FreeValue2 = app.cExFieldEvent_PopEnemy._UniqueIndex
    _FreeValue3 = if pop_belonging then 0 else _ExecMinute
    _FreeValue4 = Route Guid Hash
    _FreeValue5 = unused
    _FreeMiniValue0 = pop_belonging | (0x10 * app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield._IsOnlyPopBelongingStage) | 0xC
    _FreeMiniValue1 = Countdown starting point in minutes
    _FreeMiniValue2 = _BattlefieldBelongingStageStayMinute
    _FreeMiniValue3 = app.cKeepQuestData._Index, 255 if quest is not saved
    _FreeMiniValue4 = if pop_belonging then 2 else 0 app.cExFieldEvent_Battlefield.BATTLEFIELD_STATE
    _FreeMiniValue5 = if pop_belonging then getOptionTagIdx(app.EnemyDef.OptionTagHolder.Value) else 0
    _FreeMiniValue6 = if pop_belonging then _AreaNo else _AreaNo_AfterPopBelongingStage
]]

local data = require("FieldEventSpawner.data")
local monster_factory = require("FieldEventSpawner.events.monster.monster")
local sched = require("FieldEventSpawner.schedule")
local util = require("FieldEventSpawner.util")

local rl = data.util.reverse_lookup
local rt = data.runtime
local ace = data.ace

---@class BattlefieldEventFactory
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = monster_factory })

---@param monster_data MonsterData
---@param monster_role app.EnemyDef.ROLE_ID
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param stage app.FieldDef.STAGE
---@param time integer
---@param is_yummy boolean
---@param battlefield_state BattlefieldState
---@param area integer?
---@param rewards GuiRewardData[]?
---@param difficulty System.Guid[]?
---@param environ app.EnvironmentType.ENVIRONMENT[]?
---@return BattlefieldEventFactory
function this:new(
    monster_data,
    monster_role,
    legendary_id,
    stage,
    time,
    is_yummy,
    battlefield_state,
    area,
    rewards,
    difficulty,
    environ
)
    local o = monster_factory.new(
        self,
        monster_data,
        monster_role,
        rl(ace.enum.pop_em_fixed, "BATTLEFIELD"),
        legendary_id,
        stage,
        time,
        false,
        is_yummy,
        area,
        nil,
        rewards,
        difficulty,
        environ
    )
    setmetatable(o, self)
    ---@cast o BattlefieldEventFactory
    o.battlefield_state = battlefield_state
    o.pop_em_type = o:_get_em_pop_type_bf()
    o._area_array = monster_data:get_area_array(
        stage,
        not environ and rt.get_environ(stage) or nil,
        ace.map.pop_em_to_em_param_key[ace.enum.pop_em_fixed[o.pop_em_type]]
    )
    return o
end

---@protected
---@return SpawnResult, SpawnEvent?
function this:build()
    local area = self.area and self.area or self:_get_area({}, self._area_array)
    if not area then
        return rt.enum.spawn_result.NO_AREA
    end

    local em_pop_param = self:_get_em_pop_param()
    if not em_pop_param then
        return rt.enum.spawn_result.NO_EM_PARAM
    end
    ---@cast em_pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield

    local difficulty_guid, option_value
    local is_repel = self.battlefield_state == rt.enum.battlefield_state.battlefield_repel
    local environ_type = self.environ and self.environ[math.random(#self.environ)] or rt.get_environ(self.stage)
    local stage_param = self:_get_repel_param(em_pop_param, area)

    if stage_param then
        option_value = stage_param:get_OptionTagValue()
    else
        -- slay only
        option_value = 0
    end

    if self.difficulty then
        difficulty_guid = self.difficulty[math.random(#self.difficulty)]
    else
        if is_repel then
            difficulty_guid = em_pop_param:lotDifficultyID_PopBelonging(self.legendary_id)
        else
            difficulty_guid = em_pop_param:lotDifficultyID(self.legendary_id, 0, true)
        end
    end

    if not difficulty_guid then
        return rt.enum.spawn_result.NO_DIFFICULTY
    end

    local reward_data = self:_get_reward_data(difficulty_guid)

    if not reward_data then
        return rt.enum.spawn_result.NO_REWARDS
    end

    local event_data = sched.util.create_event_data()
    event_data._EventType = rl(ace.enum.ex_event, "POP_EM")
    event_data._FreeValue0 = util.getEnemyIdFixed:call(nil, self.event_data.id)
    event_data._FreeValue1 = util.hash_guid(difficulty_guid)
    event_data._FreeValue2 = util.get_stage_id_fixed(self.stage)
    event_data._FreeValue4 = reward_data.reward_id1
    event_data._FreeValue5 = reward_data.reward_id2
    event_data._FreeMiniValue0 = is_repel and 0 or 0x1C | ((self.is_yummy or reward_data.reward_id2 ~= -1) and 1 or 0)
    event_data._FreeMiniValue1 = environ_type | (0x10 * self.pop_em_type)
    event_data._FreeMiniValue2 = self.monster_role | (0x10 * self.legendary_id)
    event_data._FreeMiniValue3 = area
    event_data._FreeMiniValue4 = stage_param and 0x10 * self:_get_option_tag(option_value, difficulty_guid) or 0
    event_data._FreeMiniValue5 = self.time
    event_data._FreeMiniValue6 = 255
    event_data._ExecMinute = self._schedule_timeline:get_AdvancedGameMinute() + 1
    event_data._UniqueIndex = self._schedule_timeline:newEventUniqueIndex(self.stage)

    local sub_events = sched.spawn_event.subevent_ctor(reward_data.reward_array)
    table.insert(sub_events, sched.spawn_event.subevent_ctor(event_data)[1])
    return rt.enum.spawn_result.OK,
        sched.spawn_event.monster_ctor(
            self:_get_battlefield_data(
                em_pop_param,
                event_data._ExecMinute - 1,
                event_data._UniqueIndex,
                difficulty_guid
            ),
            self:_get_monster_name(),
            area,
            self.event_data.id,
            self.area,
            nil,
            nil,
            rt.enum.event_collision_flag.EVENT_TYPE,
            {
                sched.spawn_event.child_ctor(
                    event_data._UniqueIndex,
                    event_data,
                    area,
                    rt.enum.event_collision_flag.ID
                ),
            },
            sub_events
        )
end

---@protected
---@param em_pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
---@param now integer
---@param em_pop_index integer
---@param difficulty_guid System.Guid
---@return app.cExFieldScheduleExportData.cEventData
function this:_get_battlefield_data(em_pop_param, now, em_pop_index, difficulty_guid)
    local route_guid, area, option_value
    local is_repel = self.battlefield_state == rt.enum.battlefield_state.battlefield_repel

    if is_repel then
        route_guid = em_pop_param:get_RouteID_AfterPopBelongingStage()
        area = em_pop_param:get_AreaNo_AfterPopBelongingStage()
        option_value = em_pop_param:get_OptionTagValue_AfterPopBelongingStage()
    else
        route_guid = em_pop_param:get_RouteID()
        area = em_pop_param:get_AreaNo()
        option_value = em_pop_param:get_OptionTagValue()
    end

    local event_data = sched.util.create_event_data()
    event_data._ExecMinute = now
    event_data._EventType = rl(ace.enum.ex_event, "BATTLEFIELD")
    event_data._FreeValue0 = util.get_stage_id_fixed(self.stage)
    event_data._FreeValue1 = util.get_stage_id_fixed(em_pop_param:get_QuestStage())
    event_data._FreeValue2 = em_pop_index
    event_data._FreeValue3 = is_repel and 0 or now
    event_data._FreeValue4 = util.hash_guid(route_guid)
    event_data._FreeMiniValue0 = (is_repel and 1 or 0)
        | (0x10 * (em_pop_param:get_IsOnlyPopBelongingStage() and 1 or 0))
        | 0xC
    event_data._FreeMiniValue1 = self.time
    event_data._FreeMiniValue2 = self.time
    event_data._FreeMiniValue3 = 255
    event_data._FreeMiniValue4 = is_repel and rl(ace.enum.battlefield_state, "POP_BELONGING")
        or rl(ace.enum.battlefield_state, "ACCEPTABLE_QUEST")
    event_data._FreeMiniValue5 = self:_get_option_tag(option_value, difficulty_guid)
    event_data._FreeMiniValue6 = area
    event_data._UniqueIndex = self._schedule_timeline:newEventUniqueIndex(self.stage)
    return event_data
end

---@protected
---@param em_pop_param app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield
---@param area integer
---@return app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam
function this:_get_repel_param(em_pop_param, area)
    local pop_belong_array = em_pop_param._PopBelongingStageParam
    local pop_belong_enum = util.get_array_enum(pop_belong_array)

    while pop_belong_enum:MoveNext() do
        local pop_belong = pop_belong_enum:get_Current()
        ---@cast pop_belong app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam
        if pop_belong:get_AreaNo() == area then
            return pop_belong
        end
    end
end

---@protected
---@return app.ExDef.POP_EM_TYPE_Fixed
function this:_get_em_pop_type_bf()
    if self.battlefield_state == rt.enum.battlefield_state.battlefield_slay then
        return rl(ace.enum.pop_em_fixed, "BATTLEFIELD")
    end
    return rl(ace.enum.pop_em_fixed, "BF_POP_BELONGING")
end

return this
