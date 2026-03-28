-- PIDStandard.lua

-- Components

local PID = {}
PID.__index = PID

function PID:new(Kp, Ki, Kd)
    local obj = {
        -- Coeffitients
        Kp = Kp or 0.,
        Ki = Ki or 0.,
        Kd = Kd or 0.,

        -- Auxiliary values
        integral = nil,
        previous_error = nil
    }
    setmetatable(obj, PID)
    return obj
end

function PID:correct()
    return coroutine.create(
        function(current, target, delta_time)
            while true do
                local output

                if type(target) == "table" then -- PID controller corrects vector value
                    -- Vector error value
                    local error = {}
                    for i = 1, #target do
                        error[i] = target[i] - current[i]
                    end

                    -- Vector proportional gain
                    local P = {}
                    for i = 1, #error do
                        P[i] = error[i]
                    end

                    -- Vector integral gain
                    if not self.integral then
                        self.integral = {}
                    end
                    for i = 1, #error do
                        self.intagral[i] = (self.integral[i] or 0) + error[i] * delta_time
                    end
                    local I = {}
                    for i = 1, #self.integral do
                        I[i] = self.integral[i]
                    end

                    -- Vector derivative gain
                    if not self.previous_error then
                        self.previous_error = {}
                    end
                    local D = {}
                    for i = 1, #error do
                        D[i] = (error[i] - (self.previous_error[i] or 0)) / delta_time
                        self.previous_error[i] = error[i]
                    end

                    -- Vector control output
                    output = {}
                    for i = 1, #target do
                        output[i] = P[i] * self.Kp + I[i] * self.Ki + D[i] * self.Kd
                    end
                else -- PID controller corrects scalar value
                    -- Scalar error value
                    local error = target - current

                    -- Scalar proportional gain
                    local P = error

                    -- Scalar integral gain
                    self.accumulator = (self.accumulator or 0) + error * delta_time
                    local I = self.accumulator

                    -- Scalar derivative gain
                    local D = (error - (self.previous_error or 0)) / delta_time
                    self.previous_error = error

                    -- Scalar control output
                    output = P * self.Kp + I * self.Ki + D * self.Kd
                end

                -- Yield the control output and pause until resumed
                coroutine.yield(output)
            end
        end
    )
end

return PID
