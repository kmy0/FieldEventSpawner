---@class ItemData : EventData
---@field id app.ItemDef.ID_Fixed
---@field id_not_fixed app.ItemDef.ID
---@field key string

local data_util = require("FieldEventSpawner.data.util")
local util = require("FieldEventSpawner.util")

local this = {}

---@return ItemData[]
function this.get_data()
    ---@type ItemData[]
    local ret = {}
    local item_ids = {}
    local lang = util.get_language()

    data_util.get_enum("app.ItemDef.ID", item_ids)
    for item_id, _ in pairs(item_ids) do
        local item_data = util.getItemData:call(nil, item_id)

        if not item_data or not util.isValidItem(nil, item_id) then
            goto continue
        end
        ---@cast item_data app.user_data.ItemData.cData

        local guid = item_data:get_RawName()
        local name_english = util.get_message_local(guid, 1)
        ---@cast name_english string

        if name_english:len() == 0 then
            goto continue
        end

        table.insert(ret, {
            id = item_data:get_ItemId(),
            id_not_fixed = item_id,
            name_english = name_english,
            name_local = util.get_message_local(guid, lang, true),
            key = string.format("%s_item_name", item_id),
        })
        ::continue::
    end
    return ret
end

return this
