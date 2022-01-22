local Prompt = {}
local statusbar = require("ui.statusbar")

function Prompt.init(self)
    -- output prompt to statusbar
    trigger.add("^.*$", {
        prompt = true,
        gag = true
    }, function(m)
        statusbar.prompt = m[1]
        statusbar:refresh()
    end)

    -- do not send empty lines to log and screen
    -- mostly used in prompt messages like more
    alias.add("^$", function(_, line)
        line:gag(true)
        mud.send(line:line(), {
            gag = true,
            skip_log = true
        })
    end)
end

return Prompt
