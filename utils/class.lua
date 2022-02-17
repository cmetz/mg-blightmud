local Class = function(attr)
    local class = attr or {}
    class.__index = class
    class.__call = function(_, ...)
        return class:new(...)
    end
    function class:new(...)
        local instance = setmetatable({}, class)
        if class.initialize then
            class.initialize(instance, ...)
        end
        return instance
    end
    function class:is_instance_of(cls)
        return getmetatable(self) == cls
    end
    return setmetatable(class, {
        __call = class.__call
    })
end

return Class
