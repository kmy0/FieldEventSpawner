local data_ace = require("FieldEventSpawner.data.ace.init")
local game_data = require("FieldEventSpawner.util.game.data")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")
local util_table = require("FieldEventSpawner.util.misc.table")

local rl = game_data.reverse_lookup

local this = {}

---@param pop_em app.cExFieldEvent_PopEnemy
---@return string
function this.get_monster_name(pop_em)
    local id = pop_em:get_EmID()
    local guid
    local _FreeMiniValue2 = pop_em:get_FreeMiniValue2()

    if _FreeMiniValue2 >> 0 == rl(data_ace.enum.em_role, "BOSS") then
        guid = m.getEnemyExtraName(id)
    elseif _FreeMiniValue2 >> 0 == rl(data_ace.enum.em_role, "FRENZY") then
        guid = m.getEnemyFrenzyName(id)
    elseif _FreeMiniValue2 >> 4 == rl(data_ace.enum.legendary, "NORMAL") then
        guid = m.getEnemyLegendaryName(id)
    elseif _FreeMiniValue2 >> 4 == rl(data_ace.enum.legendary, "KING") then
        guid = m.getEnemyLegendaryKingName(id)
    else
        guid = m.getEnemyNameGuid(id)
    end
    return game_lang.get_message_local(guid, game_lang.get_language(), true)
end

---@param first app.QuestDef.EM_REWARD_RANK
---@param second app.QuestDef.EM_REWARD_RANK
---@return boolean
function this.is_spoffer_pair(first, second)
    local key = util_table.sort({ first, second })
    local ret = data_ace.map.spoffer_pairings[string.format("%s,%s", table.unpack(key))]
    return ret or ret == nil
end

return this
