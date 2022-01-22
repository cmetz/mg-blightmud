require("utils.string")
local prompt = require("protocol.prompt")
local mg_gmcp = require("protocol.gmcp")
local statusbar = require("ui.statusbar")

local function on_connect(host, port)
    if host == "localhost" or host == "mg.mud.de" then
        statusbar:init()
        prompt:init()
        mg_gmcp:init()
    end
end

local function on_disconnect()
    blight.status_height(1)
    blight.status_line(0, "")
    script.reset()
end

mud.on_connect(function(host, port)
    on_connect(host, port)
end)

mud.on_disconnect(function()
    on_disconnect()
end)
