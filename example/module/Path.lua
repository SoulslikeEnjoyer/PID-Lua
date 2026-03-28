-- Path.lua

local Path = {}
Path.__index = Path

function Path:new(controller, starting_position, record_size)
    local obj = {
        controller = controller,
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
    if type(starting_position) == "table" then -- multidimensional trajectory travel
        obj.current.position = {}
        for i = 1, #starting_position do
            obj.current.position[i] = starting_position[i]
        end
        table.insert(obj.record.positions, {})
        for i = 1, #starting_position do
            obj.record.positions[1][i] = obj.current.position[i]
        end
    else -- single dimension trajectory travel
        obj.current.position = starting_position
        table.insert(obj.record.positions, obj.current.position)
    end
    setmetatable(obj, Path)
    return obj
end

function Path:move()
    return coroutine.create(
        function(target, delta_time)
            while true do
                -- Calculate next timestamp
                self.current.timestamp = self.current.timestamp + delta_time

                -- Calculate next position
                local _, velocity = coroutine.resume(self.controller:correct(), self.current.position, target, delta_time)
                if type(velocity) == "table" then -- multidimensional trajectory travel
                    for i = 1, #self.current.position do
                        self.current.position[i] = self.current.position[i] + velocity[i] * delta_time
                    end
                else -- single dimension trajectory travel
                    self.current.position = self.current.position + velocity * delta_time
                end

                -- Add current timestamp to path record
                table.insert(self.record.timestamps, self.current.timestamp)
                while #self.record.timestamps > self.record.size do
                    table.remove(self.record.timestamps, 1)
                end

                -- Add current position to path record
                if type(self.current.position) == "table" then -- multidimensional trajectory travel
                    table.insert(self.record.positions, {})
                    for i = 1, #self.current.position do
                        self.record.positions[#self.record.positions][i] = self.current.position[i]
                    end
                else -- single dimension trajectory travel
                    table.insert(self.record.positions, self.current.position)
                end
                while #self.record.positions > self.record.size do
                    table.remove(self.record.positions, 1)
                end

                -- Yield the current poaition in a path and pause until resumed
                coroutine.yield(self.current.position)
            end
        end
    )
end

return Path
