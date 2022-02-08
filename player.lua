local Player = {

    name = "",
    title = "",
    presay = "",
    level = 0,
    guild = "",
    guild_title = "",
    guild_level = 0,
    race = "",
    wizlevel = 0,
    wimpy = 0,
    wimpy_direction = "",
    hp = 0,
    hp_max = 0,
    sp = 0,
    sp_max = 0,
    poison = 0,
    poison_max = 0,
    attributes = {
        con = 0,
        int = 0,
        dex = 0,
        str = 0
    },
    last_input_line = "",
    walk_mode = ""
}

local statusbar = require("ui.statusbar")

local player_aliases = alias.add_group()
local player_triggers = trigger.add_group()

function Player.update()
    statusbar:update()
end

-- walk mode in mg

Player.WALK_MODE_SILENT = "ultrakurz"
Player.WALK_MODE_SHORT = "kurz"
Player.WALK_MODE_LONG = "lang"

local walk_mode_quiet_count = 0

function Player.set_walk_mode(mode, quiet)
    if quiet then
        walk_mode_quiet_count = walk_mode_quiet_count + 1
    end
    mud.send(mode, {
        gag = true
    })
end

player_triggers:add("^Du bist nun im \"(Ultrakurz|Kurz|Lang)\"modus.$", {}, function(m, line)
    Player.walk_mode = string.lower(m[2])
    if walk_mode_quiet_count > 0 then
        line:gag(true)
        walk_mode_quiet_count = walk_mode_quiet_count - 1
    end
    Player.update()
end)

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
statusbar:add_value("player.poison", "Spieler - Aktueller Vergiftungslevel", function()
    return statusbar.fun_max_colorized(Player, "poison", "poison_max")
end)

statusbar:add_value("player.hp_max", "Spieler - Maximale Lebenspunkte", Player, "hp_max")
statusbar:add_value("player.sp_max", "Spieler - Maxiamle Konzentrationspunkte", Player, "sp_max")
statusbar:add_value("player.poison_max", "Spieler - Maxiamler Vergiftungslevel", Player, "poison_max")

statusbar:add_value("player.wimpy", "Spieler - Vorsicht", function()
    return statusbar.fun_max_colorized(Player, "wimpy", "hp_max")
end)
statusbar:add_value("player.wimpy_direction", "Spieler - Vorsicht Fluchtrichtung", Player, "wimpy_direction")

return Player
