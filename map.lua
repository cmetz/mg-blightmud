local Map = {}

local argparser = require("utils.argparser")
local player = require("player")
local statusbar = require("ui.statusbar")
local macros = require("macros")

local Exit = require("map.exit")
local Room = require("map.room")
local PathFinder = require("map.pathfinder")

-- map

local rooms = {}
local rooms_alias_to_id = {}
local rooms_id_to_alias = {}

local path_finder = PathFinder(function()
    return rooms
end)

local current_room_id = ""
local last_room_id = ""
local mapping_mode = 0 -- 0 off, 1 on, 2 on (lazy)
local auto_walk = false
local auto_walk_end_room
local auto_walk_last_search = {}
local scan_room_after_next_prompt = false

local map_aliases = alias.add_group()
local map_triggers = trigger.add_group()
local map_line_trigger
local map_prompt_trigger

function Map.add_room(id, domain, short, exits)
    if not id or id == "" then
        return
    end
    if rooms[id] then
        return rooms[id]
    end
    local room = Room(id, domain, short)
    if exits then
        for _, exit in ipairs(exits) do
            room:add_exit(exit)
        end
    end
    rooms[id] = room
end

function Map.set_current_room(id)
    last_room_id = current_room_id
    current_room_id = id

    if not auto_walk and mapping_mode > 0 and last_room_id ~= "" and current_room_id ~= "" and last_room_id ~=
        current_room_id then
        local direction = Exit.user_input_to_direction(player.last_input_line) or player.last_input_line
        if direction then
            local exit_found = false
            for _, exit in ipairs(rooms[last_room_id].exits) do
                if exit.direction == direction and not exit.to_room then
                    exit.to_room = current_room_id
                    exit_found = true
                    break
                elseif exit.to_room == current_room_id then
                    exit_found = true
                end
            end
            if not exit_found and mapping_mode > 1 then -- lazy mode we add exists to the previos room
                local last_room = rooms[last_room_id]
                last_room:add_exit(direction, nil, current_room_id)
            end
            local reverse_direction = Exit.reverse_direction(direction)
            if reverse_direction then
                for _, exit in ipairs(rooms[current_room_id].exits) do
                    if exit.direction == reverse_direction and not exit.to_room then
                        exit.to_room = last_room_id
                        break
                    end
                end
            end
        end
        scan_room_after_next_prompt = true
        map_prompt_trigger:enable()
    end

    if auto_walk and current_room_id == auto_walk_end_room then
        print(cformat("<green>Du bist da!<reset>"))
        auto_walk = false
        auto_walk_end_room = nil
    end

    if not auto_walk then
        statusbar:update()
    end
end

function Map.get_current_room(quiet)
    local room = rooms[current_room_id]
    if not room and not quiet then
        print(cformat("<red>Konnte keinen aktuellen Raum bestimmen!<reset>"))
    end
    return room
end

function Map.get_room_id_by_alias(alias)
    return rooms_alias_to_id[alias]
end

function Map.get_alias_by_room_id(room_id)
    return rooms_id_to_alias[room_id] or ""
end

function Map.list_rooms(args)
    if #args.input == 0 then
        return
    end
    local count_only = args.flags.c
    local count = 0

    local re_input = {}
    local all = false
    for _, input in ipairs(args.input) do
        if input == "." or input == ".*" then
            all = true
            break
        end
        local re = regex.new(input, {
            case_insensitive = true
        })
        table.insert(re_input, re)
    end

    -- regex for highlite
    local re_highlite = regex.new("(" .. table.concat(args.input, "|") .. ")", {
        case_insensitive = true
    })

    auto_walk_last_search = {}
    for k, room in pairs(rooms) do
        -- print("here")
        if not args.flags.a or Map.get_alias_by_room_id(room.id) ~= "" then
            local entry = Map.get_room_info(room, args.flags.l and true)
            local found_all = true
            if not all then
                for _, re in ipairs(re_input) do
                    if not re:test(entry) then
                        found_all = false
                        break
                    end
                end
            end
            if found_all then
                count = count + 1
                if not count_only then
                    if not all then
                        entry = re_highlite:replace(entry, "<green>$1<reset>")
                    end
                    print(count .. ": " .. entry:cformat())
                    if args.flags.l then
                        print("")
                    end
                    table.insert(auto_walk_last_search, room.id)
                end
            end
        end
    end
    print(cformat("<yellow>Anzahl Treffer: %d<reset>", count))
