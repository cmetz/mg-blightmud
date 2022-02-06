local Statusbar = {}

-- Value
Statusbar.Value = {}
local Value = Statusbar.Value
Value.__index = Value

function Value.new(name, help_text, obj, key)
    local ret = setmetatable({}, Value)
    ret.name = name
    ret.help_text = help_text
    ret.obj = obj
    ret.key = key
    return ret
end

function Value.get_value(self)
    local ret
    if type(self.obj) == "function" then
        ret = self.obj()
    else
        ret = self.obj
    end
    if self.key then
        ret = ret[self.key]
    end
    return tostring(ret)
end

-- module statusbar

local DEFAULT_STATUS_LINES = {"{player.name}",
                              "<red>L<reset> {player.hp} <blue>K<reset> {player.sp}     <cyan>{room.domain}: <yellow>{room.short}<reset> N {room.notes}",
                              "{prompt}"}

local MAX_COLOR_RANGE = {C_RED, C_YELLOW, C_GREEN}

local status_lines = {}

local status_tokens = {}

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
    print(cformat([[
Konfiguriert die Ausgabe der Statuszeile.

Setzen mit:
  <blue>/config_statusbar <cyan>zeile inhalt<reset>

Zuruecksetzen mit:
  <blue>/config_statusbar <cyan>reset<reset>

Beispiel:
  <blue>/config_statusbar <cyan>2 Lebenspunkte:{hp}<reset>

Tab completion kann benutzt werden um aktuelle Einstellungen vorzublenden:
  <blue>/config_statusbar<red><space><tab><reset>

Verfuegbare Platzhalter:
]]))
    local keys = {}
    local max_name_len = 0
    for name in pairs(status_tokens) do
        max_name_len = math.max(max_name_len, #name)
        table.insert(keys, name)
    end
    max_name_len = max_name_len + 1
    table.sort(keys)
    for _, name in ipairs(keys) do
        local value = status_tokens[name]
        local line = C_YELLOW .. string.format("  %-" .. max_name_len .. "s", name) .. C_RESET
        if value.help_text then
            line = line .. value.help_text
        end
        print(line)
    end
    print(cformat([[

<green>Aktuelle Einstellung:<reset>
]]))

    for i, line in pairs(status_lines) do
        print("  Zeile " .. i .. ": " .. line)
    end
end

status_aliases:add("^/config_statusbar ?(\\d|reset)? ?(.*)?$", function(m)
    if m[2] == "" then
        statusbar_help()
        return
    end
    if m[2] == "reset" then
        status_lines = {table.unpack(DEFAULT_STATUS_LINES)}
        print("Statusbar auf die Defaulteinstellungen zurueckgesetzt!")
    else
        local i = tonumber(m[2])
        if i > 0 and i <= #status_lines then
            status_lines[i] = m[3]
            print("Zeile " .. i .. " gesetzt auf: " .. m[3])
        end
    end
    Statusbar:update()
    save_config()
end)

blight.on_complete(function(input)
    if input:starts_with("/config_statusbar") then
        local l = {}
        for i, line in pairs(status_lines) do
            l[i] = "/config_statusbar " .. i .. " " .. line
        end
        return l
    else
        return {}
    end
end)

function Statusbar.fun_max_colorized(obj, current_key, max_key)

    current = obj[current_key]
    max = obj[max_key]
    if max <= 0 then
        color_index = 1
    else
        color_index = math.max(math.ceil(current / max * #MAX_COLOR_RANGE), 1)
    end
    return MAX_COLOR_RANGE[color_index] .. current .. C_RESET
end

function Statusbar.init(self)
    load_config()
    blight.status_height(#status_lines)
    self:update()
end

function Statusbar.update(self)
    for i, line in pairs(status_lines) do
        for name, value in pairs(status_tokens) do
            line = line:replace("{" .. name .. "}", value:get_value())
        end
        blight.status_line(i - 1, line:cformat())
    end
end

function Statusbar.add_value(self, name, help_text, obj, key)
    local ret = Value.new(name, help_text, obj, key)
    status_tokens[name] = ret
    return ret
end

return Statusbar
