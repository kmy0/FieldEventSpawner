---@class (exact) MonsterEventFactory : AreaEventFactory
---@field event_data MonsterData
---@field pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@field monster_role app.EnemyDef.ROLE_ID
---@field legendary_id app.EnemyDef.LEGENDARY_ID
---@field is_village_boost boolean
---@field is_yummy boolean
---@field spoffer integer?
---@field rewards GuiRewardData[]?
---@field difficulty System.Guid[]?
---@field environ app.EnvironmentType.ENVIRONMENT[]?
---@field protected _field_director app.cExFieldDirector
---@field protected _schedule_timeline app.cExFieldDirector.cScheduleTimeline

--[[ app.cExFieldEvent_PopEnemy
    _FreeValue0 = app.EnemyDef.ID_Fixed
    _FreeValue1 = app.cEmParamGuid_Difficulty2_DifficultyRate.Value Hash, found at app.user_data.ExFieldParam_LayoutData.cDifficultyWeight._DifficultyRank
    _FreeValue2 = app.FieldDef.STAGE_Fixed
    _FreeValue3 = app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo._AreaMoveGuid Hash
    _FreeValue4 = app.cExFieldEvent_EmReward ID1, from app.cExFieldDirector:createExEmRewardEvent(...) at index 0
    _FreeValue5 = app.cExFieldEvent_EmReward ID2, from app.cExFieldDirector:createExEmRewardEvent(...) at index 1, -1 if it does not exist
    _FreeMiniValue0 =
        a14 = 0 when creating monsters through createEmPopEvent
        if isVillageBoost then
            _FreeMiniValue0 = a14 | 0x5C
        else
            _FreeMiniValue0 = a14 & 1 | 0x1C
        end

        if isYummy then
            _FreeMiniValue0 |= 1
        end
    _FreeMiniValue1 = app.EnvironmentType.ENVIRONMENT | (0x10 * app.ExDef.POP_EM_TYPE_Fixed)
    _FreeMiniValue2 = app.EnemyDef.ROLE_ID | (0x10 * LEGENDARY_ID)
    _FreeMiniValue3 = Area number
    _FreeMiniValue4 = GroupIDNo, (0x10 * lotOptionTagIdx) | idx
        idx = lowest not occupied idx between 0 and 15, one idx per monster of the same kind eg. two Rathians would have idx 0 and 1,
        swarm members have the same groupid
    _FreeMiniValue5 = Countdown starting point in minutes
    _FreeMiniValue6 = app.cKeepQuestData._Index, 255 if quest is not saved
]]

local data = require("FieldEventSpawner.data")
local factory = require("FieldEventSpawner.events.area_event_factory")
local reward_factory = require("FieldEventSpawner.events.reward")
local sched = require("FieldEventSpawner.schedule")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local rl = data.util.reverse_lookup
local rt = data.runtime
local ace = data.ace

---@class MonsterEventFactory
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = factory })

---@param monster_data MonsterData
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type  app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param stage app.FieldDef.STAGE
---@param time integer
---@param is_village_boost boolean
---@param is_yummy boolean
---@param area integer?
---@param spoffer integer?
---@param rewards GuiRewardData[]?
---@param difficulty System.Guid[]?
---@param environ app.EnvironmentType.ENVIRONMENT[]?
---@return MonsterEventFactory
function this:new(
    monster_data,
    monster_role,
    pop_em_type,
    legendary_id,
    stage,
    time,
    is_village_boost,
    is_yummy,
    area,
    spoffer,
    rewards,
    difficulty,
    environ
)
    local o = factory.new(self, monster_data, stage, time, area)
    setmetatable(o, self)
    ---@cast o MonsterEventFactory

    o.monster_role = monster_role
    o.legendary_id = legendary_id
    o.is_village_boost = is_village_boost
    o.is_yummy = is_yummy
    o.spoffer = spoffer
    o.pop_em_type = pop_em_type
    o.rewards = rewards
    o.difficulty = difficulty
    o.environ = environ
    o._field_director, o._schedule_timeline = rt.get_field_director()
    o._area_array = monster_data:get_area_array(
        stage,
        not environ and rt.get_environ(stage) or nil,
        ace.map.pop_em_to_em_param_key[ace.enum.pop_em_fixed[pop_em_type]]
    )
    return o
end

