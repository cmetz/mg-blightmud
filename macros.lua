Macros = {}

-- unsorted list of macors
local argparser = require("utils.argparser")

local aliases = alias.add_group()

local alias_commands = {}
local run_commands = {}

local dry_run = false
local needs_receiving = false

-- wrapper functions to allow dry_runs
-- this is needed for the is_receiving function
-- mostly usefull for the map auto walk, to check
-- if it needs to stop
local function send_to_mud(s)
    if not dry_run then
        mud.send(s, {
            gag = true
        })
    end
end

local function add_command(alias, re_str, fun)
    table.insert(alias_commands, alias)
    table.insert(run_commands, {
        re = regex.new(re_str),
        command = fun
    })
end

-- commands

-- do command

local RE_DO_SPLIT = regex.new("((?:[^;\\\\]|[\\\\]+.)+)")

local function do_(s) -- do comman with "_" cause of the lua reseved word do
    local needs_to_wait = false
    local matches = RE_DO_SPLIT:match_all(s)
    for _, match in ipairs(matches) do
        local command = match[1]:replace("\\;", ";")
        if not dry_run then
            send_to_mud(command)
        end
    end
end

add_command("do", "^/do (.*)$", do_)

local function _run(s)
    for _, e in ipairs(run_commands) do
        local m = e.re:match(s)
        if m then
            e.command(m[2])
            break
        end
    end
end

function Macros.run(s)
    _run(s)
end

function Macros.is_receiving(s)
    dry_run = true
    needs_receiving = false
    _run(s)
    dry_run = false
    return needs_receiving
end

aliases:add("^/(?:" .. table.concat(alias_commands) .. ").*$", function(m)
    Macros.run(m[1])
end)

return Macros
