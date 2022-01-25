string.replace = function(str, this, that)
    this = string.gsub(this, "[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
    that = string.gsub(that, "%%", "%%%%")
    return string.gsub(str, this, that)
end

string.cformat = function(str, ...)
    if ... then
        return cformat(str, ...)
    else
        return cformat(string.gsub(str, "%%", "%%%%"))
    end
end
