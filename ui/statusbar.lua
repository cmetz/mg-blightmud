local Statusbar = {
    prompt = "",
    hp = 0,
    max_hp = 0,
    sp = 0,
    max_sp = 0,
    room_short = "",
    room_domain = ""
}

local DEFAULT_STATUS_LINES = {"",
                              "<red>L<reset>:{hp} <blue>K<reset>:{sp}     <cyan>{room_domain}: <yellow>{room_short}<reset>",
                              "{prompt}"}

local HP_MP_COLOR_RANGE = {C_RED, C_YELLOW, C_GREEN}

local status_lines = {}

local status_aliases = alias.add_group()

local function load_config()
    local config = store.disk_read("mg_statusbar")
    if not config then
        status_lines = DEFAULT_STATUS_LINES
        return
    end

    config = json.decode(config)
    status_lines = config.status_lines
end

local function save_config()
    config = {
        status_lines = status_lines
    }
    store.disk_write("mg_statusbar", json.encode(config))
end

local function statusbar_help()
    blight.output(cformat([[
Konfiguriert die Ausgabe der Statuszeile.

Setzen mit:
  <blue>/config_statusbar <cyan>zeile inhalt<reset>

Zuruecksetzen mit:
  <blue>/config_statusbar <cyan>reset<reset>

Beispiel:
  <blue>/config_statusbar <cyan>2 Lenebspunkte:{hp}<reset>

Tab completion kann benutzt werden um aktuelle Einstellungen vorzublenden:
  <blue>/config_statusbar<red><space><tab><reset>

<green>Aktuelle Einstellung:<reset>
]]))

    for i, line in pairs(status_lines) do
        blight.output("Zeile " .. i .. ": " .. line)
    end
end

status_aliases:add("^/config_statusbar ?(\\d|reset)? ?(.*)?$", function(m)
    if m[2] == "" then
        statusbar_help()
        return
    end
    if m[2] == "reset" then
        status_lines = DEFAULT_STATUS_LINES
        blight.output("Statusbar auf die Defaulteinstellungen zurueckgesetzt!")
    else
        local i = tonumber(m[2])
        if i > 0 and i <= #status_lines then
            status_lines[i] = m[3]
            blight.output("Zeile " .. i .. " gesetzt auf: " .. m[3])
        end
    end
    Statusbar:refresh()
    save_config()
end)

blight.on_complete(function(input)
    if string.sub(input, 1, 17) == "/config_statusbar" then
        local l = {}
        for i, line in pairs(status_lines) do
            l[i] = "/config_statusbar " .. i .. " " .. line
        end
        return l
    else
        return {}
    end
end)

local function get_hp_mp_colorized(current, max)
    if max <= 0 then
        color_index = 1
    else
        color_index = math.max(math.ceil(current / max * #HP_MP_COLOR_RANGE), 1)
    end
    return HP_MP_COLOR_RANGE[color_index] .. current .. C_RESET
end

function Statusbar.init(self)
    load_config()
    blight.status_height(#status_lines)
    self:refresh()
end

function Statusbar.refresh(self)
    for i, line in pairs(status_lines) do
        line = line:replace("{prompt}", C_RESET .. self.prompt)
        line = line:replace("{hp}", get_hp_mp_colorized(self.hp, self.max_hp))
        line = line:replace("{sp}", get_hp_mp_colorized(self.sp, self.max_sp))
        line = line:replace("{max_hp}", self.max_hp)
        line = line:replace("{max_sp}", self.max_sp)
        line = line:replace("{room_short}", self.room_short)
        line = line:replace("{room_domain}", self.room_domain)
        blight.status_line(i - 1, cformat(line))
    end
end

return Statusbar
