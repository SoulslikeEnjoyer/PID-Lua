-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")
local types  = require("pl.types" )

-- Local components
local utils  = require("PID.utils")

-- Temporary components
local inspect = require("inspect")

-- Class declaration
local Path = class()

-- Class initialization method
function Path:_init(controller, start, record_size)
    -- Type safety checks
    assert(not types.is_type(controller, "nil") and types.is_callable(controller.correct),
        "controller.correct method can not be called")
    assert(not types.is_type(start, "nil") and types.is_type(start.time, "number"),
        "start.time field is not a number")
    assert(not types.is_type(start, "nil") and (types.is_type(start.position, "number") or utils.is_vector(start.position)),
        "start.position field is neither a scalar nor a vector value")
    assert(types.is_type(record_size, "nil") or types.is_type(record_size, "number") and types.is_integer(record_size),
        "record_size optional parameter is not an integer number")

    -- Initialization
    self.controller = tablex.deepcopy(controller)
    self.current = {
        timestamp = start.time,
        position = tablex.deepcopy(start.position),
        speed = (not types.is_type(start.position, "number")) and {} or 0 -- ternary operation
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

-- Path moving method
function Path:move()
    return coroutine.create(
        function(target, delta_time)
            while true do
                -- Type safety checks
                assert(types.is_type(self.current.position, "number") and types.is_type(target, "number") or
                    utils.is_vector(self.current.position) and utils.is_vector(target) and
                    utils.have_same_keys(self.current.position, target),
                    "Current and target positions do not correspond mathematically")
                assert(types.is_type(delta_time, "number"),
                    "delta_time parameter is not a number")

                -- Next record data
                local next = {
                    timestamp = 0,
                    position  = (not types.is_type(self.current.position, "number")) and {} or 0, -- ternary operation
                    speed     = (not types.is_type(self.current.speed   , "number")) and {} or 0  -- ternary operation
                }

                -- Calculate next timestamp
                next.timestamp = self.current.timestamp + delta_time
                -- Calculate control value (acceleration)
                local _, control = assert(coroutine.resume(self.controller:correct(), self.current.position, target, delta_time))
                assert(types.is_type(self.current.position, "number") and types.is_type(control, "number") or
                    utils.is_vector(self.current.position) and utils.is_vector(control) and
                    utils.have_same_keys(self.current.position, control),
                    "Current position and control value do not correspond mathematically")
                if types.is_type(self.current.position, "number") then -- monodimensional trajectory travel
                    -- Calculate next speed value
                    next.speed = self.current.speed + control * delta_time
                    -- Calculate next position
                    next.position = self.current.position + next.speed * delta_time
                else -- multidimensional trajectory travel
                    for key, _ in pairs(self.current.position) do
                        -- Calculate next speed value
                        next.speed[key] = (self.current.speed[key] or 0) + control[key] * delta_time
                        -- Calculate next position
                        next.position[key] = self.current.position[key] + next.speed[key] * delta_time
                    end
                end

                -- Update current state of the system
                self.current = tablex.deepcopy(next)

                -- Add current timestamp to path record
                table.insert(self.record.timestamps, self.current.timestamp)
                while #self.record.timestamps > self.record.size do
                    table.remove(self.record.timestamps, 1)
                end

                -- Add current position to path record
                table.insert(self.record.positions, tablex.deepcopy(self.current.position))
                while #self.record.positions > self.record.size do
                    table.remove(self.record.positions, 1)
                end

                -- Yield the current position and pause until resumed
                coroutine.yield(self.current.position)
            end
        end
    )
end

return Path
