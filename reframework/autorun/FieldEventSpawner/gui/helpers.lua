local ace = require("FieldEventSpawner.data.ace.init")
local config = require("FieldEventSpawner.config.init")
local e = require("FieldEventSpawner.util.game.enum")
local gui = require("FieldEventSpawner.data.gui")
local helpers = require("FieldEventSpawner.data.helpers")
local m = require("FieldEventSpawner.util.ref.methods")
local mod = require("FieldEventSpawner.data.mod")
local spawner = require("FieldEventSpawner.schedule.spawner")
local state = require("FieldEventSpawner.gui.state")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {}

---@return boolean
function this.is_battlefield_monster()
    local event = this.get_current_event()
    if not event or not event:is_monster_event() then
        return false
    end

    ---@cast event MonsterData

    local em_param = state.combo.em_param:get()
    return em_param == "battlefield_slay"
        or em_param == "battlefield_repel"
        or em_param == "invalid" and event:is_battlefield()
end

---@return boolean
function this.is_battlefield_monster_current_stage()
    local event = this.get_current_event()
    if not event or not event:is_monster_event() then
        return false
    end
    ---@cast event MonsterData
    return event:is_battlefield_current_stage()
end

---@return boolean
function this.is_em_size_disabled()
    return not state.combo.em_difficulty:get()
        or state.em_size_min == state.em_size_max
        or config.current.mod.spawn_delay > 0
end

---@return boolean
function this.is_swarm_count_disabled()
    local em_param = state.combo.em_param:get()
    local ret = (em_param ~= "swarm" and em_param ~= "boss")
    if ret then
        return ret
    end

    if em_param == "legendary" then
        local event = this.get_current_event()
        if not event or not event:is_monster_event() then
            return true
        end
        ---@cast event MonsterData
        local param = event:get_param_struct(
            mod.state.stage,
            not config.current.mod.is_ignore_environ and mod.state.environ or nil
        ) or {}
        return not param.boss
    end

    return false
end

---@return boolean
function this.is_spawn_delay_disabled()
    return state.combo.spoffer:get() ~= nil
end

---@return boolean
function this.is_yummy_disabled()
    return mod.is_in_quest() or state.combo.quest_rewards:get() == "user_defined"
end

---@return boolean
function this.is_reward_max()
    return state.combo.quest_rewards:get() == "random_max"
end

---@return boolean
function this.is_village_boost_disabled()
    return mod.is_in_quest()
        or not mod.is_village_boost_unlocked(mod.state.stage)
        or this.is_battlefield_monster()
        or this.get_swarm_count() > 0 and state.combo.em_param:get() ~= "boss"
end

---@return boolean
function this.is_spoffer_swarm_disabled()
    local em_param = state.combo.em_param:get()

    return mod.is_in_quest()
        or not mod.is_spoffer_unlocked(mod.state.stage)
        or (em_param ~= "swarm" and em_param ~= "boss")
        or state.swarm_count_array[config:get("mod.swarm_count")] < 2
        or config.current.mod.spawn_delay > 0
end

---@return boolean
function this.get_is_spoffer_swarm()
    if this.is_spoffer_swarm_disabled() then
        return false
    end

    return config.current.mod.is_spoffer_swarm
end

---@return boolean
function this.get_is_yummy()
    if this.is_yummy_disabled() then
        return false
    end

    return config.current.mod.is_yummy
end

---@return boolean
function this.get_is_village_boost()
    if this.is_village_boost_disabled() then
        return false
    end

    return config.current.mod.is_village_boost
end

---@return integer?
function this.get_em_size()
    if this.is_em_size_disabled() then
        return
    end

    local ret = config.current.mod.em_size
    if ret == -1 then
        return
    end

    return ret + state.em_size_min
end

---@return number
function this.get_spawn_delay()
    if this.is_spawn_delay_disabled() then
        return 0
    end

    return m.realSec_to_GameMinute(config.current.mod.spawn_delay * 60 * 1.0)
end

---@return GuiRewardData[]?
function this.get_user_rewards()
    if mod.is_in_quest() then
        return
    end

    return state.combo.quest_rewards:get() == "user_defined"
            and config.current.mod.reward_config.array
        or nil
end

---@param combo Combo
---@return boolean
function this.is_combo_empty(combo)
    return #combo.map == 1 and combo.map[1].key == -1
