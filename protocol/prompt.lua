local Prompt = {
    previous_prompt = "",
    current_prompt = ""
}

local output_since_last_prompt = ""

local statusbar = require("ui.statusbar")
local output_hooks = {}
local output_at_prompt_hooks = {}

function Prompt.update(self)
    if Prompt.previous_prompt ~= Prompt.current_prompt then
        statusbar:update()
    end
    Prompt.previous_prompt = Prompt.current_prompt
    if #output_at_prompt_hooks > 0 then
        for _, hook in ipairs(output_at_prompt_hooks) do
            hook(output_since_last_prompt, hook)
        end
    end
    if output_since_last_prompt ~= "" then
        output_since_last_prompt = ""
    end
end

function Prompt.init(self)
    -- output prompt to statusbar
    trigger.add("^.*$", {
        prompt = true,
        gag = true
    }, function(m)
        Prompt.current_prompt = m[1]
        Prompt:update()
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

function Prompt.add_output_hook(fun, wait_until_prompt)
    if wait_until_prompt then
        table.insert(output_at_prompt_hooks, fun)
    else
        table.insert(output_hooks, fun)
    end
end

function Prompt.remove_output_hook(fun)
    for i = #output_hooks, 1, -1 do
        if output_hooks[i] == fun then
            table.remove(output_hooks, i)
        end
    end
    for i = #output_at_prompt_hooks, 1, -1 do
        if output_at_prompt_hooks[i] == fun then
            table.remove(output_at_prompt_hooks, i)
        end
    end
end

mud.add_output_listener(function(line)
    if not line:prompt() then
        if #output_hooks > 0 or #output_at_prompt_hooks > 0 then
            if output_since_last_prompt == "" then
                output_since_last_prompt = line:line()
            else
                output_since_last_prompt = output_since_last_prompt .. "\n" .. line:line()
            end
            for _, hook in ipairs(output_hooks) do
                hook(output_since_last_prompt, hook)
            end
        end
    end
    return line
end)

statusbar:add_value("prompt", "MG - Aktuelles Prompt", Prompt, "current_prompt")

return Prompt
