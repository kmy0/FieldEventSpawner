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
---@param ignore_environ_type boolean
---@param area integer?
---@param spoffer integer?
---@param rewards GuiRewardData[]?
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
    ignore_environ_type,
    area,
    spoffer,
    rewards
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
        ignore_environ_type,
        area,
        spoffer,
        rewards
    )
    return fac:spawn()
end

---@param monster_data MonsterData
---@param monster_role app.EnemyDef.ROLE_ID
---@param legendary_id app.EnemyDef.LEGENDARY_ID
---@param stage app.FieldDef.STAGE
---@param time integer
---@param is_yummy boolean
---@param ignore_environ_type boolean
---@param battlefield_state BattlefieldState
---@param area integer?
---@param rewards GuiRewardData[]?
---@return SpawnResult
function this.battlefield(
    monster_data,
    monster_role,
    legendary_id,
    stage,
    time,
    is_yummy,
    ignore_environ_type,
    battlefield_state,
    area,
    rewards
)
    local fac = event.battlefield:new(
        monster_data,
        monster_role,
        legendary_id,
        stage,
        time,
        is_yummy,
        ignore_environ_type,
        battlefield_state,
        area,
        rewards
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
---@param ignore_environ_type boolean
---@param swarm_count integer
---@param area integer?,
---@param rewards GuiRewardData[]?
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
    ignore_environ_type,
    swarm_count,
    area,
    rewards
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
        ignore_environ_type,
        swarm_count,
        area,
        rewards
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
