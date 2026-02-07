---@class ItemData : EventData
---@field id app.ItemDef.ID_Fixed
---@field id_not_fixed app.ItemDef.ID
---@field key string

local e = require("FieldEventSpawner.util.game.enum")
local game_lang = require("FieldEventSpawner.util.game.lang")
local m = require("FieldEventSpawner.util.ref.methods")

local this = {}

---@return ItemData[]
function this.get_data()
    ---@type ItemData[]
    local ret = {}
    local lang = game_lang.get_language()

    for _, item_id in e.iter("app.ItemDef.ID") do
        local item_data = m.getItemData(item_id)

        if not item_data or not m.isValidItem(item_id) then
            goto continue
        end

        local guid = item_data:get_RawName()
        local name_english = game_lang.get_message_local(guid, 1)
        ---@cast name_english string

        if name_english:len() == 0 then
            goto continue
        end

        table.insert(ret, {
            id = item_data:get_ItemId(),
            id_not_fixed = item_id,
            name_english = name_english,
            name_local = game_lang.get_message_local(guid, lang, true),
            key = string.format("%s_item_name", item_id),
        })
        ::continue::
    end
    return ret
end

return this
