---@class (exact) SwarmEventFactory : MonsterEventFactory
---@field swarm_count integer
---@field protected __index SwarmEventFactory

---@class (exact) SwarmData
---@field groupid integer
---@field route_hash integer
---@field area integer
---@field has_boss boolean

local data = require("FieldEventSpawner.data")
local lang = require("FieldEventSpawner.lang")
local monster_factory = require("FieldEventSpawner.events.monster.monster")
local sched = require("FieldEventSpawner.schedule")
local table_util = require("FieldEventSpawner.table_util")
local util = require("FieldEventSpawner.util")

local rl = data.util.reverse_lookup
local rt = data.runtime
local ace = data.ace

---@class SwarmEventFactory
local this = {}
this.__index = this
setmetatable(this, { __index = monster_factory })

---@param monster_data MonsterData
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param stage app.FieldDef.STAGE
---@param time integer
---@param is_village_boost boolean
---@param is_yummy boolean
---@param swarm_count integer
---@param area integer?
---@param rewards GuiRewardData[]?
---@param environ app.EnvironmentType.ENVIRONMENT[]?
---@return SwarmEventFactory
function this:new(
    monster_data,
    monster_role,
    pop_em_type,
    legendary_id,
    stage,
    time,
    is_village_boost,
    is_yummy,
    swarm_count,
    area,
    environ
)
    local o = monster_factory.new(
        self,
        monster_data,
        monster_role,
        pop_em_type,
        legendary_id,
        stage,
        time,
        is_village_boost,
        is_yummy,
        area,
        nil,
        environ
    )
    setmetatable(o, self)
    ---@cast o SwarmEventFactory
    o.swarm_count = swarm_count

    if pop_em_type == rl(ace.enum.pop_em_fixed, "LEGENDARY") then
        o.monster_role = rl(ace.enum.em_role, "BOSS")
    elseif monster_role == rl(ace.enum.em_role, "BOSS") then
        o.pop_em_type = rl(ace.enum.pop_em_fixed, "SWARM")
    end
    return o
end

---@return SpawnResult, MonsterSpawnEvent?
function this:build()
    ---@type SwarmData
    ---@diagnostic disable-next-line: missing-fields
    local swarm_data = { has_boss = self.monster_role == rl(ace.enum.em_role, "BOSS") }
    if not swarm_data.has_boss then
        self.is_village_boost = false
    end

    local res, leader_data = self:_build_leader(swarm_data)
    if res ~= rt.enum.spawn_result.OK then
        return res
    end
    ---@cast leader_data MonsterSpawnEvent

    leader_data.cache_base.children = {}
    local member_data, member_rewards
    for _ = 1, self.swarm_count do
        res, member_rewards, member_data = self:_build_member(swarm_data)
        if res ~= rt.enum.spawn_result.OK then
            return res
        end
        ---@cast member_data ScheduledEvent
        ---@cast member_rewards ScheduledEvent[]

        table.insert(
            leader_data.cache_base.children,
            sched.spawn_event.child_ctor(member_data.event_data._UniqueIndex, member_data.event_data, swarm_data.area)
        )
        table.insert(leader_data.sub_events, member_data)
        leader_data.sub_events = table_util.array_merge(leader_data.sub_events, member_rewards)
    end

    leader_data.cache_base.name =
        string.format("%s - %s (%s)", leader_data.cache_base.name, lang.tr("em_swarm_suffix.name"), self.swarm_count)

    return rt.enum.spawn_result.OK, leader_data
end

---@param out SwarmData
---@return SpawnResult, MonsterSpawnEvent?
function this:_build_leader(out)
    local res, event = monster_factory.build(self)
    if res == rt.enum.spawn_result.OK then
        ---@cast event MonsterSpawnEvent
        out.area = event.event_data._FreeMiniValue3
        out.groupid = event.event_data._FreeMiniValue4
        out.route_hash = event.event_data._FreeValue3

        if self.pop_em_type == rl(ace.enum.pop_em_fixed, "LEGENDARY") then
            event.event_data._FreeMiniValue1 = rt.get_environ(self.stage) | (0x10 * rl(ace.enum.pop_em_fixed, "SWARM"))
        end
    end
    return res, event
end

---@param swarm_data SwarmData
---@return SpawnResult, ScheduledEvent[]?, ScheduledEvent?
function this:_build_member(swarm_data)
    self.monster_role = rl(ace.enum.em_role, "NORMAL")
    self.legendary_id = rl(ace.enum.legendary, "NONE")
    self.pop_em_type = rl(ace.enum.pop_em_fixed, "SWARM")
    self.is_village_boost = false
    self.is_yummy = false

    local em_pop_param = self:_get_em_pop_param()
    if not em_pop_param then
        return rt.enum.spawn_result.NO_EM_PARAM
    end

    local difficulty_guid = em_pop_param:lotDifficultyID(self.legendary_id, 0, true)
    if not difficulty_guid then
        return rt.enum.spawn_result.NO_DIFFICULTY
    end

    local reward_data = self:_get_game_reward_data(difficulty_guid, false, false)

    local event_data = sched.util.create_event_data()
    event_data._EventType = rl(ace.enum.ex_event, "POP_EM")
    event_data._FreeValue0 = util.getEnemyIdFixed:call(nil, self.event_data.id)
    event_data._FreeValue1 = util.hash_guid(difficulty_guid)
    event_data._FreeValue2 = util.get_stage_id_fixed(self.stage)
    event_data._FreeValue3 = swarm_data.route_hash
    event_data._FreeValue4 = reward_data.reward_id1
    event_data._FreeValue5 = reward_data.reward_id2
    event_data._FreeMiniValue0 = swarm_data.has_boss and 0x10 or 0x1C
    event_data._FreeMiniValue1 = rt.get_environ(self.stage) | (0x10 * rl(ace.enum.pop_em_fixed, "SWARM"))
    event_data._FreeMiniValue2 = self.monster_role
    event_data._FreeMiniValue3 = swarm_data.area
    event_data._FreeMiniValue4 = swarm_data.groupid
    event_data._FreeMiniValue5 = self.time
    event_data._FreeMiniValue6 = 255
    event_data._UniqueIndex = self._schedule_timeline:newEventUniqueIndex(self.stage)
    event_data._ExecMinute = self._schedule_timeline:get_AdvancedGameMinute()

    return rt.enum.spawn_result.OK,
        sched.spawn_event.subevent_ctor(reward_data.reward_array),
        sched.spawn_event.subevent_ctor(event_data)[1]
end

---@protected
---@param em_pop_param  app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm
---@return System.Guid
function this:_get_difficulty(em_pop_param)
    if self.pop_em_type == ace.enum.pop_em_fixed["SWARM"] then
        return em_pop_param:lotDifficultyID_Boss(self.legendary_id, true)
    end
    return monster_factory._get_difficulty(self, em_pop_param)
end

return this
