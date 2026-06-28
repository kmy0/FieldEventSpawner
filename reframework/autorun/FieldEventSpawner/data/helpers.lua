local ace = require("FieldEventSpawner.data.ace.init")
local e = require("FieldEventSpawner.util.game.enum")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")
local util_table = require("FieldEventSpawner.util.misc.table")

local this = {}

---@param pop_em app.cExFieldEvent_PopEnemy
---@return string
function this.get_monster_name(pop_em)
    local id = pop_em:get_EmID()
    local guid
    local _FreeMiniValue2 = pop_em:get_FreeMiniValue2()

    if _FreeMiniValue2 >> 0 == e.get("app.EnemyDef.ROLE_ID").BOSS then
        guid = m.getEnemyExtraName(id)
    elseif _FreeMiniValue2 >> 0 == e.get("app.EnemyDef.ROLE_ID").FRENZY then
        guid = m.getEnemyFrenzyName(id)
    elseif _FreeMiniValue2 >> 4 == e.get("app.EnemyDef.LEGENDARY_ID").NORMAL then
        guid = m.getEnemyLegendaryName(id)
    elseif _FreeMiniValue2 >> 4 == e.get("app.EnemyDef.LEGENDARY_ID").KING then
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
    local ret = ace.map.spoffer_pairings[string.format("%s,%s", table.unpack(key))]
    return ret or ret == nil
end

---@param query string
---@return table<string, string>
function this.filter_item_rewards(query)
    local ret = {}

    if query == "" then
        return ace.map.item_key_to_name_local
    end

    local number = tonumber(query)
    local predicate = function(key)
        if number then
            return ace.item.by_key[key].id_not_fixed == number
        end

        local query_lower = query:lower()
        local name_lower = ace.item.by_key[key].name_local:lower()
        return name_lower:find(query_lower) ~= nil
    end

    for k, v in pairs(ace.map.item_key_to_name_local) do
        if predicate(k) then
            ret[k] = v
        end
    end

    return ret
end

return this
