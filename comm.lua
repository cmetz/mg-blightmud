local Comm = {}

-- print gmcp message
function Comm.print_channel_message(msg, player, channel)
    print(msg)
end

-- Triggers

local comm_triggers = trigger.add_group()

-- Trigger: Teile mit (Empfaenger)
-- Rhoakka teilt Dir mit: test text
-- oder
-- Deine Freundin Rhoakka teilt Dir mit: test text
-- oder
-- Deine Feindin Rhoakka teilt Dir mit: test text

comm_triggers:add("^(?:Deine? (Freund(?:in)?|Feind(?:in)?) )?(\\w+) teilt Dir mit: (.*)$", {
    gag = true
}, function(match, line)
    local message = {
        friend = match[2] ~= "" and match[2] or nil,
        from = match[3],
        text = match[4]
    }
    if message.friend then
        print(cformat("<yellow>Von <byellow>%s %s: %s<reset>", message.friend, message.from, message.text))
    else
        print(cformat("<red>Von <bred>%s: %s<reset>", message.from, message.text))
    end
end)

-- Trigger Teile mit (Sender)
-- Du teilst Rhoakka mit: test text
-- oder
-- Du teilst deinen Freunden mit: test text
comm_triggers:add("^Du teilst ([Dd]einen )?(\\w+) mit: (.*)$", {
    gag = true
}, function(match, line)
    local message = {
        friend = match[2] ~= "" and true or false,
        to = match[3],
        text = match[4]
    }
    if message.friend then
        message.to = message.to:sub(1, -2) -- Freunden/Feinden -> Freunde/Feinde
        print(cformat("<magenta>An <bmagenta>%s: %s<reset>", message.to, message.text))
    else
        print(cformat("<cyan>An <bcyan>%s: %s<reset>", message.to, message.text))
    end

end)

return Comm
