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
function this.is_battlefield()
    local bf = state.combo.em_param:get()
    return bf == "battlefield_slay" or bf == "battlefield_repel"
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
function this.is_village_boost_disabled()
    return mod.is_in_quest()
        or not mod.is_village_boost_unlocked(mod.state.stage)
        or this.is_battlefield()
        or config.current.mod.swarm_count > 0 and state.combo.em_param:get() ~= "boss"
end

---@return boolean
function this.is_spoffer_swarm_disabled()
    local em_param = state.combo.em_param:get()

    return mod.is_in_quest()
        or not mod.is_spoffer_unlocked(mod.state.stage)
        or (em_param ~= "swarm" and em_param ~= "boss")
        or config.current.mod.swarm_count < 2
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
---@return integer?
function this.swap_with_disabled(combo, key_to_value, current_index, disabled_keys)
    key_to_value = util_table.deep_copy(key_to_value)
    key_to_value[-1] = -1
    local ret = combo:swap(key_to_value, current_index, disabled_keys)
    ret = combo:translate(ret)
    return ret
end

---@return System.Guid[]?
function this.get_monster_difficulties()
    local diff_table = this.get_monster_difficulties_table()
    if not diff_table then
        return
    end

    local em_difficulty = diff_table[state.combo.em_difficulty:get()]
    if not em_difficulty then
        return
    end

    return em_difficulty[state.combo.em_difficulty_rank:get()]
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
    local rank = combo.em_difficulty_rank:get()
    if rank then
        combo.em_difficulty_rank:get_key(config.current.mod.em_difficulty_rank)
        ret[rank] = util_table.deep_copy(diff_table[rank])
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

    for unique_id, candidate in pairs(mod.state.spoffer) do
        if
            not util_table.any(difficulties, function(key, _)
                return helpers.is_spoffer_pair(key, candidate.rank)
            end)
        then
            table.insert(ret, unique_id)
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
        return ret
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    for rank, guids in pairs(candidates) do
        if helpers.is_spoffer_pair(rank, spoffer_rank) then
            ret = util_table.merge(ret, guids)
        end
    end

    return util_table.unique(ret)
end

---@return AreaEventData
function this.get_current_event()
    return ace.event.by_stage[mod.state.stage][state.combo.event_type:get()][state.combo.event:get()]
end

function this.spawn()
    local combo = state.combo
    local config_mod = config.current.mod
    local event = this.get_current_event()
    local event_type = combo.event_type:get()

    if event_type == "monster" then
        ---@cast event MonsterData
        local em_param = combo.em_param:get()
        local role = gui.map.em_param_to_role[em_param]
        local role_id = e.get("app.EnemyDef.ROLE_ID")[role]
        local legendary = gui.map.em_param_mod_to_legendary[combo.em_param_mod:get()]
        local legendary_id = e.get("app.EnemyDef.LEGENDARY_ID")[legendary]
        local pop_em_type = gui.map.em_param_to_pop_em[em_param]
        local rewards = this.get_user_rewards()
        local environ = config_mod.is_ignore_environ
                and event.map[
                    mod.state.stage --[[@as app.FieldDef.STAGE]]
                ].env_by_param[em_param]
            or nil
        local spoffer = combo.spoffer:get()
        local difficulty = this.get_monster_difficulties()

        if spoffer and not difficulty then
            difficulty = this.get_valid_spoffer_difficulties()
        end

        if config_mod.swarm_count > 0 then
            return spawner.swarm(
                event,
                role_id,
                e.get("app.ExDef.POP_EM_TYPE_Fixed")[pop_em_type],
                legendary_id,
                mod.state.stage,
                config_mod.time,
                this.get_spawn_delay(),
                this.get_is_village_boost(),
                this.get_is_yummy(),
                config_mod.swarm_count,
                combo.area:get(),
                rewards,
                difficulty,
                environ,
                this.get_em_size(),
                this.get_is_spoffer_swarm()
            )
        elseif em_param == "battlefield_repel" or em_param == "battlefield_slay" then
            return spawner.battlefield(
                event,
                role_id,
                legendary_id,
                mod.state.stage,
                config_mod.time,
                this.get_is_yummy(),
                mod.enum.battlefield_state[em_param],
                combo.area:get(),
                rewards,
                difficulty,
                environ,
                this.get_em_size()
            )
        else
            return spawner.monster(
                event,
                role_id,
                e.get("app.ExDef.POP_EM_TYPE_Fixed")[pop_em_type],
                legendary_id,
                mod.state.stage,
                config_mod.time,
                this.get_spawn_delay(),
                this.get_is_village_boost(),
                this.get_is_yummy(),
                combo.area:get(),
                spoffer,
                rewards,
                difficulty,
                environ,
                this.get_em_size()
            )
        end
    elseif event_type == "gimmick" then
        ---@cast event GimmickData
        return spawner.gimmick(
            event,
            mod.state.stage,
            config_mod.time,
            this.get_spawn_delay(),
            config_mod.is_ignore_environ,
            combo.area:get()
        )
    elseif event_type == "animal" then
        ---@cast event AnimalData
        return spawner.animal(
            event,
            mod.state.stage,
            config_mod.time,
            this.get_spawn_delay(),
            config_mod.is_ignore_environ,
            combo.area:get()
        )
    end
end

return this
