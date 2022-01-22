string.replace = function(str, this, that)
    this = string.gsub(this, "[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
    that = string.gsub(that, "%%", "%%%%")
    return string.gsub(str, this, that)
end
