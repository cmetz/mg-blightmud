local Player = {
    hp = 0,
    hp_max = 0,
    sp = 0,
    sp_max = 0,
    name = "",
    title = "",
    presay = "",
    guild = "",
    race = "",
    wizlevel = 0,
    last_input_line = ""
}

local statusbar = require("ui.statusbar")

local player_aliases = alias.add_group()

function Player.update()
    statusbar:update()
end

-- input listener for fetchting the last input

mud.add_input_listener(function(line)
    Player.last_input_line = line:line()
    return line
end)

-- statusbar

statusbar:add_value("player.name", "Spieler - Name", Player, "name")
statusbar:add_value("player.title", "Spieler - Titel", Player, "title")
statusbar:add_value("player.presay", "Spieler - Presay", Player, "presay")
statusbar:add_value("player.race", "Spieler - Rasse", Player, "race")
statusbar:add_value("player.guild", "Spieler - Gilde", Player, "guild")

statusbar:add_value("player.hp", "Spieler - Aktuelle Lebenspunkte", function()
    return statusbar.fun_max_colorized(Player, "hp", "hp_max")
end)
statusbar:add_value("player.sp", "Spieler - Aktuelle Konzentrationspunkte", function()
    return statusbar.fun_max_colorized(Player, "sp", "sp_max")
end)
statusbar:add_value("player.hp_max", "Spieler - Maximale Lebenspunkte", Player, "hp_max")
statusbar:add_value("player.sp_max", "Spieler - Maxiamle Konzentrationspunkte", Player, "sp_max")

return Player
