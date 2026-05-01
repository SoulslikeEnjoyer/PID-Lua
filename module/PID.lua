-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")

-- Temporary components
local inspect = require("inspect")

-- Auxiliary type definitions
--- @class Vector<T>: { [(integer | string)]: T } # Vector value type

-- Module class definition
--- @generic T: (number | Vector<number>)
--- @class PID<T> # PID-controller
--- public:
--- @field public term {
---     proportional: {
---         gain: number,
---         limit: number?,
---         on: {
---             error: {
---                 weight: (fun(PonE?: number): number),
---             },
---             measurement: {
---                 weight: (fun(PonM?: number): number),
---                 accumulator: T?,
---             },
---         },
---     },
---     integral: {
---         gain: number,
---         limit: number?,
---         accumulator: T?,
---     },
---     derivative: {
---         gain: number,
---         limit: number?,
---     },
--- } # List of PID-controller terms
--- 
--- @field public _init function # Construct PID-Controller object
--- | fun(self: PID<T>, Kp: number, Ki: number, Kd: number, PonM?: number)
--- @field public clear function # Clear data storage and accumulators
--- | fun(self: PID<T>)
--- @field public update function # Calculate control output
--- | fun(self: PID<T>, input: T, target: T, deltaTime: number): T
--- 
--- protected:
--- @field protected storage {
---     input: T?,
---     target: T?,
--- } # Storage for previous measured state of the system
---     
--- private:
--- @field private PonM_ number # Backing field for proportional term weight accessors
local PID = class()

function PID:_init(Kp, Ki, Kd, PonM)
    -- Initialization with common term properties
    --- @type { gain: number, limit: number? } # Common term properties
    local common = {
        gain  = 0,
        limit = nil
    }
    self.term = {
        proportional = tablex.deepcopy(common),
        integral     = tablex.deepcopy(common),
        derivative   = tablex.deepcopy(common)
    }

    -- Proportional term initialization and specific term properties
    self.term.proportional.gain = Kp
    self.term.proportional.on = {
        error = {
            weight =
            function (PonE)
                if PonE ~= nil then
                    self.PonM_ = 1 - math.min(math.max(PonE, 0), 1) -- clamping weight between 0 and 1
                end
                return 1 - self.PonM_
            end
        },
        measurement = {
            weight =
            function (PonM)
                if PonM ~= nil then
                    self.PonM_ = math.min(math.max(PonM, 0), 1) -- clamping weight between 0 and 1
                end
                return self.PonM_
            end,
            accumulator = nil
        },
    } self.PonM_ = (PonM ~= nil) and PonM or 0 -- ternary construction

    -- Integral term initialization and specific term properties
    self.term.integral.gain = Ki
    self.term.integral.accumulator = nil

    -- Derivative term initialization
    self.term.derivative.gain = Kd

    -- Data storage initialization
    self.storage = {
        input  = nil,
        target = nil
    }
end

function PID:clear()
    -- Clearing proportional term on measurement accumulator
    self.term.proportional.on.measurement.accumulator = nil

    -- Clearing integral term accumulator
    self.term.integral.accumulator = nil

    -- Clearing data storage
    self.storage = {
        input  = nil,
        target = nil
    }
end

--- Floating-point numbers equality function
--- @param a number # First number of comparison
--- @param b number # Second number to compare with
--- @param epsilon? number # Precision of comparison (oprional parameter)
--- @return boolean # Result of numbers comparison
local function equal(a, b, epsilon)
    epsilon = epsilon or (2.0 ^ -52) -- double precision by default
    return a == b or math.abs(a - b) < epsilon * math.max(math.abs(a), math.abs(b))
