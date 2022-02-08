Macros = {}

-- unsorted list of macors
local argparser = require("utils.argparser")
local prompt = require("protocol.prompt")

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

local function start_receiving_mud_data(fun)
    if not dry_run then
        prompt.add_output_hook(fun)
    end
    needs_receiving = true
end

local function stop_receiving_mud_data(fun)
    if not dry_run then
        prompt.remove_output_hook(fun)
    end
end

local function wait(time, fun)
    if not dry_run then
        timer.add(time, 1, fun)
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

-- do trigger command

local RE_DO_TRIGGER_SPLIT = regex.new("([^:]+):([^:]+):([^:]+):?([^:]+)?")
-- /do_trigger unt wegekreuz:zeigt nach (\w+),\s(\w+)\sund\s(\w+):$1:l
local function do_trigger(s)
    local m = RE_DO_TRIGGER_SPLIT:match(s)
    if m then
        local before = m[2]
        local check_for = m[3]
        local after = m[4]
        local flags = m[5]
        local handler_call_count = 0
        local data_handler = function(data, me)
            handler_call_count = handler_call_count + 1
            local re = regex.new("^.*" .. check_for .. ".*$", {
                dot_matches_new_line = true,
                case_insensitive = true
            })
            if string.find(flags, "l") then
                data = string.lower(data)
            end
            local after_replaced = re:replace(data, after)
            if after_replaced ~= data then
                do_(after_replaced)
                stop_receiving_mud_data(me)
            elseif handler_call_count > 9 then
                stop_receiving_mud_data(me)
                print(cformat("<red>/do_trigger %s hat nach 10 MG Zeilen nichts gefunden. Entfernt!<reset>", m[1]))
            end
        end
        start_receiving_mud_data(data_handler)
        do_(before)
    end
end

add_command("do_trigger", "^/do_trigger (([^:]+):([^:]+):([^:]+):?([^:]+)?)$", do_trigger)

-- do wait command

local RE_DO_WAIT_SPLIT = regex.new("(\\d+):([^:]+)")

local function do_wait(s)
    local m = RE_DO_WAIT_SPLIT:match(s)
    if m then
        local wait_time = tonumber(m[2])
        local what = m[3]
        wait(wait_time, function()
            do_(what)
        end)
    end
end

add_command("do_wait", "^/do_wait ((\\d+):([^:]+))$", do_wait)

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

aliases:add("^/(?:" .. table.concat(alias_commands, "|") .. ").*$", function(m)
    Macros.run(m[1])
end)

return Macros
