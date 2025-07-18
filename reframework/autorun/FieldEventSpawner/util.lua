local this = {}

local msg_id = {
    extract_pattern = "<REF (.-)>",
    strip_pattern = "(<REF.->)",
    bad_pattern = "#Rejected#",
}

this.getEnemyNameGuid = sdk.find_type_definition("app.EnemyDef"):get_method("EnemyName(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getMessageLocal = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid, via.Language)") --[[@as REMethodDefinition]]
this.getGuidByName = sdk.find_type_definition("via.gui.message"):get_method("getGuidByName(System.String)") --[[@as REMethodDefinition]]
this.getRewardRankFromDifficulty = sdk.find_type_definition("app.EnemyUtil")
    :get_method("getRewardRankFromDifficulty(System.Guid)") --[[@as REMethodDefinition]]
this.getRewardGradeFromDifficulty = sdk.find_type_definition("app.EnemyUtil")
    :get_method("getRewardGradeFromDifficulty(System.Guid)") --[[@as REMethodDefinition]]
this.getEnemyIdFixed = sdk.find_type_definition("app.EnemyDef"):get_method("enemyId(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getFixedFromSTAGE = sdk.find_type_definition("app.FieldDef"):get_method("getFixedFromSTAGE") --[[@as REMethodDefinition]]
this.isBossID = sdk.find_type_definition("app.EnemyDef"):get_method("isBossID(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.isEmValid = sdk.find_type_definition("app.EnemyDef"):get_method("isValid(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getEnemyLegendaryName = sdk.find_type_definition("app.EnemyDef"):get_method("EnemyLegendaryName(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getEnemyLegendaryKingName = sdk.find_type_definition("app.EnemyDef")
    :get_method("EnemyLegendaryKingName(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getEnemyFrenzyName = sdk.find_type_definition("app.EnemyDef"):get_method("EnemyFrenzyName(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getEnemyExtraName = sdk.find_type_definition("app.EnemyDef"):get_method("EnemyExtraName(app.EnemyDef.ID)") --[[@as REMethodDefinition]]
this.getGimmickEventName = sdk.find_type_definition("app.ExDef"):get_method("Name(app.ExDef.GIMMICK_EVENT)") --[[@as REMethodDefinition]]
this.getFixedFromGIMMICK_EVENT = sdk.find_type_definition("app.ExDef"):get_method(
    "getFixedFromGIMMICK_EVENT(app.ExDef.GIMMICK_EVENT, app.ExDef.GIMMICK_EVENT_Fixed)"
) --[[@as REMethodDefinition]]
this.getGIMMICK_EVENTFromFixed = sdk.find_type_definition("app.ExDef"):get_method("getGIMMICK_EVENTFromFixed") --[[@as REMethodDefinition]]
this.getFixedFromANIMAL_EVENT = sdk.find_type_definition("app.ExDef"):get_method(
    "getFixedFromANIMAL_EVENT(app.ExDef.ANIMAL_EVENT, app.ExDef.ANIMAL_EVENT_Fixed)"
) --[[@as REMethodDefinition]]
this.getAnimalEventName = sdk.find_type_definition("app.ExDef"):get_method("AnimalEventName(app.ExDef.ANIMAL_EVENT)") --[[@as REMethodDefinition]]
this.getUTCTime = sdk.find_type_definition("app.QuestUtil"):get_method("getUTCTime()") --[[@as REMethodDefinition]]
this.getGimmickID = sdk.find_type_definition("app.ExDef"):get_method("GimmickID(app.ExDef.GIMMICK_EVENT)") --[[@as REMethodDefinition]]
this.lotExRewardPopEnemy = sdk.find_type_definition("app.ExQuestRewardUtil"):get_method(
    "lotExRewardItemList(System.Collections.Generic.List`1<app.savedata.cItemWork>, System.Collections.Generic.List`1<System.Boolean>, System.Byte[], System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Boolean)"
) --[[@as REMethodDefinition]]
this.createEventInstance = sdk.find_type_definition("app.ExFieldUtil")
    :get_method("createEventInstance(app.cExFieldScheduleExportData.cEventData)") --[[@as REMethodDefinition]]
this.getItemData = sdk.find_type_definition("app.ItemDef"):get_method("Data(app.ItemDef.ID)") --[[@as REMethodDefinition]]
this.isValidItem = sdk.find_type_definition("app.ItemDef"):get_method("isValidItem(app.ItemDef.ID)") --[[@as REMethodDefinition]]
this.getEM_REWARD_RANKFromFixed = sdk.find_type_definition("app.QuestDef"):get_method(
    "getEM_REWARD_RANKFromFixed(app.QuestDef.EM_REWARD_RANK_Fixed, app.QuestDef.EM_REWARD_RANK)"
) --[[@as REMethodDefinition]]
this.getIncorrectStatusBit = sdk.find_type_definition("app.QuestCheckUtil")
    :get_method("getIncorrectStatusBit(app.QuestCheckUtil.INCORRECT_STATUS)") --[[@as REMethodDefinition]]

---@param int integer
---@return integer
function this.unsigned_to_signed(int)
    local num32 = int & 0xFFFFFFFF
    if num32 > 0x7FFFFFFF then
        return num32 - 0x100000000
    end
    return num32
end

---@param guid System.Guid
---@return string
function this.format_guid(guid)
    return string.format(
        "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        guid.mData1,
        guid.mData2,
        guid.mData3,
        guid.mData4_0,
        guid.mData4_1,
        guid.mData4_2,
        guid.mData4_3,
        guid.mData4_4,
        guid.mData4_5,
        guid.mData4_6,
        guid.mData4_7
    )
end

---@param guid System.Guid
---@return integer
function this.hash_guid(guid)
    return this.unsigned_to_signed(
        guid:read_dword(0x4) ~ guid:read_dword(0x0) ~ guid:read_dword(0x8) ~ guid:read_qword(0x8) >> 32
    )
end

---@generic T
---@param array System.Array<T>
---@return System.ArrayEnumerator<T>
function this.get_array_enum(array)
    ---@type System.ArrayEnumerator
    local enum
    local arr = array

    this.try(function()
        arr = array:ToArray()
    end)

    if not this.try(function()
        enum = arr:GetEnumerator()
    end) then
        enum = sdk.create_instance("System.ArrayEnumerator", true) --[[@as System.ArrayEnumerator]]
        enum:call(".ctor", arr)
    end
    return enum
end

---@param ptr integer
---@return integer
function this.deref_ptr(ptr)
    local fake_int64 = sdk.to_valuetype(ptr, "System.UInt64")
    ---@cast fake_int64 ValueType
    local deref = fake_int64:get_field("m_value")

    return deref
end

---@param rank_fixed app.QuestDef.EM_REWARD_RANK_Fixed
---@return app.QuestDef.EM_REWARD_RANK
function this.get_em_reward_rank(rank_fixed)
    local o = ValueType.new(sdk.find_type_definition("app.QuestDef.EM_REWARD_RANK") --[[@as RETypeDefinition]])
    this.getEM_REWARD_RANKFromFixed:call(nil, rank_fixed, o)
    return o:get_field("value__")
end

---@param stage app.FieldDef.STAGE
---@return app.FieldDef.STAGE_Fixed
function this.get_stage_id_fixed(stage)
    local o = ValueType.new(sdk.find_type_definition("app.FieldDef.STAGE_Fixed") --[[@as RETypeDefinition]])
    this.getFixedFromSTAGE:call(nil, stage, o)
    return o:get_field("value__")
end

---@param gimmick_event app.ExDef.GIMMICK_EVENT
---@return app.ExDef.GIMMICK_EVENT_Fixed
function this.get_gimmick_event_id_fixed(gimmick_event)
    local o = ValueType.new(sdk.find_type_definition("app.ExDef.GIMMICK_EVENT_Fixed") --[[@as RETypeDefinition]])
    this.getFixedFromGIMMICK_EVENT:call(nil, gimmick_event, o)
    return o:get_field("value__")
end

---@param animal_event app.ExDef.ANIMAL_EVENT
---@return app.ExDef.ANIMAL_EVENT_Fixed
function this.get_animal_event_id_fixed(animal_event)
    local o = ValueType.new(sdk.find_type_definition("app.ExDef.ANIMAL_EVENT_Fixed") --[[@as RETypeDefinition]])
    this.getFixedFromANIMAL_EVENT:call(nil, animal_event, o)
    return o:get_field("value__")
end

---@param gimmick_fixed app.ExDef.GIMMICK_EVENT_Fixed
---@return app.ExDef.GIMMICK_EVENT
function this.get_gimmick_event_id(gimmick_fixed)
    local o = ValueType.new(sdk.find_type_definition("app.ExDef.GIMMICK_EVENT") --[[@as RETypeDefinition]])
    this.getGIMMICK_EVENTFromFixed:call(nil, gimmick_fixed, o)
    return o:get_field("value__")
end

---@generic T
---@param system_array System.Array<T>
---@return T[]
function this.system_array_to_lua(system_array)
    local ret = {}
    local enum = this.get_array_enum(system_array)

    while enum:MoveNext() do
        local o = enum:get_Current()
        table.insert(ret, o)
    end
    return ret
end

---@param s string
---@param sep string?
---@return string[]
function this.split_string(s, sep)
    if not sep then
        sep = "%s"
    end

    local ret = {}
    for i in string.gmatch(s, "([^" .. sep .. "]+)") do
        table.insert(ret, i)
    end
    return ret
end

---@return via.Scene
function this.get_scene()
    return sdk.call_native_func(
        sdk.get_native_singleton("via.SceneManager"),
        sdk.find_type_definition("via.SceneManager") --[[@as RETypeDefinition]],
        "get_CurrentScene()"
    )
end

---@param type string?
---@return System.Array<REManagedObject>
function this.get_all_t(type)
    if not type then
        type = "via.Transform"
    end
    return this.get_scene():call("findComponents(System.Type)", sdk.typeof(type))
end

---@return via.Language
function this.get_language()
    return sdk.call_native_func(
        sdk.get_native_singleton("via.gui.GUISystem"),
        sdk.find_type_definition("via.gui.GUISystem") --[[@as RETypeDefinition]],
        "get_MessageLanguage()"
    )
end

---@param guid_name string
---@param lang via.Language
---@param fallback boolean?
---@return string
function this.get_message_local_from_name(guid_name, lang, fallback)
    local msg_guid = this.getGuidByName:call(nil, guid_name)
    return this.get_message_local(msg_guid, lang, fallback)
end

---@param guid System.Guid
---@param lang via.Language
---@param fallback boolean?
---@return string
function this.get_message_local(guid, lang, fallback)
    local parts = {}
    local msg = this.getMessageLocal:call(nil, guid, lang)
    ---@cast msg string
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

---@param obj REManagedObject
function this.print_fields(obj)
    ---@type RETypeDefinition[]
    local types = {}
    local def = obj:get_type_definition()

    while def do
        table.insert(types, def)
        def = def:get_parent_type()
    end

    ---@type {type: string, data: {name: string, data: any}[]}[]
    local res = {}
    for i = 1, #types do
        local type = types[i]
        local fields = type:get_fields()
        local data = { type = type:get_full_name(), data = {} }

        for j = 1, #fields do
            local field = fields[j]
            table.insert(data.data, { name = field:get_name(), data = field:get_data(obj) })
        end

        table.insert(res, data)
    end

    local max_len = 0
    for _, t in pairs(res) do
        for _, d in pairs(t.data) do
            max_len = math.max(max_len, #d.name)
        end
    end

    print(obj)
    for i = 1, #res do
        local type = res[i]
        print(type.type)
        print(string.rep("_", max_len))

        for j = 1, #type.data do
            local data = type.data[j]
            print(string.format("%s: %s", data.name .. string.rep(" ", max_len - #data.name), data.data))
        end
    end
    print("\n")
end

---@generic T
---@param system_array T[]
---@param something fun(system_array: System.Array<T>, index: integer, value: T): boolean?
---@param reverse boolean?
function this.do_something(system_array, something, reverse)
    ---@diagnostic disable-next-line: undefined-field, no-unknown
    local size = system_array:get_Count() - 1
    if reverse then
        for i = size, 0, -1 do
            ---@diagnostic disable-next-line: undefined-field
            if something(system_array, i, system_array:get_Item(i)) == false then
                break
            end
        end
    else
        for i = 0, size do
            ---@diagnostic disable-next-line: undefined-field
            if something(system_array, i, system_array:get_Item(i)) == false then
                break
            end
        end
    end
end

---@param try fun()
---@param catch fun(err: string)?
---@param finally fun(ok: boolean, err: string?)?
---@return boolean
function this.try(try, catch, finally)
    ---@diagnostic disable-next-line: no-unknown
    local ok, err = pcall(try)

    if not ok and catch then
        catch(err)
    end

    if finally then
        finally(ok, err)
    end

    return ok
end

return this
