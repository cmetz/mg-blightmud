local class = require("utils.class")

local Logger = class()

function Logger:initialize(name)
    Logger.name = name
end

function Logger:output(s, ...)
    print(cformat(s, ...))
end

function Logger:info(s, ...)
    self:output(C_GREEN .. s .. C_RESET, ...)
end

function Logger:warning(s, ...)
    self:output(C_YELLOW .. s .. C_RESET, ...)
end

function Logger:alert(s, ...)
    self:output(C_RED .. s .. C_RESET, ...)
end

function Logger:error(s, ...)
    self:output(C_RED .. s .. C_RESET, ...)
end

function Logger:debug(s, ...)
    self:output(C_CYAN .. s .. C_RESET, ...)
end

return Logger