end
function PID:update(input, target, deltaTime)
    --- @type boolean # Flag to determine whether PID-Controller regulates scalar value
    local scalarValue = (type(input) == "number")

    --- @generic T: (number | Vector<number>)
    --- @type T # Control output value
    local output = scalarValue and 0 or {} -- ternary construction

    -- PID Controller logic
    if scalarValue then -- PID-Controller regulates scalar value
        --- @type number # Error value
        local error = target - input

        --- @type number? # Measurement value
        local measurement = nil
        if self.storage.input ~= nil then
            measurement = input - self.storage.input
        end

        -- Proportional term
        if self.term.proportional.gain ~= 0 then
            --- @type number # Term
            local P = 0

            -- Proportional on Error
            if self.term.proportional.on.error.weight() ~= 0 then
                --- @type number # Partial on error term contributon
                local PonE = error
                P = P + self.term.proportional.gain * self.term.proportional.on.error.weight() * PonE
            end
            -- Proportional on Measurement
            if measurement ~= nil and self.term.proportional.on.measurement.weight() ~= 0 then
                self.term.proportional.on.measurement.accumulator = (self.term.proportional.on.measurement.accumulator or 0) - measurement
                --- @type number # Partial on measurement term contributon
                local PonM = self.term.proportional.on.measurement.accumulator
                P = P + self.term.proportional.gain * self.term.proportional.on.measurement.weight() * PonM
            end

            -- Clamp to acceptable limits
            if self.term.proportional.limit ~= nil then
                P = math.min(math.max(P, -self.term.proportional.limit), self.term.proportional.limit)
            end

            -- Contribution to the control output
            output = output + P
        end

        -- Integral term
        if self.term.integral.gain ~= 0 then
            --- @type number # Term
            local I = 0

            -- Integral on Error
            self.term.integral.accumulator = (self.term.integral.accumulator or 0) + error * deltaTime
            if self.term.proportional.on.error.weight() == 1 and equal(target, input) then -- reset accumulator ONLY if proportional term is calculated on error fully
                self.term.integral.accumulator = 0
            end
            --- @type number # On error term contributon
            local IonE = self.term.integral.accumulator
            I = I + self.term.integral.gain * IonE

            -- Clamp to acceptable limits
            if self.term.integral.limit ~= nil then
                I = math.min(math.max(I, -self.term.integral.limit), self.term.integral.limit)
            end

            -- Contribution to the control output
            output = output + I
        end

        -- Derivative term
        if self.term.derivative.gain ~= 0 then
            --- @type number # Term
            local D = 0

            -- Derivative on Measurement
            if measurement ~= nil then
                --- @type number # On measurement term contributon
                local DonM = -measurement / deltaTime
                D = D + self.term.derivative.gain * DonM
            end

            -- Clamp to acceptable limits
            if self.term.derivative.limit ~= nil then
                D = math.min(math.max(D, -self.term.derivative.limit), self.term.derivative.limit)
            end

            -- Contribution to the control output
            output = output + D
        end
    else -- PID-Controller regulates vector value
        --- @type Vector<number> # Error value
        local error = tablex.deepcopy(target)
        for axis, _ in pairs(input) do
            error[axis] = (error[axis] or 0) - input[axis]
        end

        --- @type Vector<number>? # Measurement value
        local measurement = nil
        if self.storage.input ~= nil then
            measurement = tablex.deepcopy(input)
            for axis, _ in pairs(self.storage.input) do
                measurement[axis] = (measurement[axis] or 0) - self.storage.input[axis]
            end
        end

        -- Proportional term
        if self.term.proportional.gain ~= 0 then
            --- @type Vector<number> # Term
            local P = {}

            -- Proportional on Error
            if self.term.proportional.on.error.weight() ~= 0 then
                --- @type Vector<number> # Partial on error term contributon
                local PonE = error
                for axis, _ in pairs(PonE) do
                    P[axis] = (P[axis] or 0) + self.term.proportional.gain * self.term.proportional.on.error.weight() * PonE[axis]
                end
            end
            -- Proportional on Measurement
            if measurement ~= nil and self.term.proportional.on.measurement.weight() ~= 0 then
                if self.term.proportional.on.measurement.accumulator == nil then
                    self.term.proportional.on.measurement.accumulator = {}
                end
                for axis, _ in pairs(measurement) do
                    self.term.proportional.on.measurement.accumulator[axis] = (self.term.proportional.on.measurement.accumulator[axis] or 0) - measurement[axis]
                end
                --- @type Vector<number> # Partial on measurement term contributon
                local PonM = self.term.proportional.on.measurement.accumulator
                for axis, _ in pairs(PonM) do
                    P[axis] = (P[axis] or 0) + self.term.proportional.gain * self.term.proportional.on.error.weight() * PonM[axis]
                end
            end

            -- Clamp to acceptable limits
            if self.term.proportional.limit ~= nil then
                for axis, _ in pairs(P) do
                    P[axis] = math.min(math.max(P[axis], -self.term.proportional.limit), self.term.proportional.limit)
                end
            end

            -- Contribution to the control output
            for axis, _ in pairs(P) do
                output[axis] = (output[axis] or 0) + P[axis]
            end
        end

        -- Integral term
        if self.term.integral.gain ~= 0 then
            --- @type Vector<number> # Term
            local I = {}

            -- Integral on Error
            if self.term.integral.accumulator == nil then
                self.term.integral.accumulator = {}
            end
            for axis, _ in pairs(error) do
                self.term.integral.accumulator[axis] = (self.term.integral.accumulator[axis] or 0) + error[axis] * deltaTime
                if self.term.proportional.on.error.weight() == 1 and equal((target[axis] or 0), (input[axis] or 0)) then -- reset accumulator ONLY if proportional term is calculated on error fully
                    self.term.integral.accumulator[axis] = 0
                end
            end
            --- @type Vector<number> # On error term contributon
            local IonE = self.term.integral.accumulator
            for axis, _ in pairs(IonE) do
                I[axis] = (I[axis] or 0) + self.term.integral.gain * IonE[axis]
            end

            -- Clamp to acceptable limits
            if self.term.integral.limit ~= nil then
                for axis, _ in pairs(I) do
                    I[axis] = math.min(math.max(I[axis], -self.term.integral.limit), self.term.integral.limit)
                end
            end

            -- Contribution to the control output
            for axis, _ in pairs(I) do
                output[axis] = (output[axis] or 0) + I[axis]
            end
        end

        -- Derivative term
        if self.term.derivative.gain ~= 0 then
            --- @type Vector<number> # Term
            local D = {}

            -- Derivative on Measurement
            if measurement ~= nil then
                --- @type Vector<number> # On measurement term contributon
                local DonM = {}
                for axis, _ in pairs(measurement) do
                    DonM[axis] = -measurement[axis] / deltaTime
                end
                for axis, _ in pairs(DonM) do
                    D[axis] = (D[axis] or 0) + self.term.derivative.gain * DonM[axis]
                end
            end

            -- Clamp to acceptable limits
            if self.term.derivative.limit ~= nil then
                for axis, _ in pairs(D) do
                    D[axis] = math.min(math.max(D[axis], -self.term.derivative.limit), self.term.derivative.limit)
                end
            end

            -- Contribution to the control output
            for axis, _ in pairs(D) do
                output[axis] = (output[axis] or 0) + D[axis]
            end
        end
    end

    -- Update storage data
    self.storage = {
        input  = tablex.deepcopy(input ),
        target = tablex.deepcopy(target)
    }

    -- Return control output
    return output
end

return PID
