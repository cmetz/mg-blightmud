local Mod = {}

local Window = {port}
Window.__index = Window

function Window.send(self, text)
    conn = socket.connect("localhost", self.port)
    if conn then
        conn:send(text)
        conn:close()
    end
end

function Window.print(self, text)
    self.send(text .. "\n")
end

function Window.clear(self)
    self:send("\x1b[2J\x1b[1;1H")
end

function Window.hide_cursor(self, hide)
    self:send("\x1b[?25" .. (hide and "l" or "h"))
end

local windows = {}

function Mod.get(port)

    -- return existing window connection
    if windows[port] then
        return window[port]
    end

    -- connect to window port
    ret = setmetatable({}, Window)
    ret.port = port
    windows[port] = ret
    return ret
end

return Mod
