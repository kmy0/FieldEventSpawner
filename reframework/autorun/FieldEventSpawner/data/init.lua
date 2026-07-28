local this = {
    gui = require("FieldEventSpawner.data.gui"),
    ace = require("FieldEventSpawner.data.ace.init"),
    mod = require("FieldEventSpawner.data.mod"),
}

---@return boolean
function this.init()
    return this.ace.init()
end

return this
