---@class (exact) MonsterEventFactory : AreaEventFactory
---@field event_data MonsterData
---@field pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@field monster_role app.EnemyDef.ROLE_ID
---@field legendary_id app.EnemyDef.LEGENDARY_ID
---@field is_village_boost boolean?
---@field is_yummy boolean?
---@field spoffer_unique_index integer?
---@field rewards GuiRewardData[]?
---@field difficulty System.Guid?
---@field environ app.EnvironmentType.ENVIRONMENT[]?
---@field size integer?
---@field is_invalid boolean
---@field option_tag integer?
---@field is_reward_max boolean?
---@field invalid_rewards GuiRewardData[]?

---@class (exact) MonsterEventFactoryOptionalArgs : AreaEventFactoryOptionalArgs
---@field spoffer_unique_index integer?
---@field rewards GuiRewardData[]?
---@field difficulty System.Guid?
---@field environ app.EnvironmentType.ENVIRONMENT[]?
---@field size integer?
---@field option_tag integer?
---@field is_village_boost boolean?
---@field is_yummy boolean?
---@field is_reward_max boolean?
---@field invalid_rewards GuiRewardData[]?

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

local ace = require("FieldEventSpawner.data.ace.init")
local e = require("FieldEventSpawner.util.game.enum")
local factory = require("FieldEventSpawner.events.area_event_factory")
local game_lang = require("FieldEventSpawner.util.game.lang")
local helpers = require("FieldEventSpawner.data.helpers")
local hook = require("FieldEventSpawner.schedule.hook")
local m = require("FieldEventSpawner.util.ref.methods")
local mod = require("FieldEventSpawner.data.mod")
local reward_factory = require("FieldEventSpawner.events.reward")
local sched = require("FieldEventSpawner.schedule.init")
local util_game = require("FieldEventSpawner.util.game.init")
local util_misc = require("FieldEventSpawner.util.misc.init")
local util_ref = require("FieldEventSpawner.util.ref.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class MonsterEventFactory
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = factory })

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type  app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param opts MonsterEventFactoryOptionalArgs?
---@return MonsterEventFactory
function this:new(monster_data, stage, time, monster_role, pop_em_type, legendary_id, opts)
    opts = opts or {}
    local o = factory.new(self, monster_data, stage, time, opts)
    setmetatable(o, self)
    ---@cast o MonsterEventFactory

    o.monster_role = monster_role
    o.legendary_id = legendary_id
    o.is_village_boost = opts.is_village_boost
    o.is_yummy = opts.is_yummy
    o.spoffer_unique_index = opts.spoffer_unique_index
    o.pop_em_type = pop_em_type
    o.rewards = opts.rewards
    o.difficulty = opts.difficulty
    o.environ = opts.environ
    o.size = opts.size
    o.option_tag = opts.option_tag
    o.is_reward_max = opts.is_reward_max
    o.is_invalid = opts.difficulty
            and helpers.is_invalid_em2(monster_data, opts.difficulty, o.monster_role)
        or false
    o.invalid_rewards = opts.invalid_rewards

    o._area_array = monster_data:get_area_array(
        stage,
        not opts.environ and mod.get_environ(stage) or nil,
        o:_get_em_param()
    )
    return o
end

---@return SpawnResult
function this:spawn()
    hook.set_reward_max_flag(self.is_reward_max)
    return factory.spawn(self)
end

