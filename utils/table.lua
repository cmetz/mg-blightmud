function table.keys(t)
    local ret = {}
    for k in pairs(t) do
        table.insert(ret, k)
    end
    return ret
end

function table.values(t)
    local ret = {}
    for _, v in pairs(t) do
        table.insert(ret, v)
    end
    return ret
end

function table.swap(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[v] = k
    end
    return ret
end

function table.extend(into, from)
    for i = 1, #from do
        into[#into + 1] = from[i]
    end
end