end

---@param combo Combo
---@param key_to_value table
---@param current_index integer?
---@param disabled_keys any[]?
---@param is_init boolean?
---@param insert_dummy boolean? by default, true
---@return integer?
function this.swap_with_disabled(
    combo,
    key_to_value,
    current_index,
    disabled_keys,
    is_init,
    insert_dummy
)
    key_to_value = util_table.deep_copy(key_to_value)
    insert_dummy = insert_dummy == nil and true or false
    if insert_dummy then
        key_to_value[-1] = -1
    end

    local ret
    if is_init then
        ret = combo:swap_init(key_to_value, current_index, disabled_keys)
    else
        ret = combo:swap(key_to_value, current_index, disabled_keys)
    end

    return ret
end

---@return table<integer, table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>>?
function this.get_monster_difficulties_table()
    local event = this.get_current_event()
    if not event or not state.combo.em_param:get() or not state.combo.em_param_mod:get() then
        return
    end

    ---@cast event MonsterData
    return event:get_difficulty_table(
        mod.state.stage,
        not config.current.mod.is_ignore_environ and mod.state.environ or nil,
        state.combo.em_param:get(),
        state.combo.em_param_mod:get()
    )
end

---@return table<app.QuestDef.EM_REWARD_RANK, System.Guid[]>?
function this.get_monster_all_difficulties()
    local combo = state.combo
    local diff_table = this.get_monster_difficulties_table()
    if not diff_table then
        return
    end

    local ret = {}
    local guid = combo.em_difficulty_rank:get()
    if guid then
        ret[m.getRewardRankFromDifficulty(guid)] = { guid }
    else
        for _, difs in pairs(diff_table) do
            for rank, guids in pairs(difs) do
                if not ret[rank] then
                    ret[rank] = util_table.deep_copy(guids)
                else
                    util_table.merge_t(ret[rank], util_table.deep_copy(guids))
                end
            end
        end

        for k, v in pairs(ret) do
            ret[k] = util_table.unique(v)
        end
    end

    return ret
end

---@return integer[]
function this.get_spoffer_disabled_keys()
    local ret = {}
    local difficulties = this.get_monster_all_difficulties()
    if not difficulties then
        return ret
    end

    local event = this.get_current_event()
    if not event or not event:is_monster_event() then
        return util_table.keys(mod.state.spoffer)
    end

    ---@cast event MonsterData
    local difficulty = state.combo.em_difficulty_rank:get()
    local role = state.combo.em_role:get()
    if helpers.is_invalid_em2(event, difficulty, role) then
        return util_table.keys(mod.state.spoffer)
    elseif difficulty then
        local rank = m.getRewardRankFromDifficulty(difficulty)
        for unique_id, candidate in pairs(mod.state.spoffer) do
            if not helpers.is_spoffer_pair(rank, candidate.rank) then
                table.insert(ret, unique_id)
            end
        end
    else
        for unique_id, candidate in pairs(mod.state.spoffer) do
            if
                not util_table.any(difficulties, function(key, _)
                    return helpers.is_spoffer_pair(key, candidate.rank)
                end)
            then
                table.insert(ret, unique_id)
            end
        end
    end

    return ret
end

---@return System.Guid[]?
function this.get_valid_spoffer_difficulties()
    local candidates = this.get_monster_all_difficulties()
    local spoffer_rank = mod.state.spoffer[state.combo.spoffer:get()].rank
    local ret = {}

    if not candidates then
        return
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    for rank, guids in pairs(candidates) do
        if helpers.is_spoffer_pair(rank, spoffer_rank) then
            ret = util_table.merge(ret, guids)
        end
    end

    return util_table.pick_random_value(ret)
end

---@return AreaEventData?
function this.get_current_event()
    local all_events = ace.event.by_stage[mod.state.stage]
    if not all_events then
        return
    end

    local events = all_events[state.combo.event_type:get()]
    if not events then
        return
    end

    return events[state.combo.event:get()]
end

---@return System.Guid?
function this.get_difficulty()
    local spoffer_unique_index = state.combo.spoffer:get()
    local ret = state.combo.em_difficulty_rank:get()

    if spoffer_unique_index and not ret then
        ret = this.get_valid_spoffer_difficulties()
    end

    return ret