end

local scanned_data = {}

local RE_SCAN_EXIT_LINE = regex.new("^Es gibt (?:\\w+) sichtbaren? Ausgae?nge?[:.]")

function Map.scan_current_room(args)
    local room = Map.get_current_room()
    if not room then
        return
    end
    if room.scanned and not args.flags["f"] then
        if args.flags["a"] then
            print(cformat("<yellow>Raum bereits gescanned!<reset>"))
        else
            print(cformat("<yellow>Raum bereits gescanned! Zum erneuten scannen bitte -f verwenden.<reset>"))
        end
        return
    end
    scanned_data = {}
    map_line_trigger:enable()
    map_prompt_trigger:enable()
    mud.send("schau", {
        gag = true,
        skip_log = true
    })
end

function Map.scan_current_room_done()
    print(cformat("<green>Fertig mit Scannen des Raumes.<reset>"))
    local long_desc = {}
    for _, line in ipairs(scanned_data) do
        if RE_SCAN_EXIT_LINE:test(line) then
            if #long_desc > 0 then
                local room = Map.get_current_room()
                room.long = table.concat(long_desc, "\n")
                room.scanned = true
            end
            break
        end
        table.insert(long_desc, line)
    end
end

function Map.receive_scan_data(line)
    if line:prompt() then
        map_line_trigger:disable()
        map_prompt_trigger:disable()
        Map.scan_current_room_done()
    end
    table.insert(scanned_data, line:line())
end

function Map.cmd_add_room_note(args)
    local room = Map.get_current_room()
    if not room then
        return
    end
    if args.arguments.clear == "yes" then
        room:clear_notes()
    end
    if #args.input > 0 then
        local note = table.concat(args.input, " ")
        room:add_note(note)
    end
end

function Map.get_room_info(room, long)
    local template = ""
    if long then
        template = "<cyan>{domain}: <yellow>{short}<reset> <red>{alias}<reset> ({id}){long}{exits}{notes}"
    else
        template = "<cyan>{domain}: <yellow>{short}<reset> <red>({alias})<reset>"
    end

    template = template:replace("{domain}", room.domain)
    template = template:replace("{short}", room.short)
    template = template:replace("{alias}", Map.get_alias_by_room_id(room.id))

    if long then
        template = template:replace("{id}", room.id)
        template = template:replace("{long}", room.long and "\n" .. room.long or "")

        local exits = {}
        if #room.exits > 0 then
            for _, exit in ipairs(room.exits) do
                local exit_name = exit:get_name(true)
                if exit.to_room then
                    table.insert(exits, C_GREEN .. exit_name .. C_RESET)
                else
                    table.insert(exits, C_RED .. exit_name .. C_RESET)
                end
            end
        end
        template = template:replace("{exits}", "\n<green>Ausgaenge:<reset> " .. table.concat(exits, ", "))

        local notes = ""
        if #room.notes > 0 then
            notes = "\n<yellow>Notizen:"
            for _, note in ipairs(room.notes) do
                notes = notes .. cformat("\n - %s", note)
            end
            notes = notes .. "<reset>"
        end
        template = template:replace("{notes}", notes)
    end
    return template
end

function Map.print_room_info(long)
    local room = Map.get_current_room()
    if not room then
        return
    end
    print(Map.get_room_info(room, long):cformat())
end

