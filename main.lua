require("utils.string")
require("utils.table")
require("macros")
local prompt = require("protocol.prompt")
local gmcp = require("protocol.gmcp")
local statusbar = require("ui.statusbar")

local PATH_SEP = package.config:sub(1, 1)

MG_DATA_PATH = blight.data_dir() .. PATH_SEP .. "mg"
os.execute("mkdir " .. MG_DATA_PATH)
MG_DATA_PATH = MG_DATA_PATH .. PATH_SEP
-- local file = io.open(MG_DATA_PATH .. "test.txt", "a")
-- file:write("loaded\n")
-- file:close()

local self = {
    host = store.session_read("current_host"),
    port = tonumber(store.session_read("current_port") or "0")
}

local function on_connect(host, port)
    store.session_write("current_host", host)
    store.session_write("current_port", tostring(port))
    if host == "localhost" or host == "mg.mud.de" then
        statusbar:init()
        prompt:init()
        gmcp:init()
    end
end

local function on_disconnect()
    self.host = nil
    self.port = nil
    store.session_write("current_host", tostring(nil))
    store.session_write("current_port", tostring(nil))
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
