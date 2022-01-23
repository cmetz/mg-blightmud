require("utils.string")
local prompt = require("protocol.prompt")
local mg_gmcp = require("protocol.gmcp")
local statusbar = require("ui.statusbar")

local self = {
    host = store.session_read("cur_host"),
    port = tonumber(store.session_read("cur_port") or "0")
}

local function on_connect(host, port)
    store.session_write("cur_host", host)
    store.session_write("cur_port", tostring(port))
    if host == "localhost" or host == "mg.mud.de" then
        statusbar:init()
        prompt:init()
        mg_gmcp:init()
    end
end

local function on_disconnect()
    self.host = nil
    self.port = nil
    store.session_write("cur_host", tostring(nil))
    store.session_write("cur_port", tostring(nil))
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

if self.host and self.port then
    on_connect(self.host, self.port)
end
