-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")
local types  = require("pl.types" )

-- Local components
local utils  = require("PID.utils")

-- Class declaration
local Trajectory = class()

-- Class initialization method
function Trajectory:_init(calculation_rule, starting_time, record_size)
    -- Type safety checks
    assert(types.is_callable(calculation_rule),
        "calculation_rule parameter can not be called")
    assert(types.is_type(record_size, "nil") or types.is_type(starting_time, "number"),
        "starting_timestamp optional parameter is not a number")
    assert(types.is_type(record_size, "nil") or types.is_type(record_size, "number") and types.is_integer(record_size),
        "record_size optional parameter is not an integer number")

    -- Starting position (acquire and check)
    local starting_position = calculation_rule(starting_time or 0)
    assert(types.is_type(starting_position, "number") or utils.is_vector(starting_position),
        "calculation_rule parameter returns nor a number nor a vector value")

    -- Initialization
    self.rule = calculation_rule
    self.current = {
        timestamp = starting_time or 0,
        position  = tablex.deepcopy(starting_position)
    }
    self.record = {
        size = record_size or 0,
        timestamps = {},
        positions = {}
    }
    if self.record.size > 0 then
        table.insert(self.record.timestamps, self.current.timestamp)
        table.insert(self.record.positions, tablex.deepcopy(self.current.position))
    end
end

-- Trajectory calculation method
function Trajectory:calculate()
    return coroutine.create(
        function(delta_time)
            while true do
                -- Type safety checks
                assert(types.is_type(delta_time, "number"),
                    "delta_time parameter is not a number")

                -- Next record data
                local next = {
                    timestamp = 0,
                    position = nil
                }

                -- Calculate next timestamp
                next.timestamp = self.current.timestamp + delta_time
                self.current.timestamp = next.timestamp

                -- Calculate next position
                next.position = self.rule(self.current.timestamp)
                assert(types.is_type(self.current.position, "number") and types.is_type(next.position, "number") or
                    utils.is_vector(self.current.position) and utils.is_vector(next.position),
                    "next position, calculated by calculation rule does not correspond dimensionwise to previous position in a trajectory")
                self.current.position = next.position

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

                -- Yield the current poaition in a trajectory and pause until resumed
                coroutine.yield(self.current.position)
            end
        end
    )
end

return Trajectory
