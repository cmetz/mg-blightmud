Macros = {}

-- unsorted list of macors
local argparser = require("utils.argparser")

local aliases = alias.add_group()

-- do command

local RE_DO = "^/do (.*)$"
local RE_DO_SPLIT = regex.new("((?:[^;\\\\]|[\\\\]+.)+)")

function do_(s)
    local matches = RE_DO_SPLIT:match_all(s)
    for _, match in ipairs(matches) do
        local command = match[1]:replace("\\;", ";")
        mud.send(command, {
            gag = true
        })
    end
end

local RUN_COMMANDS = {{
    re = regex.new(RE_DO),
    command = do_
}}

function Macros.run(s)
    for _, e in ipairs(RUN_COMMANDS) do
        local m = e.re:match(s)
        if m then
            e.command(m[2])
        end
    end
end

aliases:add(RE_DO, function(m)
    do_(m[2])
end)

return Macros