function Map.save()
    local data = {
        rooms = {}
    }
    local c = 0
    for id, room in pairs(rooms) do
        data.rooms[id] = room:dump()
        c = c + 1
    end
    data.rooms_alias_to_id = rooms_alias_to_id
    data.rooms_id_to_alias = rooms_id_to_alias
    local save_file = io.open(MG_DATA_PATH .. "rooms.json", "w")
    save_file:write(json.encode(data))
    save_file:close()
    print(cformat("%d Raeume gespeichert!", c))
end

function Map.toggle_mapping()
    mapping_mode = mapping_mode + 1
    mapping_mode = mapping_mode % 3
    local state = mapping_mode == 0 and "<red>dekativiert<reset>" or
                      (mapping_mode == 1 and "<green>aktiviert<reset>" or "<yellow>aktiviert (bequem)<reset>")
    print(cformat("Autoamtisches scannen von Raeumen: " .. state))
end

function Map.load()
    local save_file = io.open(MG_DATA_PATH .. "rooms.json", "r")
    if save_file then
        local data = json.decode(save_file:read("*all"))
        save_file:close()
        if data then
            local new_rooms = {}
            local c = 0
            for id, room_data in pairs(data.rooms) do
                local room = Room._from_dump(room_data)
                new_rooms[id] = room
                c = c + 1
            end
            rooms = new_rooms
            if data.rooms_alias_to_id then
                for alias, room_id in pairs(data.rooms_alias_to_id) do
                    if rooms[room_id] then
                        rooms_alias_to_id[alias] = room_id
                        rooms_id_to_alias[room_id] = alias
                    end
                end
            end

            print(cformat("%d Raeume geladen!", c))
        end
    end
end

function Map.walk_path(path)
end

-- triggers, only needed for scanning currently so deisabled by default
-- gets enabled when a scanning is requestet

-- if we received a "Finsternis." we set the current room to blank
map_triggers:add("^Finsternis.$", {}, function()
    Map.set_current_room("")
end)

map_line_trigger = map_triggers:add("^.*$", {
    enabled = false,
    gag = true
}, function(_, line)
    Map.receive_scan_data(line)
end)

map_prompt_trigger = map_triggers:add("^.*$", {
    enabled = false,
    prompt = true
}, function(_, line)
    if scan_room_after_next_prompt then
        map_prompt_trigger:disable()
        scan_room_after_next_prompt = false
        local args = argparser.Arguments()
        args:add_flag("a")
        Map.scan_current_room(args)
    else
        Map.receive_scan_data(line, line:prompt())
    end
end)

-- aliases

map_aliases:add("^/(?:wo|room info)$", function(m)
    Map.print_room_info(true)
end)

map_aliases:add("^/room (?:list|search) ?(.*)?$", function(m)
    local args = argparser.parse(m[2])
    Map.list_rooms(args)
end)

map_aliases:add("^/room scan ?(.*)?$", function(m)
    local args = argparser.parse(m[2])
    Map.scan_current_room(args)
end)

map_aliases:add("^/room mapping$", function()
    Map.toggle_mapping()
end)

map_aliases:add("^/room exit (\\w+)\\s?(.*)?", function(m)
    local sub_cmd = m[2]
    local args = argparser.parse(m[3])
    local room = Map.get_current_room()
    if not room then
        return
    end
    if sub_cmd == "list" then
        room:cmd_exit_list(args)
    elseif sub_cmd == "add" then
        room:cmd_exit_add(args)
    elseif sub_cmd == "del" then
        room:cmd_exit_delete(args)
    end
end)

map_aliases:add("^/room note (.*)", function(m)
    local args = argparser.parse(m[2])
    Map.cmd_add_room_note(args)
end)

