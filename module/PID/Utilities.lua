-- Cpmponents
local types = require("pl.types")

-- Temporary components
local inspect = require("inspect")

local utils = {}

function utils.equal(a, b, epsilon)
    -- Type safety checks
    assert(types.is_type(a, "number"),
        "a parameter is not a number")
    assert(types.is_type(b, "number"),
        "b parameter is not a number")
    assert(types.is_type(epsilon, "nil") or types.is_type(epsilon, "number"),
        "epsilon optional parameter is not a number")

    -- Floating-point numbers comparison
    epsilon = epsilon or (2.0 ^ -52)
    return a == b or math.abs(a - b) < epsilon
end

function utils.is_vector(object)
    if types.is_iterable(object) then
        for _, value in pairs(object) do
            if not types.is_type(value, "number") then
                return false
            end
        end
    else
        return false
    end
    return true
end

function utils.have_same_keys(t1, t2)
    for k, _ in pairs(t1) do
        if t2[k] == nil then
            return false
        end
    end
    for k, _ in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end
    return true
end

return utils
