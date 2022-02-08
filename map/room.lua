local class = require("utils.class")
local Exit = require("map.exit")

-- Room class
local Room = class()

function Room:initialize(id, domain, short, long)
    self.id = id
    self.short = tostring(short)
    self.domain = tostring(domain)
    self.long = long
    self.notes = {}
    self.exits = {}
    self.scanned = false
end

function Room:add_note(note)
    table.insert(self.notes, note)
    print(cformat("<green>Notiz \"%s\" am Raum \"%s\" hinzugefuegt.<reset>", note, self.short))
end

function Room:clear_notes()
    self.notes = {}
    print(cformat("<red>Notizen im Raum wurden geloescht!<reset>", note, self.short))
end

function Room:add_exit(direction, alias, to_room)
    local exit = Exit(self.id, direction, alias, to_room)
    table.insert(self.exits, exit)
    return exit
end

function Room:get_exit_to(to_id)
    local last_prio = math.huge
    local found_exit = nil
    for _, exit in ipairs(self.exits) do
        if exit.to_room and exit.to_room == to_id then
            local current_prio = exit:get_prio()
            if current_prio < last_prio then
                found_exit = exit
                last_prio = current_prio
            end
        end
    end
    return found_exit
end

function Room:get_direction_to(to_id)
    local exit = self:get_exit_to(to_id)
    if exit then
        return exit.direction
    end
end

function Room:clear_exits()
    self.exits = {}
end

-- commands

function Room:cmd_exit_list(args)
    print("Ausgaenge:")
    local max = 0
    for _, exit in ipairs(self.exits) do
        max = math.max(max, #exit:get_name())
    end
    for _, exit in ipairs(self.exits) do
        print(cformat("  %-" .. max .. "s: %s", exit:get_name(), exit:get_direction()))
    end
end

function Room:cmd_exit_add(args)
    local exit_alias = args.arguments.alias
    local exit_command = ""
    if #args.input > 0 then
        exit_command = table.concat(args.input, " ")
    end
    if exit_command == "" then
        print(cformat("<red>Syntax:<reset> /room exit add [--alias=exit_alias] <exit_command>"))
        return
    end
    self:add_exit(exit_command, exit_alias)
end

function Room:cmd_exit_delete(args)
    local exit_name = table.concat(args.input, " ")
    if exit_name ~= "" then
        for i, exit in ipairs(self.exits) do
            if exit:get_name() == exit_name then
                table.remove(self.exits, i)
                print(cformat("<yellow>Ausgang \"%s\" entfernt!<reset>", exit_name))
                return
            end
        end
    end
    print(cformat("<red>Syntax:<reset> /room exit del alias"))
    print(cformat("<red>Syntax:<reset> Benutze \"/room exit list\" um den alias zu bestimmen!"))
end

-- data dump

function Room:dump()
    ret = {}
    ret.id = self.id
    ret.domain = self.domain
    ret.short = self.short
    ret.long = self.long
    -- ret.alias = self.alias
    ret.notes = self.notes
    ret.scanned = self.scanned
    local dumped_exits = {}
    for _, exit in ipairs(self.exits) do
        table.insert(dumped_exits, exit:dump())
    end
    ret.exits = dumped_exits
    return ret
end

function Room._from_dump(data)
    local ret = Room(data.id, data.domain, data.short, data.long)
    -- ret:set_alias(data.alias)
    ret.notes = data.notes
    ret.scanned = data.scanned
    local exits = {}
    for _, exit in ipairs(data.exits) do
        table.insert(exits, Exit._from_dump(exit))
    end
    ret.exits = exits
    return ret
end

return Room
