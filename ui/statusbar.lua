local Statusbar = {
    prompt = "",
    hp = 0,
    max_hp = 0,
    sp = 0,
    max_sp = 0,
    room_short = "",
    room_domain = ""
}

local STATUS_LINES = {"", "L:{hp} K:{sp}     {room_short} - {room_domain}", "{prompt}"}
local HP_MP_COLOR_RANGE = {C_RED, C_YELLOW, C_GREEN}

local function get_hp_mp_colorized(current, max)
    if max <= 0 then
        color_index = 1
    else
        color_index = math.max(math.ceil(current / max * #HP_MP_COLOR_RANGE), 1)
    end
    return HP_MP_COLOR_RANGE[color_index] .. current .. C_RESET
end

function Statusbar.init(self)
    blight.status_height(#STATUS_LINES)
    self:refresh()
end

function Statusbar.refresh(self)
    for i, line in pairs(STATUS_LINES) do
        line = line:replace("{prompt}", C_RESET .. self.prompt)
        line = line:replace("{hp}", get_hp_mp_colorized(self.hp, self.max_hp))
        line = line:replace("{sp}", get_hp_mp_colorized(self.sp, self.max_sp))
        line = line:replace("{max_hp}", self.max_hp)
        line = line:replace("{max_sp}", self.max_sp)
        line = line:replace("{room_short}", self.room_short)
        line = line:replace("{room_domain}", self.room_domain)
        blight.status_line(i - 1, line)
    end
end

return Statusbar
