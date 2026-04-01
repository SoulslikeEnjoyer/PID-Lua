-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")
local types  = require("pl.types" )

-- Local components
local utils  = require("PID.utils")

-- Class declaration
local PID = class()

-- Class initialization method
function PID:_init(Kp, Ki, Kd)
    -- Type safety checks
    assert(types.is_type(Kp, "number"),
        "Kp coeffitient parameter is not a number")
    assert(types.is_type(Ki, "number"),
        "Ki coeffitient parameter is not a number")
    assert(types.is_type(Kd, "number"),
        "Kd coeffitient parameter is not a number")

    -- Initialization
    self.Kp = Kp
    self.Ki = Ki
    self.Kd = Kd
    self.storage = {
        integral = nil,
        error    = nil
    }
end

function PID:correct()
    return coroutine.create(
        function(input, target, delta_time)
            while true do
                -- Type safety checks
                assert(types.is_type(input, "number") and types.is_type(target, "number") or
                    utils.is_vector(input) and utils.is_vector(target) and
                    utils.have_same_keys(input, target),
                    "Input value and target value do not correspond mathematically")
                assert(types.is_type(delta_time, "number"),
                    "delta_time parameter is not a number")

                -- Control output value
                local output = nil

                if types.is_type(input, "number") then -- PID controller regulates scalar value
                    -- Scalar control output value
                    output = 0

                    -- Error value
                    local error = target - input

                    -- Proportional gain
                    if self.Kp ~= 0 then
                        -- Gain
                        local P = error

                        -- Contribution
                        output = output + self.Kp * P
                    end

                    -- Integral gain
                    if self.Ki ~= 0 then
                        -- Gain
                        if self.storage.integral == nil then
                            self.storage.integral = 0
                        end
                        self.storage.integral = (not utils.equal(error, 0)) and -- ternary operation
                            self.storage.integral + error * delta_time or
                            0
                        local I = self.storage.integral

                        -- Contribution
                        output = output + self.Ki * I
                    end

                    -- Derivative gain
                    if self.Kd ~= 0 then
                        -- Gain
                        local D = 0
                        if self.storage.error ~= nil then
                            D = (error - self.storage.error) / delta_time
                        end
                        self.storage.error = error

                        -- Contribution
                        output = output + self.Kd * D
                    end
                else -- PID controller regulates vector value
                    -- Vector control output value
                    output = {}
                    for key, _ in pairs(input) do
                        output[key] = 0
                    end

                    -- Error value
                    local error = {}
                    for key, _ in pairs(error) do
                        error[key] = target[key] - input[key]
                    end

                    -- Proportional gain
                    if self.Kp ~= 0 then
                        -- Gain
                        local P = tablex.deepcopy(error)

                        -- Contribution
                        for key, _ in pairs(output) do
                            output[key] = output[key] + self.Kp * P[key]
                        end
                    end

                    -- Integral gain
                    if self.Ki ~= 0 then
                        -- Gain
                        if self.storage.integral == nil then
                            self.storage.integral = {}
                        end
                        for key, _ in pairs(input) do
                            self.storage.integral[key] = (not utils.equal(error[key], 0)) and -- ternary operation
                                (self.storage.integral[key] or 0) + error[key] * delta_time or
                                0
                        end
                        local I = tablex.deepcopy(self.storage.integral)

                        -- Contribution
                        for key, _ in pairs(output) do
                            output[key] = output[key] + self.Ki * I[key]
                        end
                    end

                    -- Derivative gain
                    if self.Kd ~= 0 then
                        -- Gain
                        local D = {}
                        if self.storage.error ~= nil then
                            for key, _ in pairs(error) do
                                D[key] = (error[key] - self.storage.error[key]) / delta_time
                            end
                        end
                        for key, _ in pairs(error) do
                            self.storage.error[key] = error[key]
                        end

                        -- Contribution
                        for key, _ in pairs(output) do
                            output[key] = output[key] + self.Kd * D[key]
                        end
                    end
                end

                -- Yield the control output and pause until resumed
                coroutine.yield(output)
            end
        end
    )
end

return PID
