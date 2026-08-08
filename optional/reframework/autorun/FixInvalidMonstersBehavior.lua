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

-- JID DAHAAD
m.hook("app.cEm0162_00Extend.doUpdateBegin()", function(args)
    if get_stage() == jindahaad_stage then
        return
    end

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
end)
m.hook("app.cEm0162_00Extend.onDamageKeepHealth(System.Single, System.Single)", function(_)
    if get_stage() ~= jindahaad_stage then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end)

-- GOGMAZIOS
m.hook("app.cEm0078_00Extend.doUpdateBegin()", function(args)
    if get_stage() ~= gog_stage then
        local o = sdk.to_managed_object(args[2])
        o._IsFinishAreaMove = true
    end
end)
m.hook(
    "app.NpcPartnerUtil.getEx02Phase(app.cEm0078_00Extend, app.Em0078_00_Def.PHASE)",
    nil,
    function(_)
        if get_stage() ~= gog_stage then
            return false
        end
    end
)

-- Gm040
-- app.cEm1165_00Extend.requestCreateBarrier()
-- OMEGA
m.hook("app.cEm0166_00Extend.updateSpAtk()", function(args)
    if get_stage() ~= jindahaad_stage then
    end

    local o = sdk.to_managed_object(args[2])
    print(o:get_CurrentPhase())
    return sdk.PreHookResult.SKIP_ORIGINAL
end)
