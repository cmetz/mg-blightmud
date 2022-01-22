local MG_Gmcp = {}
local statusbar = require("ui.statusbar")

function MG_Gmcp.init()
    gmcp.on_ready(function()
        -- blight.output("Registering GMCP")
        -- blight.output("Register MG.char")
        gmcp.register("MG.char")
        gmcp.register("MG.room")
        gmcp.receive("MG.char.vitals", function(data)
            obj = json.decode(data)
            statusbar.hp = obj["hp"]
            statusbar.sp = obj["sp"]
            statusbar:refresh()
        end)
        gmcp.receive("MG.room.info", function(data)
            obj = json.decode(data)
            statusbar.room_short = obj["short"]
            statusbar.room_domain = obj["domain"]
            statusbar:refresh()
        end)
        gmcp.receive("MG.char.maxvitals", function(data)
            obj = json.decode(data)
            statusbar.max_hp = obj["max_hp"]
            statusbar.max_sp = obj["max_sp"]
            statusbar:refresh()
        end)
        gmcp.echo(false)
    end)
end

return MG_Gmcp
