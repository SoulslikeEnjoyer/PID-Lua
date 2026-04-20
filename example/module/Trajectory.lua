-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")

-- Temporary components
local inspect = require("inspect")

-- Module class declaration
--- @generic T: (number | vector<number>)
--- @class Trajectory<T> # Trajectory class
--- public:
--- @field public rule (fun(time: number): T) # Calculation rule of the trajectory
--- @field public current {
---     timestamp: number,
---     position: T,
--- } # Current timestamp and position in a trajectory
--- @field public record {
---     size: integer,
---     timestamps: number[],
---     positions: T[],
--- } # Record of recent timestamps and positions
--- 
--- @field public _init function # Constructor
--- | fun(self: Trajectory<T>, calculation_rule: (fun(time: number): T), starting_timestamp: number, record_size?: integer)
--- 
--- @field public clear function # Clear record and set position corresponding to the relevant timestamp (if passed)
--- | fun(self: Trajectory<T>, current_timestamp?: number)
--- 
--- @field public calculate function # Calculate next position in a trajectory
--- | fun(self: Trajectory<T>, delta_time: number): T
--- 
--- private:
--- @field private _impl {
---     calculate: (fun(self: Trajectory<T>): thread),
--- }
local Trajectory = class()
Trajectory._impl = {}

function Trajectory:_init(calculation_rule, starting_timestamp, record_size)
    self.rule = tablex.deepcopy(calculation_rule)
    self.current = {
        timestamp = starting_timestamp,
        position  = tablex.deepcopy(self.rule(starting_timestamp))
    }
    self.record = {
        size = record_size or 0,
        timestamps = {},
        positions  = {}
    }
    if self.record.size > 0 then
        table.insert(self.record.timestamps, self.current.timestamp)
        table.insert(self.record.positions, tablex.deepcopy(self.current.position))
    end
end

function Trajectory:clear(current_timestamp)
    -- Clearing record data
    self.record.timestamps = {}
    self.record.positions  = {}

    -- Updating current timestamp and position in the trajectory
    if current_timestamp ~= nil then
        self.current = {
            timestamp = current_timestamp,
            position  = tablex.deepcopy(self.rule(current_timestamp))
        }
    end
end

--- Tragectory calculation method implementation
--- @generic T: (number | vector<number>)
--- @param self Trajectory<T> # Trajectory itself
--- @return thread # Trajectory calculation coroutine
local calculate_impl = function(self)
    return coroutine.create(
        --- Hidden Trajectory calculation logic implementation
        --- @generic T: (number | vector<number>)
        --- @param delta_time number # Time passed since last trajectory calculation
        function(delta_time)
            while true do
                -- Next trajectory data
                local next = {
                    timestamp = 0,
                    position  = nil
                }

                -- Calculate next timestamp
                next.timestamp = self.current.timestamp + delta_time

                -- Calculate next position in a trajectory
                next.position = self.rule(next.timestamp)

                -- Update current timestamp and position
                self.current = tablex.deepcopy(next)

                -- Add current timestamp to trajectory record
                table.insert(self.record.timestamps, self.current.timestamp)
                while #self.record.timestamps > self.record.size do
                    table.remove(self.record.timestamps, 1)
                end

                -- Add current position to trajectory record
                table.insert(self.record.positions, tablex.deepcopy(self.current.position))
                while #self.record.positions > self.record.size do
                    table.remove(self.record.positions, 1)
                end

                -- Yield calculated position and pause until resumed
                coroutine.yield(self.current.position)
            end
        end
    )
end Trajectory._impl.calculate = calculate_impl

function Trajectory:calculate(delta_time)
    local _, position = assert(coroutine.resume(self._impl.calculate(self), delta_time))
    return position
end

return Trajectory
