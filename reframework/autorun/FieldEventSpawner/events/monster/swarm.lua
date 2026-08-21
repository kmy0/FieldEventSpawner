---@class (exact) SwarmEventFactory : MonsterEventFactory
---@field swarm_count integer

---@class (exact) SwarmData
---@field groupid integer
---@field route_hash integer
---@field area integer
---@field has_boss boolean

---@class (exact) SwarmEventFactoryOptionalArgs: MonsterEventFactoryOptionalArgs
---@field spoffer_unique_index nil
---@field spoffer_swarm boolean?

local config = require("FieldEventSpawner.config.init")
local e = require("FieldEventSpawner.util.game.enum")
local mod = require("FieldEventSpawner.data.mod")
local monster_factory = require("FieldEventSpawner.events.monster.monster")
local sched = require("FieldEventSpawner.schedule.init")
local util_game = require("FieldEventSpawner.util.game.init")
local util_table = require("FieldEventSpawner.util.misc.table")

---@class SwarmEventFactory
local this = {}
---@diagnostic disable-next-line: inject-field
this.__index = this
setmetatable(this, { __index = monster_factory })

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param swarm_count integer
---@param opts SwarmEventFactoryOptionalArgs?
---@return SwarmEventFactory
function this:new(
    monster_data,
    stage,
    time,
    monster_role,
    pop_em_type,
    legendary_id,
    swarm_count,
    opts
)
    opts = opts or {}
    opts.spoffer_unique_index = opts.spoffer_swarm and 0 or nil
    local o = monster_factory.new(
        self,
        monster_data,
        stage,
        time,
        monster_role,
        pop_em_type,
        legendary_id,
        opts
    )
    setmetatable(o, self)
    ---@cast o SwarmEventFactory
    o.swarm_count = swarm_count
    return o
end

---@return SpawnResult, MonsterSpawnEvent?
function this:build()
    ---@type SwarmData
    ---@diagnostic disable-next-line: missing-fields
    local swarm_data = { has_boss = self.monster_role == e.get("app.EnemyDef.ROLE_ID").BOSS }
    if not swarm_data.has_boss then
        self.is_village_boost = false
    end

    local res, leader_data = self:_build_leader(swarm_data)
    if res ~= mod.enum.spawn_result.OK then
        return res
    end
    ---@cast leader_data MonsterSpawnEvent

    local event_data = leader_data.event_data
    if self.legendary_id > 0 then
        event_data._FreeMiniValue0 = event_data._FreeMiniValue0 | (0x80 * self.legendary_id)
    end

    event_data._UniqueIndex = self._schedule_timeline:newEventUniqueIndex(self.stage)
    leader_data.cache_base.children = {}
    leader_data.args.swarm_indexes = { event_data._UniqueIndex }

    local member_data, member_rewards
    for _ = 1, self.swarm_count do
        res, member_rewards, member_data = self:_build_member(swarm_data)
        if res ~= mod.enum.spawn_result.OK then
            return res
        end
        ---@cast member_data ScheduledEvent
        ---@cast member_rewards ScheduledEvent[]

        table.insert(
            leader_data.cache_base.children,
            sched.spawn_event.make_child(
                member_data.event_data._UniqueIndex,
                { event_data = member_data.event_data, area = swarm_data.area }
            )
        )
        table.insert(leader_data.sub_events, member_data)
        leader_data.sub_events = util_table.array_merge(leader_data.sub_events, member_rewards)
        table.insert(leader_data.args.swarm_indexes, member_data.event_data._UniqueIndex)
    end

    leader_data.cache_base.name = string.format(
        "%s - %s (%s)",
        leader_data.cache_base.name,
        config.lang:tr("mod.text_em_swarm_suffix"),
        self.swarm_count
    )

    return mod.enum.spawn_result.OK, leader_data
end

---@param out SwarmData
---@return SpawnResult, MonsterSpawnEvent?
function this:_build_leader(out)
    local res, event = monster_factory.build(self)
    if res == mod.enum.spawn_result.OK then
        ---@cast event MonsterSpawnEvent
        out.area = event.event_data._FreeMiniValue3
        out.groupid = event.event_data._FreeMiniValue4
        out.route_hash = event.event_data._FreeValue3

        if event.args.spoffer_unique_index then
            event.args.spoffer_swarm = true
            event.args.spoffer_unique_index = nil
        end
    end
    return res, event
end

---@param swarm_data SwarmData
---@return SpawnResult, ScheduledEvent[]?, ScheduledEvent?
function this:_build_member(swarm_data)
    self.monster_role = e.get("app.EnemyDef.ROLE_ID").NORMAL
    self.pop_em_type = e.get("app.ExDef.POP_EM_TYPE_Fixed").SWARM
    self.is_village_boost = false
    self.is_yummy = false

    local em_pop_param = self:_get_em_pop_param()
    if not em_pop_param then
        return mod.enum.spawn_result.NO_EM_PARAM
    end

    local reward_data
    if swarm_data.has_boss then
        self.difficulty = em_pop_param:lotDifficultyID(self.legendary_id, 0, true)
        reward_data = self:_get_game_reward_data(self.difficulty)
    else
        self.difficulty = self.difficulty
            or em_pop_param:lotDifficultyID(self.legendary_id, 0, true)
        reward_data = self:_get_reward_data(self.difficulty)
    end

    if not self.difficulty then
        return mod.enum.spawn_result.NO_DIFFICULTY
    end

    if not reward_data then
        return mod.enum.spawn_result.NO_REWARDS
    end

    local event_data = sched.util.create_event_data()
    event_data._EventType = e.get("app.EX_FIELD_EVENT_TYPE").POP_EM
    event_data._FreeValue0 = e.to_fixed("app.EnemyDef.ID_Fixed", self.event_data.id)
    event_data._FreeValue1 = util_game.hash_guid(self.difficulty)
    event_data._FreeValue2 = e.to_fixed("app.FieldDef.STAGE_Fixed", self.stage)
    event_data._FreeValue3 = swarm_data.route_hash
    event_data._FreeValue4 = reward_data.reward_id1
    event_data._FreeValue5 = reward_data.reward_id2
    --FIXME: never actaully found where those values are set
    event_data._FreeMiniValue0 = (swarm_data.has_boss and 0x10 or 0x1C) | (0x80 * self.legendary_id)
    event_data._FreeMiniValue1 = mod.get_environ(self.stage)
        | (0x10 * e.get("app.ExDef.POP_EM_TYPE_Fixed").SWARM)
    event_data._FreeMiniValue2 = self.monster_role | (0x10 * self.legendary_id)
    event_data._FreeMiniValue3 = swarm_data.area
    event_data._FreeMiniValue4 = swarm_data.groupid
    event_data._FreeMiniValue5 = self.time
    event_data._FreeMiniValue6 = 255
    event_data._UniqueIndex = self._schedule_timeline:newEventUniqueIndex(self.stage)
    event_data._ExecMinute = self._schedule_timeline:get_AdvancedGameMinute() + self.spawn_delay

    return mod.enum.spawn_result.OK,
        sched.spawn_event.make_subevent(reward_data.reward_array),
        sched.spawn_event.make_subevent(event_data)[1]
end

---@protected
---@param em_pop_param  app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm
---@return System.Guid?
function this:_get_difficulty(em_pop_param)
    if self.monster_role == e.get("app.EnemyDef.ROLE_ID").BOSS then
        return em_pop_param:lotDifficultyID_Boss(self.legendary_id, true)
    end
    return monster_factory._get_difficulty(self, em_pop_param)
end

return this