---@return SpawnResult, MonsterSpawnEvent?
function this:build()
    local environ_type = self.environ and self.environ[math.random(#self.environ)]
        or mod.get_environ(self.stage)
    local other_monsters = self._field_director:findExecutedPopEms(true, false)
    local other_monsters_lua = util_game.system_array_to_lua(other_monsters)
    local route_guid, areas = self:_get_route_data(other_monsters, environ_type)
    if not areas or self.environ then
        areas = self._area_array
    end

    ---@cast areas integer[]
    local area = self.area and self.area or self:_get_area(other_monsters_lua, areas)
    if not area then
        return mod.enum.spawn_result.NO_AREA
    end

    if not self.difficulty then
        local em_pop_param = self:_get_em_pop_param()
        if not em_pop_param then
            return mod.enum.spawn_result.NO_EM_PARAM
        end

        self.difficulty = self:_get_difficulty(em_pop_param)
    end

    if not self.difficulty then
        return mod.enum.spawn_result.NO_DIFFICULTY
    end

    ---@type EditedRewardData?
    local spoffer_rewards
    if self.rewards and self.spoffer_unique_index then
        spoffer_rewards = self:_get_edited_reward_data(self.rewards)
    elseif self.invalid_rewards and self.spoffer_unique_index then
        spoffer_rewards = self:_get_edited_reward_data(self.invalid_rewards)
    end

    local reward_data = self:_get_reward_data(self.difficulty)

    if
        not reward_data
        or (
            (self.invalid_rewards or self.rewards)
            and self.spoffer_unique_index
            and not spoffer_rewards
        )
    then
        return mod.enum.spawn_result.NO_REWARDS
    end

    self:_adjust_legendary_id()
    local event_data = sched.util.create_event_data()
    event_data._EventType = e.get("app.EX_FIELD_EVENT_TYPE").POP_EM
    event_data._FreeValue0 = e.to_fixed("app.EnemyDef.ID_Fixed", self.event_data.id)
    event_data._FreeValue1 = util_game.hash_guid(self.difficulty)
    event_data._FreeValue2 = e.to_fixed("app.FieldDef.STAGE_Fixed", self.stage)
    event_data._FreeValue3 = util_game.hash_guid(route_guid)
    event_data._FreeValue4 = reward_data.reward_id1
    event_data._FreeValue5 = reward_data.reward_id2
    event_data._FreeMiniValue0 = (
        (self.is_village_boost and not self.spoffer_unique_index) and 0x5C or 0x1C
    ) | ((self.is_yummy or reward_data.reward_id2 ~= -1) and 1 or 0)
    event_data._FreeMiniValue1 = environ_type | (0x10 * self.pop_em_type)
    event_data._FreeMiniValue2 = self.monster_role | (0x10 * self.legendary_id)
    event_data._FreeMiniValue3 = area
    event_data._FreeMiniValue4 = self:_get_group_id(other_monsters, environ_type, self.difficulty)
    event_data._FreeMiniValue5 = self.time
    event_data._FreeMiniValue6 = 255
    event_data._ExecMinute = self._schedule_timeline:get_AdvancedGameMinute() + self.spawn_delay

    local ret = sched.spawn_event.make_monster(
        event_data,
        self:_get_monster_name(),
        area,
        self.event_data.id,
        {
            area = self.area,
            is_spoffer_village_boost = self.spoffer_unique_index and self.is_village_boost or false,
            spoffer_unique_index = self.spoffer_unique_index,
            sub_events = sched.spawn_event.make_subevent(reward_data.reward_array),
            spoffer_rewards = spoffer_rewards,
            size = self.size,
            option_tag = self.option_tag,
        }
    )
    return mod.enum.spawn_result.OK, ret
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
    local function fetch_route_info(role)
        local array = self._field_director:getRoutePatternList(
            self.event_data:get_em_id_for_route(self.stage),
            role,
            self.legendary_id,
            self.pop_em_type,
            self.stage,
            environ_type,
            other_ems,
            1
        )
        return array._Array:get_Item(0)
    end

    ---@type app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo
    local route_info

    util_misc.try(function()
        route_info = fetch_route_info(self.monster_role)
        if not route_info then
            error("NO ROUTE INFO")
        end
    end, function(err)
        if not self.is_invalid then
            error(err)
        end
        route_info = fetch_route_info(e.get("app.EnemyDef.ROLE_ID").NORMAL)
    end)

    local area_array = self._field_director:getInitAreaList(route_info, self.stage, environ_type)
    local ret = {}
    local enum = util_game.get_array_enum(area_array._Array)
    while enum:MoveNext() do
        local area = enum:get_Current()
        if area ~= nil then
            table.insert(ret, area)
        end
    end

    local guid = route_info:get_AreaMoveGuid()
    return guid, util_table.empty(ret) and nil or ret
end

---@protected
---@return app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base
function this:_get_em_pop_param()
    local field_layout = ace.ex_field_param:getFieldLayout(self.stage)
    local pop_param_by_hr = field_layout:getEmPopParamByHR(999, self.pop_em_type)
    local field_name =
        ace.map.pop_em_to_param_field[e.get("app.ExDef.POP_EM_TYPE_Fixed")[self.pop_em_type]]
    local pop_param_array = pop_param_by_hr:get_field(field_name)
    ---@cast pop_param_array  System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base>
    return field_layout:getPopParamByEmID(
        self.event_data.spoofed_id or self.event_data.id,
        pop_param_array
    )
end

---@protected
---@param difficulty_guid System.Guid
---@return EditedRewardData?
function this:_get_reward_data(difficulty_guid)
    local ret
    if self.invalid_rewards and not self.spoffer_unique_index then
        ret = self:_get_edited_reward_data(self.invalid_rewards)
    elseif self.rewards and not self.spoffer_unique_index then
        ret = self:_get_edited_reward_data(self.rewards)
    else
        local reward_data = self:_get_game_reward_data(difficulty_guid)
        ---@cast reward_data EditedRewardData
        reward_data.reward_array = sched.util.unpack_events(reward_data.reward_array)
        ret = reward_data
    end

    return ret
end

---@protected
---@param rewards GuiRewardData[]
---@return EditedRewardData?
function this:_get_edited_reward_data(rewards)
    ---@type EditedRewardData?
    local ret
    if rewards then
        local reward_fac = reward_factory:new(rewards, self.stage)
        ret = reward_fac:build()
    end
    return ret
end

---@protected
---@param difficulty_guid System.Guid
---@return System.Array<app.savedata.cItemWork>, System.Array<System.Boolean>
function this:_get_reward_array(difficulty_guid)
    local out_item_work_array_vt = util_ref.value_type("app.savedata.cItemWork[]")
    local out_bool_array_vt = util_ref.value_type("System.Boolean[]")
    self._field_director:createRewardData(
        out_item_work_array_vt,
        out_bool_array_vt,
        self.event_data.spoofed_id or self.event_data.id,
        self.monster_role,
        self.legendary_id,
        difficulty_guid,
        self.is_yummy
    )

    local item_work_array = sdk.to_managed_object(
        util_ref.deref_ptr((out_item_work_array_vt --[[@as ValueType]]):address())
    ) --[[@as System.Array<app.savedata.cItemWork>]]

    if item_work_array:get_Count() == 0 and self.is_invalid then
        return self:_get_reward_array(
            util_game.parse_guid(ace.map.replace_em_rank_guid[self.legendary_id])
        )
    end

    local bool_array =
        sdk.to_managed_object(util_ref.deref_ptr((out_bool_array_vt --[[@as ValueType]]):address())) --[[@as System.Array<System.Boolean>]]

    return item_work_array, bool_array
end

---@protected
---@param difficulty_guid System.Guid
---@return RewardData
function this:_get_game_reward_data(difficulty_guid)
    local item_work_array, bool_array = self:_get_reward_array(difficulty_guid)
    local out_reward_id_array_vt = util_ref.value_type("System.Int32[]")
    local out_event_reward_array_vt = util_ref.value_type("app.cExFieldEvent_EmReward[]")
    self._field_director:createExEmRewardEvent(
        out_event_reward_array_vt,
        out_reward_id_array_vt,
        item_work_array:get_Count(),
        item_work_array,
        bool_array,
        self._schedule_timeline,
        self.stage
    )

    local reward_id_array = sdk.to_managed_object(
        util_ref.deref_ptr((out_reward_id_array_vt--[[@as ValueType]]):address())
    ) --[[@as System.Array<System.Int32>]]
    local event_reward_array = sdk.to_managed_object(
        util_ref.deref_ptr((out_event_reward_array_vt--[[@as ValueType]]):address())
    ) --[[@as System.Array<app.cExFieldEvent_EmReward>]]

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

    local enum = util_game.get_array_enum(other_ems)
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
    local reward_rank = m.getRewardRankFromDifficulty(difficulty_guid)
    local enemy_global_param = enemy_param:getExEmGlobalParam(
        self.event_data.id,
        self.monster_role,
        self.legendary_id,
        e.get("app.QuestDef.RANK").EX,
        reward_rank
    )
    local ret = 0

    util_misc.try(function()
        ret = enemy_global_param:lotOptionTagIdx(self.stage, environ_type)
    end, function(err)
        if not self.is_invalid then
            error(err)
        end
    end)

    return ret
end

---@protected
---@param option_value System.Int64
---@param difficulty_guid System.Guid
---@return integer
function this:_get_option_tag(option_value, difficulty_guid)
    local enemy_param = ace.ex_field_param:get_ExEnemyGlobalParam()
    local reward_rank = m.getRewardRankFromDifficulty(difficulty_guid)
    local enemy_global_param = enemy_param:getExEmGlobalParam(
        self.event_data.id,
        self.monster_role,
        self.legendary_id,
        e.get("app.QuestDef.RANK").EX,
        reward_rank
    )
    local ret = 0

    util_misc.try(function()
        ret = enemy_global_param:getOptionTagIdx(option_value)
    end, function(err)
        if not self.is_invalid then
            error(err)
        end
    end)

    return ret
end

---@protected
---@return string
function this:_get_monster_name()
    local guid = m.getEnemyName(self.event_data.id, self.monster_role, self.legendary_id)
    return game_lang.get_message_local(guid, game_lang.get_language(), true)
end

---@protected
function this:_adjust_legendary_id()
    --FIXME: silly way to detect if tempered/arch-tempered version of a monster exist in the game, couldnt find anything more sane
    local name = self:_get_monster_name()
    while name == "" and self.legendary_id >= 0 do
        self.legendary_id = self.legendary_id - 1
        name = self:_get_monster_name()
    end
end

---@protected
---@return string
function this:_get_em_param()
    if self.is_invalid then
        return "invalid"
    end

    return ace.map.pop_em_to_em_param_key[e.get("app.ExDef.POP_EM_TYPE_Fixed")[self.pop_em_type]]
end

return this
