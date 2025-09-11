local this = {
    gui = require("FieldEventSpawner.data.gui"),
    ace = require("FieldEventSpawner.data.ace.init"),
    runtime = require("FieldEventSpawner.data.runtime"),
}

-- ===== DEPRECATED =================================================================
local game_data = require("FieldEventSpawner.util.game.data")
this.util = {}
this.util.reverse_lookup = game_data.reverse_lookup

package.preload["FieldEventSpawner.util"] = function()
    local m = require("FieldEventSpawner.util.ref.methods")
    local game_lang = require("FieldEventSpawner.util.game.lang")

    local ret = {}
    ret.getRewardGradeFromDifficulty =
        m.get("app.EnemyUtil.getRewardGradeFromDifficulty(System.Guid)")
    ret.getRewardRankFromDifficulty =
        m.get("app.EnemyUtil.getRewardRankFromDifficulty(System.Guid)")
    ret.getEnemyNameGuid = m.get("app.EnemyDef.EnemyName(app.EnemyDef.ID)")
    ret.get_message_local = game_lang.get_message_local
    ret.get_language = game_lang.get_language
    return ret
end

package.preload["FieldEventSpawner.table_util"] = function()
    return require("FieldEventSpawner.util.misc.table")
end
-- ==================================================================================

---@return boolean
function this.init()
    return this.ace.init()
end

return this