map_aliases:add("^/room alias ?(.*)?", function(m)
    if m[2] ~= "" then
        local room = Map.get_current_room()
        if not room then
            return
        end
        local args = argparser.parse(m[2])
        if args.flags.d then
            local alias = rooms_id_to_alias[room.id]
            if alias then
                rooms_id_to_alias[room.id] = nil
                rooms_alias_to_id[alias] = nil
                print(cformat("<yellow>Alias \"%s\" entfernt!<reset>", alias))
                return
            end
            return
        end
        local alias = args.input[1]
        if not alias then
            print(cformat("<red>Kein Alias angeben!<reset>"))
            return
        end
        if rooms_alias_to_id[alias] then
            if args.arguments.force == "yes" then
                rooms_id_to_alias[rooms_alias_to_id[alias]] = nil
            else
                print(cformat("<red>Alias \"%s\" existiert schon! --force=yes zum ueberschreiben.<reset>", alias))
            end
        end
        rooms_alias_to_id[alias] = room.id
        rooms_id_to_alias[room.id] = alias
        print(cformat("<green>Alias \"%s\" gesetzt!<reset>", alias))
    else
        for alias, room in pairs(rooms_alias_to_id) do
            print(cformat("%s (%s)", rooms[room].short, alias))
        end
    end
end)

map_aliases:add("^/room path (.*)", function(m)
    local args = argparser.parse(m[2])
    if args.arguments.clear then
        path_finder:clear_cache()
        print(cformat("<yellow>Wege Cache geleert!<reset>"))
    end
    if #args.input > 1 then
        from_id = Map.get_room_id_by_alias(args.input[1])
        to_id = Map.get_room_id_by_alias(args.input[2])
    elseif #args.input > 0 then
        from_id = current_room_id
        to_id = Map.get_room_id_by_alias(args.input[1])
    end
    if from_id and to_id then
        local path = path_finder:find_path(from_id, to_id)
        local path_as_short = {}
        for _, step in ipairs(path) do
            local d = rooms[step.from]:get_exit_to(step.to):get_name()
            table.insert(path_as_short, d)
        end
        print(cformat("Von %s nach %s:\n%s", Map.get_alias_by_room_id(from_id), Map.get_alias_by_room_id(to_id),
            table.concat(path_as_short, ", ")))
    end
end)

map_aliases:add("^/room save$", function()
    Map.save()
end)

map_aliases:add("^/room load$", function()
    Map.load()
end)

map_aliases:add("^/w?go (s=)?(\\w+)", function(m)
    local to_id
    if m[2] == "s=" then
        local search_id = tonumber(m[3])
        if search_id and search_id > 0 and search_id <= #auto_walk_last_search then
            to_id = auto_walk_last_search[search_id]
        else
            return
        end
    else
        to_id = Map.get_room_id_by_alias(m[3])
    end

    if to_id then
        local room = Map.get_current_room()
        if not room then
            return
        end
        local path = path_finder:find_path(room.id, to_id)
        if #path > 0 then
            auto_walk = true
            auto_walk_end_room = to_id
            local path_as_short = {}
            for _, step in ipairs(path) do
                table.insert(path_as_short, rooms[step.from]:get_exit_to(step.to):get_name())
            end
            print(cformat("<cyan>%s<reset>", table.concat(path_as_short, ", ")))
            if #path > 2 then
                mud.send("ultrakurz", {
                    gag = true
                })
            end
            for i, step in ipairs(path) do
                if #path > 2 and i == #path then
                    mud.send("kurz", {
                        gag = true
                    })
                end
                local direction = rooms[step.from]:get_direction_to(step.to)
                if direction:sub(1, 1) == "/" then
                    macros.run(direction)
                else
                    mud.send(direction, {
                        gag = true
                    })
                end
            end
        end
    end
end)

-- statusbar

statusbar:add_value("room.id", "Raum - Id", function()
    if not rooms[current_room_id] then
        return ""
    end
    return rooms[current_room_id].id
end)

statusbar:add_value("room.short", "Raum - Kurzbeschreibung", function()
    if not rooms[current_room_id] then
        return ""
    end
    return rooms[current_room_id].short
end)

statusbar:add_value("room.domain", "Raum - Ebene", function()
    if not rooms[current_room_id] then
        return ""
    end
    return rooms[current_room_id].domain
end)

statusbar:add_value("room.notes", "Raum - Anzahl der Notizen im Raum", function()
    if not rooms[current_room_id] then
        return ""
    end
    return #rooms[current_room_id].notes
end)

return Map