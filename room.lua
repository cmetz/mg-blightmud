local Room = {
    id = "",
    short = "",
    domain = ""
}

local statusbar = require("ui.statusbar")

function Room.update()
    statusbar:update()
end

statusbar:add_value("room.id", "Raum - Id", Room, "id")
statusbar:add_value("room.short", "Raum - Kurzbeschreibung", Room, "short")
statusbar:add_value("room.domain", "Raum - Ebene", Room, "domain")

return Room
