local event = require("FieldEventSpawner.events.init")

local this = {}

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type  app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param opts MonsterEventFactoryOptionalArgs?
---@return SpawnResult
function this.monster(monster_data, stage, time, monster_role, pop_em_type, legendary_id, opts)
    local fac =
        event.monster:new(monster_data, stage, time, monster_role, pop_em_type, legendary_id, opts)
    return fac:spawn()
end

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param monster_role app.EnemyDef.ROLE_ID
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param battlefield_state BattlefieldState
---@param opts BattlefieldEventFactoryOptionalArgs?
---@return SpawnResult
function this.battlefield(
    monster_data,
    stage,
    time,
    monster_role,
    legendary_id,
    battlefield_state,
    opts
)
    local fac = event.battlefield:new(
        monster_data,
        stage,
        time,
        monster_role,
        legendary_id,
        battlefield_state,
        opts
    )
    return fac:spawn()
end

---@param monster_data MonsterData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param swarm_count integer
---@param opts SwarmEventFactoryOptionalArgs?
---@return SpawnResult
function this.swarm(
    monster_data,
    stage,
    time,
    monster_role,
    pop_em_type,
    legendary_id,
    swarm_count,
    opts
)
    local fac = event.swarm:new(
        monster_data,
        stage,
        time,
        monster_role,
        pop_em_type,
        legendary_id,
        swarm_count,
        opts
    )
    return fac:spawn()
end

---@param gimmick_data GimmickData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param opts GimmickEventFactoryOptionalArgs?
---@return SpawnResult
function this.gimmick(gimmick_data, stage, time, opts)
    local fac = event.gimmick:new(gimmick_data, stage, time, opts)
    return fac:spawn()
end

---@param animal_data AnimalData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param opts AnimalEventFactoryOptionalArgs?
---@return SpawnResult
function this.animal(animal_data, stage, time, opts)
    local fac = event.animal:new(animal_data, stage, time, opts)
    return fac:spawn()
end

return this
