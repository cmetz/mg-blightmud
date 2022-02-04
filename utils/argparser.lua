local ArgParser = {}

local class = require("utils.class")

-- Arguments

local Arguments = class()

function Arguments:initialize()
    self:reset()
end

function Arguments:reset()
    self.arguments = {}
    self.flags = {}
    self.input = {}
    return self
end

function Arguments:add_argument(name, value)
    self.arguments[name] = value
    return self
end

function Arguments:add_flag(flag)
    for f in string.gmatch(flag, ".") do
        if self.flags[f] then
            self.flags[f] = self.flags[f] + 1
        else
            self.flags[f] = 1
        end
    end
    return self
end

function Arguments:add_input(input)
    table.insert(self.input, input)
    return self
end

-- Argparser

--[[
Regex for parsing arguments
complete = (?:(?:(?:--)([^\s=-]+)(?:=(\"(?:[^\"\\]|[\\]+.)*\"|\S+))?)|(?:-([^\s]+))|((?:\"(?:[^\"\\]|[\\]+.)*\")|\S+))(?:\s+|$)

# explination:

# allow different input options
(?:
# long argument:
#         --    name       =  "   value            "  or   value
    (?:(?:--)([^\s=-]+)(?:=(\"(?:[^\"\\]|[\\]+.)*\"  |    \S+))?)

    | # or

# flags
#      -  flags
    (?:-([^\s-]+))

    | #or 

# command / text
         " command            "    or  command
    ((?:\"(?:[^\"\\]|[\\]+.)*\")   |   \S+)
)
(?:\s+|$)           # delimiter space and end
]]

--[[
Long args
--test="\"Das ist ja Toll\"" --> test: "Das ist ja Toll"
--test=super                 --> test: super
--test="" and --test         --> test:
]]
local PATTERN_LONG_ARG = "(?:(?:--)([^\\s=-]+)(?:=(\"(?:[^\"\\\\]|[\\\\]+.)*\"|\\S+))?)"
local RE_LONG_NAME_GROUP = 2
local RE_LONG_VALUE_GROUP = 3

--[[
Flag args could be either combined or single, as value the get counted
-test           -> test --> splitted later --> t=2 e=1 s=1
-t -e -s -t     --> flag: t=2 e=1 s=1
-vvv            --> v=3
--              --> -=1
---             --> -=2
---t            --> -=2 t=1
]]
local PATTERN_FLAG_ARG = "(?:-([^\\s-]+))"
local RE_FLAG_GROUP = 4

--[[
Command / test
test text    -> 'test' 'test'
"test text"  -> 'test text'
"test\" text"-> 'text " text'
]]
local PATTERN_CMD_TXT_ARG = "((?:\"(?:[^\"\\\\]|[\\\\]+.)*\")|\\S+)"
local RE_CMD_TXT_GROUP = 5

-- whitespace and end of line as delimter for every argument
local PATTERN_ARG_DELIMITER = "(?:\\s+|$)"

-- the combined regex
local PATTERN_COMPLETE_ARG =
    "(?:" .. PATTERN_LONG_ARG .. "|" .. PATTERN_FLAG_ARG .. "|" .. PATTERN_CMD_TXT_ARG .. ")" .. PATTERN_ARG_DELIMITER

-- the compiled regex object
local RE_PARSE_ARGS = regex.new(PATTERN_COMPLETE_ARG)

-- trim extra and unescape qoutes from parsed values
-- "test\"test" --> test"test
local function unescape(s)
    if s:sub(1, 1) == "\"" and s:sub(-1) == "\"" then
        s = s:sub(2, -2):replace("\\\"", "\"")
    end
    return s
end

function ArgParser.parse(s, reused_arguments)
    local arguments = reused_arguments or Arguments()

    if s and s ~= "" then
        local args = RE_PARSE_ARGS:match_all(s)
        for _, arg in ipairs(args) do
            if arg[RE_LONG_NAME_GROUP] ~= "" then
                arguments:add_argument(arg[RE_LONG_NAME_GROUP], unescape(arg[RE_LONG_VALUE_GROUP]))
            elseif arg[RE_FLAG_GROUP] ~= "" then
                arguments:add_flag(arg[RE_FLAG_GROUP])
            elseif arg[RE_CMD_TXT_GROUP] ~= "" then
                arguments:add_input(unescape(arg[RE_CMD_TXT_GROUP]))
            end
        end
    end
    return arguments
end

-- example alias to test args, for testing purpose only
alias.add("/test_args ?(.*)?", function(m)
    local args = ArgParser.parse(m[2])
    print("Arguments:")
    for name, value in pairs(args.arguments) do
        print(string.format("  %s: %s", name, value))
    end
    print("Flags:")
    for flag, count in pairs(args.flags) do
        print(string.format("  %s: %s", flag, count))
    end
    print("Input:")
    for _, input in pairs(args.input) do
        print(string.format("  %s", input))
    end
end)

ArgParser.Arguments = Arguments

return ArgParser
