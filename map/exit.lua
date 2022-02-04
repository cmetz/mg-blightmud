local class = require("utils.class")

-- short to lang directions
local SHORT_TO_LONG = {
    n = "norden",
    o = "osten",
    s = "sueden",
    w = "westen",
    u = "unten",
    ob = "oben",
    no = "nordosten",
    so = "suedosten",
    sw = "suedwesten",
    nw = "nordwesten",
    nob = "nordoben",
    noob = "nordostoben",
    soob = "suedostoben",
    sob = "suedoben",
    swob = "suedwestoben",
    wob = "westoben",
    nwob = "nordwestoben",
    nu = "nordunten",
    nou = "nordostunten",
    sou = "suedostunten",
    su = "suedunten",
    swu = "suedwestunten",
    wu = "westunten",
    nwu = "nordwestunten"
}

local LONG_TO_SHORT = table.swap(SHORT_TO_LONG)

local DIRECTIONS = {"raus"}
table.extend(DIRECTIONS, table.values(SHORT_TO_LONG))

local REVERSE_DIRECTIONS = {
    sueden = "norden",
    westen = "osten",
    norden = "sueden",
    osten = "westen",
    oben = "unten",
    unten = "oben",
    suedwesten = "nordosten",
    nordwesten = "suedosten",
    nordosten = "suedwesten",
    suedosten = "nordwesten",
    suedunten = "nordoben",
    suedwestunten = "nordostoben",
    nordwestunten = "suedostoben",
    nordunten = "suedoben",
    nordostunten = "suedwestoben",
    ostunten = "westoben",
    suedostunten = "nordwestoben",
    suedoben = "nordunten",
    suedwestoben = "nordostunten",
    nordwestoben = "suedostunten",
    nordoben = "suedunten",
    nordostoben = "suedwestunten",
    ostoben = "westunten",
    suedostoben = "nordwestunten"
}

local USER_DIRECTION_INPUT = DIRECTIONS
for short, long in pairs(SHORT_TO_LONG) do
    table.insert(DIRECTIONS, long)
    table.insert(USER_DIRECTION_INPUT, short)
    table.insert(USER_DIRECTION_INPUT, long)
end
local RE_USER_DIRECTION_INPUT = regex.new("^(" .. table.concat(USER_DIRECTION_INPUT, "|") .. ")$")

local function short_direction(direction)
    return LONG_TO_SHORT[direction] or direction
end

local function long_direction(direction)
    return SHORT_TO_LONG[direction] or direction
end

local function user_input_to_direction(input)
    local exit_input = RE_USER_DIRECTION_INPUT:match(input)
    if exit_input then
        exit_input = exit_input[1]
        exit_input = long_direction(exit_input)
        return exit_input
    end
end

local function reverse_direction(direction)
    return REVERSE_DIRECTIONS[direction]
end

-- Exit class

local Exit = class {
    user_input_to_direction = user_input_to_direction,
    short_direction = short_direction,
    long_direction = long_direction,
    reverse_direction = reverse_direction
}

function Exit:initialize(from_room, direction, alias, to_room)
    self.from_room = from_room
    self.direction = direction
    self.alias = alias
    self.to_room = to_room
end

function Exit:get_direction()
    return self.direction
end

function Exit:get_name(long)
    if self.alias then
        return self.alias
    else
        return not long and short_direction(self.direction) or self.direction
    end
end

function Exit:dump()
    local ret = {}
    ret.from_room = self.from_room
    ret.to_room = self.to_room
    ret.direction = self.direction
    ret.alias = self.alias
    return ret
end

function Exit._from_dump(data)
    local ret = Exit(data.from_room, data.direction, data.alias, data.to_room)
    return ret
end

return Exit
