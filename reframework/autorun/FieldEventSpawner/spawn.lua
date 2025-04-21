local event = require("FieldEventSpawner.events")

local this = {}

---@param monster_data MonsterData
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
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
---@return SpawnResult
function this.monster(
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
    local fac = event.monster:new(
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
    return fac:spawn()
end

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
---@return SpawnResult
function this.battlefield(
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
    local fac = event.battlefield:new(
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
    return fac:spawn()
end

---@param monster_data MonsterData
---@param monster_role app.EnemyDef.ROLE_ID
---@param pop_em_type app.ExDef.POP_EM_TYPE_Fixed
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param stage app.FieldDef.STAGE
---@param time integer
---@param is_village_boost boolean
---@param is_yummy boolean
---@param swarm_count integer
---@param area integer?,
---@param rewards GuiRewardData[]?
---@param difficulty System.Guid[]?
---@param environ app.EnvironmentType.ENVIRONMENT[]?
---@return SpawnResult
function this.swarm(
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
    rewards,
    difficulty,
    environ
)
    local fac = event.swarm:new(
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
        rewards,
        difficulty,
        environ
    )
    return fac:spawn()
end

---@param gimmick_data GimmickData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param ignore_environ_type boolean
---@param area integer?
---@return SpawnResult
function this.gimmick(gimmick_data, stage, time, ignore_environ_type, area)
    local fac = event.gimmick:new(gimmick_data, stage, time, ignore_environ_type, area)
    return fac:spawn()
end

---@param animal_data AnimalData
---@param stage app.FieldDef.STAGE
---@param time integer
---@param ignore_environ_type boolean
---@param area integer?
---@return SpawnResult
function this.animal(animal_data, stage, time, ignore_environ_type, area)
    local fac = event.animal:new(animal_data, stage, time, ignore_environ_type, area)
    return fac:spawn()
end

return this
