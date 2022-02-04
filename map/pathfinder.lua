local class = require("utils.class")

local PathFinder = class()
function PathFinder:initialize(get_rooms_fun)
    self.get_rooms_fun = get_rooms_fun
    self._cache = {}
end

function PathFinder:_add_to_cache(from_id, to_id, path)
    local path_id = string.format("%s to %s", from_id, to_id)
    self._cache[path_id] = path
end

function PathFinder:_get_from_cache(from_id, to_id)
    local path_id = string.format("%s_%s", from_id, to_id)
    if self._cache[path_id] then
        return self._cache[path_id]
    end
end

function PathFinder:clear_cache()
    self._cache = {}
end

-- path finding djikstra -- TODO: implement a Binary Heap?
function PathFinder:find_path(from_id, to_id)
    if type(from_id) ~= "string" or type(to_id) ~= "string" then
        return
    end
    if from_id == to_id then
        return {}
    end
    local cached_path = self:_get_from_cache(from_id, to_id)
    if cached_path then
        return cached_path
    end
    local rooms = self.get_rooms_fun()
    local not_visited = {}
    local distance = {}
    local path = {}
    table.insert(not_visited, from_id)
    distance[from_id] = 0
    path[from_id] = from_id
    for id, _ in pairs(rooms) do
        if id ~= from_id then
            table.insert(not_visited, id)
            distance[id] = math.huge
        end
    end

    while #not_visited > 0 do
        local current = table.remove(not_visited, 1)
        if current == to_id then
            break
        end
        for _, exit in ipairs(rooms[current].exits) do
            if exit.to_room then
                local new_dist = distance[current] + 1
                local nb = exit.to_room
                if new_dist < distance[nb] then
                    distance[nb] = new_dist
                    path[nb] = current
                end
            end
        end
        table.sort(not_visited, function(a, b)
            return distance[a] < distance[b]
        end)
    end
    local ret = {}
    if path[to_id] then
        local last = to_id
        while last do
            local prev = path[last]
            -- table.insert(ret, 1, rooms[prev]:get_direction_to(last))
            table.insert(ret, 1, {
                from = prev,
                to = last
            })
            last = prev
            if last == from_id then
                break
            end
        end
        self:_add_to_cache(from_id, to_id, ret)
    end
    return ret
end

return PathFinder