---@return SpawnResult, MonsterSpawnEvent?
function this:build()
    local environ_type = self.environ and self.environ[math.random(#self.environ)] or rt.get_environ(self.stage)
    local other_monsters = self._field_director:findExecutedPopEms(true)
    local other_monsters_lua = util.system_array_to_lua(other_monsters)
    local route_guid, areas = self:_get_route_data(other_monsters, environ_type)
    if not areas or self.environ then
        areas = self._area_array
    end
    ---@cast areas integer[]
    local area = self.area and self.area or self:_get_area(other_monsters_lua, areas)

    if not area then
        return rt.enum.spawn_result.NO_AREA
    end

    local em_pop_param = self:_get_em_pop_param()
    if not em_pop_param then
        return rt.enum.spawn_result.NO_EM_PARAM
    end

    local difficulty_guid = self.difficulty and self.difficulty[math.random(#self.difficulty)]
        or self:_get_difficulty(em_pop_param)
    if not difficulty_guid then
        return rt.enum.spawn_result.NO_DIFFICULTY
    end

    local spoffer_rewards = (self.rewards and self.spoffer) and self:_get_edited_reward_data() or nil
    local reward_data = self:_get_reward_data(difficulty_guid)

    if not reward_data or (self.rewards and self.spoffer and not spoffer_rewards) then
        return rt.enum.spawn_result.NO_REWARDS
    end

    local event_data = sched.util.create_event_data()
    event_data._EventType = rl(ace.enum.ex_event, "POP_EM")
    event_data._FreeValue0 = util.getEnemyIdFixed:call(nil, self.event_data.id)
    event_data._FreeValue1 = util.hash_guid(difficulty_guid)
    event_data._FreeValue2 = util.get_stage_id_fixed(self.stage)
    event_data._FreeValue3 = util.hash_guid(route_guid)
    event_data._FreeValue4 = reward_data.reward_id1
    event_data._FreeValue5 = reward_data.reward_id2
    --FIXME: after TU2 game auto xors (0x80 * self.legendary_id) for tempered monsters that can be also swarm
    event_data._FreeMiniValue0 = ((self.is_village_boost and not self.spoffer) and 0x5C or 0x1C)
        | ((self.is_yummy or reward_data.reward_id2 ~= -1) and 1 or 0)
    event_data._FreeMiniValue1 = environ_type | (0x10 * self.pop_em_type)
    event_data._FreeMiniValue2 = self.monster_role | (0x10 * self.legendary_id)
    event_data._FreeMiniValue3 = area
    event_data._FreeMiniValue4 = self:_get_group_id(other_monsters, environ_type, difficulty_guid)
    event_data._FreeMiniValue5 = self.time
    event_data._FreeMiniValue6 = 255

    local ret = sched.spawn_event.monster_ctor(
        event_data,
        self:_get_monster_name(),
        area,
        self.event_data.id,
        self.area,
        self.spoffer and self.is_village_boost or false,
        self.spoffer,
        nil,
        nil,
        sched.spawn_event.subevent_ctor(reward_data.reward_array),
        spoffer_rewards
    )
    return rt.enum.spawn_result.OK, ret
end

---@protected
---@param em_pop_param  app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base
---@return System.Guid?
function this:_get_difficulty(em_pop_param)
    return em_pop_param:lotDifficultyID(self.legendary_id, 0, true)
end

---@protected
---@param other_ems System.Array<app.cExFieldEvent_PopEnemy>
---@param environ_type app.EnvironmentType.ENVIRONMENT
---@return System.Guid, integer[]?
function this:_get_route_data(other_ems, environ_type)
    local route_pattern_array = self._field_director:getRoutePatternList(
        self.event_data.id,
        self.monster_role,
        self.legendary_id,
        self.pop_em_type,
        self.stage,
        environ_type,
        other_ems,
        1
    )
    local route_info = route_pattern_array._Array:get_Item(0)
    ---@cast route_info app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo
    local area_array = self._field_director:getInitAreaList(route_info, self.stage, environ_type)
    local enum = util.get_array_enum(area_array._Array)
    ---@type integer[]
    local ret = {}

    while enum:MoveNext() do
        local area = enum:get_Current()
        if area ~= nil then
            table.insert(ret, area)
        end
    end

    local guid = route_info:get_AreaMoveGuid()
    if table_util.empty(ret) then
        return guid
    end

    return guid, ret
end

---@protected
---@return app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base
function this:_get_em_pop_param()
    local field_layout = ace.ex_field_param:getFieldLayout(self.stage)
    local pop_param_by_hr = field_layout:getEmPopParamByHR(999, self.pop_em_type)
    local field_name = ace.map.pop_em_to_param_field[ace.enum.pop_em_fixed[self.pop_em_type]]
    local pop_param_array = pop_param_by_hr:get_field(field_name)
    ---@cast pop_param_array  System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base>
    return field_layout:getPopParamByEmID(self.event_data.id, pop_param_array)
end

---@protected
---@param difficulty_guid System.Guid
---@return EditedRewardData?
function this:_get_reward_data(difficulty_guid)
    local ret
    if self.rewards and not self.spoffer then
        ret = self:_get_edited_reward_data()
    else
        local reward_data = self:_get_game_reward_data(difficulty_guid)
        ---@cast reward_data EditedRewardData
        reward_data.reward_array = sched.util.unpack_events(reward_data.reward_array)
        ret = reward_data
    end

    return ret
end

---@protected
---@return EditedRewardData?
function this:_get_edited_reward_data()
    ---@type EditedRewardData?
    local ret
    if self.rewards then
        local reward_fac = reward_factory:new(self.rewards, self.stage)
        ret = reward_fac:build()
    end
    return ret
end

---@protected
---@param difficulty_guid System.Guid
---@return RewardData
function this:_get_game_reward_data(difficulty_guid)
    local out_item_work_array_vt =
        ValueType.new(sdk.find_type_definition("app.savedata.cItemWork[]") --[[@as RETypeDefinition]])
    local out_bool_array_vt = ValueType.new(sdk.find_type_definition("System.Boolean[]") --[[@as RETypeDefinition]])
    self._field_director:createRewardData(
        out_item_work_array_vt,
        out_bool_array_vt,
        self.event_data.id,
        self.monster_role,
        self.legendary_id,
        difficulty_guid,
        self.is_yummy
    )

    local item_work_array = sdk.to_managed_object(util.deref_ptr(out_item_work_array_vt:address()))
    ---@cast item_work_array System.Array<app.savedata.cItemWork>
    local bool_array = sdk.to_managed_object(util.deref_ptr(out_bool_array_vt:address()))
    ---@cast bool_array System.Array<System.Boolean>
    local out_reward_id_array_vt = ValueType.new(sdk.find_type_definition("System.Int32[]") --[[@as RETypeDefinition]])
    local out_event_reward_array_vt =
        ValueType.new(sdk.find_type_definition("app.cExFieldEvent_EmReward[]") --[[@as RETypeDefinition]])
    self._field_director:createExEmRewardEvent(
        out_event_reward_array_vt,
        out_reward_id_array_vt,
        item_work_array:get_Count(),
        item_work_array,
        bool_array,
        self._schedule_timeline,
        self.stage
    )

    local reward_id_array = sdk.to_managed_object(util.deref_ptr(out_reward_id_array_vt:address()))
    local event_reward_array = sdk.to_managed_object(util.deref_ptr(out_event_reward_array_vt:address()))
    ---@cast event_reward_array System.Array<app.cExFieldEvent_EmReward>
    ---@cast reward_id_array System.Array<System.Int32>
    ---@type RewardData
    local ret = {
        reward_array = event_reward_array,
        reward_id1 = -1,
        reward_id2 = -1,
    }
    for i = 0, reward_id_array:get_Count() - 1 do
        ret[string.format("reward_id%s", i + 1)] = reward_id_array:get_Item(i)
    end
    return ret
end

---@protected
---@param other_ems System.Array<app.cExFieldEvent_PopEnemy>
---@param environ_type app.EnvironmentType.ENVIRONMENT
---@param difficulty_guid System.Guid
---@return integer
function this:_get_group_id(other_ems, environ_type, difficulty_guid)
    local option = self:_lot_option_tag(environ_type, difficulty_guid)
    local count = 0

    local enum = util.get_array_enum(other_ems)
    while enum:MoveNext() do
        local em = enum:get_Current()
        ---@cast em app.cExFieldEvent_PopEnemy
        if em:get_EmID() == self.event_data.id and em:get_IsWorking() then
            count = count + 1
        end
    end
    return (0x10 * option) | count
end

---@protected
---@param environ_type app.EnvironmentType.ENVIRONMENT
---@param difficulty_guid System.Guid
---@return integer
function this:_lot_option_tag(environ_type, difficulty_guid)
    local enemy_param = ace.ex_field_param:get_ExEnemyGlobalParam()
    local reward_rank = util.getRewardRankFromDifficulty:call(nil, difficulty_guid) --[[@as app.QuestDef.EM_REWARD_RANK]]
    local enemy_global_param = enemy_param:getExEmGlobalParam(
        self.event_data.id,
        self.monster_role,
        self.legendary_id,
        rl(ace.enum.quest_rank, "EX"),
        reward_rank
    )
    return enemy_global_param:lotOptionTagIdx(self.stage, environ_type)
end

---@protected
---@param option_value System.Int64
---@param difficulty_guid System.Guid
---@return integer
function this:_get_option_tag(option_value, difficulty_guid)
    local enemy_param = ace.ex_field_param:get_ExEnemyGlobalParam()
    local reward_rank = util.getRewardRankFromDifficulty:call(nil, difficulty_guid) --[[@as app.QuestDef.EM_REWARD_RANK]]
    local enemy_global_param = enemy_param:getExEmGlobalParam(
        self.event_data.id,
        self.monster_role,
        self.legendary_id,
        rl(ace.enum.quest_rank, "EX"),
        reward_rank
    )
    return enemy_global_param:getOptionTagIdx(option_value)
end

---@protected
---@return string
function this:_get_monster_name()
    local name_guid
    if self.legendary_id == rl(ace.enum.legendary, "NORMAL") then
        name_guid = util.getEnemyLegendaryName:call(nil, self.event_data.id)
    elseif self.legendary_id == rl(ace.enum.legendary, "KING") then
        name_guid = util.getEnemyLegendaryKingName:call(nil, self.event_data.id)
    elseif self.monster_role == rl(ace.enum.em_role, "BOSS") then
        name_guid = util.getEnemyExtraName:call(nil, self.event_data.id)
    elseif self.pop_em_type == rl(ace.enum.pop_em_fixed, "FRENZY") then
        name_guid = util.getEnemyFrenzyName:call(nil, self.event_data.id)
    else
        name_guid = util.getEnemyNameGuid:call(nil, self.event_data.id)
    end
    return util.get_message_local(name_guid, util.get_language(), true)
end

return this
