-- Trajectory.lua

local Trajectory = {}
Trajectory.__index = Trajectory

function Trajectory:new(calculation_rule, record_size)
    local starting_position = calculation_rule(0)
    local obj = {
        rule = calculation_rule,
        current = {
            timestamp = 0,
            position = nil
        },
        record = {
            size = record_size or 1,
            timestamps = { 0 },
            positions = {}
        },
    }
    if type(starting_position) == "table" then -- multidimensional trajectory
        obj.current.position = {}
        for i = 1, #starting_position do
            obj.current.position[i] = starting_position[i]
        end
        table.insert(obj.record.positions, {})
        for i = 1, #starting_position do
            obj.record.positions[1][i] = obj.current.position[i]
        end
    else -- single dimension trajectory
        obj.current.position = starting_position
        table.insert(obj.record.positions, obj.current.position)
    end
    setmetatable(obj, Trajectory)
    return obj
end

function Trajectory:calculate()
    return coroutine.create(
        function(delta_time)
            while true do
                -- Calculate next timestamp
                self.current.timestamp = self.current.timestamp + delta_time

                -- Calculate next position
                self.current.position = self.rule(self.current.timestamp)

                -- Add current timestamp to trajectory record
                table.insert(self.record.timestamps, self.current.timestamp)
                while #self.record.timestamps > self.record.size do
                    table.remove(self.record.timestamps, 1)
                end

                -- Add current position to trajectory record
                table.insert(self.record.positions, self.current.position)
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
