local cache = require("FieldEventSpawner.util.misc.cache")
local game_util = require("FieldEventSpawner.util.game.util")
local util_misc = require("FieldEventSpawner.util.misc.init")
---@class MethodUtil
local m = require("FieldEventSpawner.util.ref.methods")

m.getMessageLocal = m.wrap(m.get("via.gui.message.get(System.Guid, via.Language)")) --[[@as fun(guid: System.Guid, lang: via.Language): System.String]]
m.getGuidByName = m.wrap(m.get("via.gui.message.getGuidByName(System.String)")) --[[@as fun(guid_name: System.String): System.Guid]]
m.messageTagReplace =
    m.wrap(m.get("app.cGUIMessageTagReplacer.messageTagReplace(System.String, System.String)")) --[[@as fun(tag_type: System.String, tag: System.String): System.String]]
m.ExtractTags = m.wrap(m.get("via.relib.GUI.MessageTag.ExtractTags(System.String)")) --[[@as fun(str: System.String): System.Array<System.String>]]
m.ExtractTagName = m.wrap(m.get("via.relib.GUI.MessageTag.ExtractTagName(System.String)")) --[[@as fun(tag: System.String): System.String]]
m.ExtractTagArg = m.wrap(m.get("via.relib.GUI.MessageTag.ExtractTagArg(System.String)")) --[[@as fun(tag: System.String): System.String]]

local this = {}
local msg_id = {
    extract_pattern = "<REF (.-)>",
    strip_pattern = "(<REF.->)",
    bad_pattern = "#Rejected#",
}

---@param str string
---@return string
function this.replace_tags(str)
    local tags = m.ExtractTags(str)
    ---@type table<string, string>
    local replace = {}
    local lang = this.get_language()

    game_util.do_something(tags, function(_, _, value)
        local tag = m.ExtractTagName(value)
        local arg = m.ExtractTagArg(value)
        local text = m.messageTagReplace(tag, arg)

        if text == "" then
            util_misc.try(function()
                text = this.get_message_local_from_name(
                    value:match(msg_id.extract_pattern),
                    lang,
                    true
                )
            end)
        end

        replace[value] = text
    end)

    for tag, msg in pairs(replace) do
        str = str:gsub(tag, msg)
    end

    return str
end

---@param guid_name string
---@param lang via.Language
---@param fallback boolean?
---@return string
function this.get_message_local_from_name(guid_name, lang, fallback)
    local msg_guid = m.getGuidByName(guid_name)
    return this.get_message_local(msg_guid, lang, fallback)
end

---@param guid System.Guid
---@param lang via.Language
---@param fallback boolean?
---@return string
function this.get_message_local(guid, lang, fallback)
    local parts = {}
    local msg = m.getMessageLocal(guid, lang)
    for match in msg:gmatch(msg_id.extract_pattern) do
        local part = this.get_message_local_from_name(match, lang, fallback)
        if part:len() > 0 then
            table.insert(parts, part)
        end
    end

    msg = msg:gsub(msg_id.strip_pattern, "")
    table.insert(parts, msg)
    msg = table.concat(parts, " "):gsub("^%s*(.-)%s*$", "%1")

    if msg:len() == 0 and fallback then
        return this.get_message_local(guid, 1)
    elseif msg:match(msg_id.bad_pattern) then
        return ""
    end
    return msg
end

---@param guid System.Guid
---@return string
function this.get_message_local2(guid)
    local lang = this.get_language()
    return this.get_message_local(guid, lang, true)
end

---@return via.Language
function this.get_language()
    return sdk.call_native_func(
        sdk.get_native_singleton("via.gui.GUISystem"),
        sdk.find_type_definition("via.gui.GUISystem") --[[@as RETypeDefinition]],
        "get_MessageLanguage()"
    )
end

this.get_language = cache.memoize(this.get_language)

return this
