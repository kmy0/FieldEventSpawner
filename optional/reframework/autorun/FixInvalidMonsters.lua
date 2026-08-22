---@diagnostic disable

local ok, m = pcall(require, "FieldEventSpawner.util.ref.methods")
if not ok then
    return
end

local s = require("FieldEventSpawner.util.ref.singletons")

local jindahaad_phases = {
    { 0.40, 4 },
    { 0.68, 3 },
    { 0.90, 2 },
}
local jindahaad_stage = 10
local gog_stage = 13

local function get_stage()
    local fieldman = s.get("app.MasterFieldManager")
    return fieldman:get_CurrentStage()
end

-- JIN DAHAAD
-- phase progression
m.hook("app.cEm0162_00Extend.doUpdateBegin()", function(args)
    if get_stage() ~= jindahaad_stage then
        local o = sdk.to_managed_object(args[2])
        local phase = o._QuestPhase

        local char = o:get_Character()
        local health_manager = char:get_HealthMgr()
        local health = health_manager:get_HealthNormalized()

        for _, p in ipairs(jindahaad_phases) do
            if health <= p[1] and phase < p[2] then
                o:changeQuestPhase(p[2])
            elseif phase >= p[2] then
                break
            end
        end
    end
end)
-- this function prevents damage to jin dahaad when he is moving trough areas, in this case it stopped dmg entirely
m.hook("app.cEm0162_00Extend.onDamageKeepHealth(System.Single, System.Single)", function(_)
    if get_stage() ~= jindahaad_stage then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end)

-- GOGMAZIOS
-- transition to last phase
m.hook("app.cEm0078_00Extend.doUpdateBegin()", function(args)
    if get_stage() ~= gog_stage then
        local o = sdk.to_managed_object(args[2])
        o._IsFinishAreaMove = true
    end
end)
-- npcs are stuck in the walls when gog transitions to last phase
m.hook(
    "app.NpcPartnerUtil.getEx02Phase(app.cEm0078_00Extend, app.Em0078_00_Def.PHASE)",
    nil,
    function(_)
        if get_stage() ~= gog_stage then
            return false
        end
    end
)
-- geyser positions are missing, so game crashes, they are hardcoded to the stage, not worth dealing with
m.hook("app.cEm0078_00Extend.opActivateGeyser()", function(args)
    if get_stage() ~= gog_stage then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end)

-- OMEGA
-- nerscylla does not exist, spawns barrier at players pos and finishes nuke timer
m.hook("app.cEm0166_00Extend.updateSpAtkCharge()", function(args)
    if get_stage() ~= jindahaad_stage then
        local o = sdk.to_managed_object(args[2])
        if not o._IsSpAtkCharge then
            return
        end

        local timer_charge = o._SpAtkChargeTimer
        if timer_charge._Timer > 0 and timer_charge._Timer < timer_charge._Limit then
            local master_player = s.get("app.PlayerManager"):getMasterPlayer()
            local char = master_player:get_Character()
            local pos = char:get_Pos()

            o:requestCreateBarrier(pos, Quaternion.new())
            o._SpAtkChargeTimer = timer_charge._Limit
        end
    end
end)