end

---@return app.EnemyDef.LEGENDARY_ID
function this.get_legendary_id()
    local legendary = gui.map.em_param_mod_to_legendary[state.combo.em_param_mod:get()]
    return e.get("app.EnemyDef.LEGENDARY_ID")[legendary]
end

---@return app.ExDef.POP_EM_TYPE_Fixed
function this.get_pop_em_type()
    local em_param = state.combo.em_param:get()
    local pop_em_type = gui.map.em_param_to_pop_em[em_param]
    return e.get("app.ExDef.POP_EM_TYPE_Fixed")[pop_em_type]
end

---@return BattlefieldState
function this.get_battlefield_state()
    local event = this.get_current_event() --[[@as MonsterData]]
    return helpers.is_invalid_em2(event, this.get_difficulty(), state.combo.em_role:get())
            and mod.enum.battlefield_state["battlefield_slay"]
        or mod.enum.battlefield_state[state.combo.em_param:get()]
end

---@return integer
function this.get_swarm_count()
    local ret = state.swarm_count_array[config.current.mod.swarm_count]
    return ret - 1
end

function this.spawn()
    local combo = state.combo
    local config_mod = config.current.mod
    local event = this.get_current_event()
    local event_type = combo.event_type:get()

    if event_type == "monster" then
        ---@cast event MonsterData

        if this.get_swarm_count() > 0 then
            return spawner.swarm(
                event,
                mod.state.stage,
                config_mod.time,
                combo.em_role:get(),
                this.get_pop_em_type(),
                this.get_legendary_id(),
                this.get_swarm_count(),
                {
                    spawn_delay = this.get_spawn_delay(),
                    is_village_boost = this.get_is_village_boost(),
                    is_yummy = this.get_is_yummy(),
                    area = combo.area:get(),
                    rewards = this.get_user_rewards(),
                    difficulty = this.get_difficulty(),
                    environ = event:get_environ(mod.state.stage, combo.em_param:get()),
                    size = this.get_em_size(),
                    spoffer_swarm = this.get_is_spoffer_swarm(),
                    option_tag = combo.em_option_tag:get(),
                    is_reward_max = this.is_reward_max(),
                }
            )
        elseif this.is_battlefield_monster_current_stage() then
            return spawner.battlefield(
                event,
                mod.state.stage,
                config_mod.time,
                combo.em_role:get(),
                this.get_legendary_id(),
                this.get_battlefield_state(),
                {
                    is_yummy = this.get_is_yummy(),
                    area = combo.area:get(),
                    rewards = this.get_user_rewards(),
                    difficulty = this.get_difficulty(),
                    environ = event:get_environ(mod.state.stage, combo.em_param:get()),
                    size = this.get_em_size(),
                    option_tag = combo.em_option_tag:get(),
                    is_reward_max = this.is_reward_max(),
                }
            )
        else
            return spawner.monster(
                event,
                mod.state.stage,
                config_mod.time,
                combo.em_role:get(),
                this.get_pop_em_type(),
                this.get_legendary_id(),
                {
                    spawn_delay = this.get_spawn_delay(),
                    is_village_boost = this.get_is_village_boost(),
                    is_yummy = this.get_is_yummy(),
                    area = combo.area:get(),
                    spoffer_unique_index = combo.spoffer:get(),
                    rewards = this.get_user_rewards(),
                    difficulty = this.get_difficulty(),
                    environ = event:get_environ(mod.state.stage, combo.em_param:get()),
                    size = this.get_em_size(),
                    option_tag = combo.em_option_tag:get(),
                    is_reward_max = this.is_reward_max(),
                }
            )
        end
    elseif event_type == "gimmick" then
        ---@cast event GimmickData
        return spawner.gimmick(event, mod.state.stage, config_mod.time, {
            spawn_delay = this.get_spawn_delay(),
            ignore_environ_type = config_mod.is_ignore_environ,
            area = combo.area:get(),
        })
    elseif event_type == "animal" then
        ---@cast event AnimalData
        return spawner.animal(event, mod.state.stage, config_mod.time, {
            spawn_delay = this.get_spawn_delay(),
            ignore_environ_type = config_mod.is_ignore_environ,
            area = combo.area:get(),
        })
    end
end

return this
