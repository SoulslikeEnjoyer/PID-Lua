-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")
local types  = require("pl.types" )

-- Temporary components
local inspect = require("inspect")

-- Auxiliary type definitions
--- @class vector<T>: { [(integer | string)]: T } # Vector value type

-- Module class definition
--- @generic T: (number | vector<number>)
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
--- @field public _init function # Constructor
--- | fun(self: PID<T>, Kp: number, Ki: number, Kd: number, PonM?: number)
--- 
--- @field public clear function # Clear data storage and accumulators
--- | fun(self: PID<T>)
--- 
--- @field public update function # Calculate control output
--- | fun(self: PID<T>, input: T, target: T, delta_time: number): T
--- 
--- protected:
--- @field protected storage {
---     input: T?,
---     target: T?,
--- } # Storage for previous measured state of the system
---     
--- private:
--- @field private _PonM number # Backing field for proportional term weight accessors
--- @field private _impl {
---     update: (fun(self: PID<T>): thread),
--- }
local PID = class()
PID._impl = {}

function PID:_init(Kp, Ki, Kd, PonM)
    -- Initialization with common term properties
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
                    self._PonM = 1 - math.min(math.max(PonE, 0), 1) -- clamping weight between 0 and 1
                end
                return 1 - self._PonM
            end
        },
        measurement = {
            weight =
            function (PonM)
                if PonM ~= nil then
                    self._PonM = math.min(math.max(PonM, 0), 1) -- clamping weight between 0 and 1
                end
                return self._PonM
            end,
            accumulator = nil
        },
    } self._PonM = (PonM ~= nil) and PonM or 0 -- ternary construction

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

--- PID-Controller update method implementation
--- @generic T: (number | vector<number>)
--- @param self PID<T> # Controller itself
--- @return thread # PID-Controller update coroutine
local update_impl = function(self)
    --- Floating-point numbers equality function
    --- @param a number # First number of comparison
    --- @param b number # Second number to compare with
    --- @param epsilon? number # Precision of comparison (oprional parameter)
    --- @return boolean # Result of numbers comparison
    local function equal(a, b, epsilon)
        epsilon = epsilon or (2.0 ^ -52) -- double precision by default
        return a == b or math.abs(a - b) < epsilon * math.max(math.abs(a), math.abs(b))
    end
    return coroutine.create(
        --- Hidden PID-Controller logic implementation
        --- @generic T: (number | vector<number>)
        --- @param input T # Measured input value
        --- @param target T # Target to be reached
        --- @param delta_time number # Time passed since last update
        function(input, target, delta_time)
            while true do

                local scalar_value = types.is_type(input, "number")

                -- Control output value
                local output = scalar_value and 0 or {} -- ternary construction

                -- Error value
                local error = scalar_value and 0 or {} -- ternary construction
                if scalar_value then
                    error = target - input
                else
                    for key, _ in pairs(input) do
                        error[key] = target[key] - input[key]
                    end
                end

                -- Measurement value
                local measurement = nil
                if self.storage.input ~= nil then
                    measurement = scalar_value and 0 or {} -- ternary construction
                    if scalar_value then
                        measurement = input - self.storage.input
                    else
                        for key, _ in pairs(input) do
                            measurement[key] = input[key] - self.storage.input[key]
                        end
                    end
                end

                -- PID Controller logic
                if scalar_value then -- PID controller regulates scalar value
                    -- Proportional term
                    if self.term.proportional.gain ~= 0 then
                        -- Term
                        local P = 0

                        -- Proportional on Error
                        if self.term.proportional.on.error.weight() ~= 0 then
                            local PonE = error
                            P = P + self.term.proportional.gain * self.term.proportional.on.error.weight() * PonE
                        end
                        -- Proportional on Measurement
                        if measurement ~= nil and self.term.proportional.on.measurement.weight() ~= 0 then
                            self.term.proportional.on.measurement.accumulator = (self.term.proportional.on.measurement.accumulator or 0) + measurement
                            local PonM = -self.term.proportional.on.measurement.accumulator
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
                        -- Term
                        local I = 0

                        -- Integral on Error
                        self.term.integral.accumulator = (not equal(target, input)) and -- ternary construction
                            (self.term.integral.accumulator or 0) + error * delta_time or
                            0
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
                        -- Term
                        local D = 0

                        -- Derivative on Measurement
                        if measurement ~= nil then
                            local DonM = -measurement / delta_time
                            D = D + self.term.derivative.gain * DonM
                        end

                        -- Clamp to acceptable limits
                        if self.term.derivative.limit ~= nil then
                            D = math.min(math.max(D, -self.term.derivative.limit), self.term.derivative.limit)
                        end

                        -- Contribution to the control output
                        output = output + D
                    end
                end

                -- Update storage data
                self.storage = {
                    input  = tablex.deepcopy(input ),
                    target = tablex.deepcopy(target)
                }

                -- Yield the control output and pause until resumed
                coroutine.yield(output)
            end
        end
    )
end PID._impl.update = update_impl

function PID:update(input, target, delta_time)
    local _, output = assert(coroutine.resume(self._impl.update(self), input, target, delta_time))
    return output
end

return PID
