local this = {
    gui = require("FieldEventSpawner.data.gui"),
    ace = require("FieldEventSpawner.data.ace"),
    runtime = require("FieldEventSpawner.data.runtime"),
    util = require("FieldEventSpawner.data.util"),
    initialized = false,
}

---@return boolean
function this.init()
    if this.initialized then
        return true
    end

    this.ace.init()

    this.initialized = true
    return true
end

return this
