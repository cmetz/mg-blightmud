local MG_Gmcp = {}

local player = require("player")
local room = require("room")
local comm = require("comm")

function MG_Gmcp.init()

    gmcp.on_ready(function()
        gmcp.register("MG.char")
        gmcp.register("MG.room")
        gmcp.register("comm.channel")

        gmcp.receive("MG.char.vitals", function(data)
            obj = json.decode(data)
            player.hp = obj["hp"]
            player.sp = obj["sp"]
            player:update()
        end)

        gmcp.receive("MG.room.info", function(data)
            obj = json.decode(data)
            room.id = obj["id"]
            room.short = obj["short"]
            room.domain = obj["domain"]
            room:update()
        end)

        gmcp.receive("MG.char.base", function(data)
            obj = json.decode(data)
            player.name = obj["name"]
            player.title = obj["title"]
            player.presay = obj["presay"]
            player.guild = obj["guild"]
            player.race = obj["race"]
            player.wizlevel = obj["wizlevel"]
            player:update()
        end)

        gmcp.receive("MG.char.maxvitals", function(data)
            obj = json.decode(data)
            player.hp_max = obj["max_hp"]
            player.sp_max = obj["max_sp"]
            player:update()
        end)

        gmcp.receive("comm.channel", function(data)
            obj = json.decode(data)
            comm.print_channel_message(obj.msg, obj.player, obj.chan)
        end)
    end)
end

return MG_Gmcp
