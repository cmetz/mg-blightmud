local Prompt = {
    previous_prompt = "",
    current_prompt = ""
}

local statusbar = require("ui.statusbar")

function Prompt.update(self)
    statusbar:update()
end

function Prompt.init(self)
    -- output prompt to statusbar
    trigger.add("^.*$", {
        prompt = true,
        gag = true
    }, function(m)
        Prompt.current_prompt = m[1]
        if Prompt.previous_prompt ~= Prompt.current_prompt then
            Prompt.previous_prompt = Prompt.current_prompt
            Prompt:update()
        end
    end)

    -- do not send empty lines to log and screen
    -- mostly used in mud prompt messages like more
    alias.add("^$", function(_, line)
        line:gag(true)
        mud.send(line:line(), {
            gag = true,
            skip_log = true
        })
    end)

end

statusbar:add_value("prompt", "MG - Aktuelles Prompt", Prompt, "current_prompt")

return Prompt
