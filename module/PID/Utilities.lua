-- Cpmponents
local types = require("pl.types")

local utils = {}

function utils.is_vector(value)
    local is_indexable = types.is_indexable(value)
    if is_indexable then
        for index = 1, #value do
            if not types.is_type(value[index], "number") then
                return false
            end
        end
    else
        return false
    end
    return true
end

return utils
