-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")

-- Temporary components
local inspect = require("inspect")

-- Auxiliary type definitions
--- @class Vector<T>: { [(integer | string)]: T } # Vector value type

-- Module class declaration
--- @generic T: (number | Vector<number>)
--- @class State<T>: {
---     timestamp: number,
---     position: T,
---     velocity: T,
---     acceleration: T,
--- }
--- @class Path<T> # Path class
--- public:
--- @field public controller PID<T> # PID-Controller used for path correction
--- 
--- @field public _init function # Construct path object
--- | fun(self: Path<T>, controller: PID<T>, starting: { timestamp: number, position: T, velocity: T?, acceleration: T? }, recordCapacity?: integer)
--- @field public current function | # Get current state
--- | fun(self: Path<T>): State<T>
--- @field public record function | # Access trace record data
--- | fun(self: Path<T>): State<T>[]
--- @field public clear function # Clear record and set current state values to the relevant ones (if passed)
--- | fun(self: Path<T>, relevant?: State<T>, recordCapacity?: integer)
--- @field public move function # Move to the target position, using PID-Controller control output for acceleration control and return calculated state
--- | fun(self: Path<T>, targetPosition: T, deltaTime: number): State<T>
--- 
--- private:
--- @field private current_ State<T> # Current state
--- @field private traceRecord_ {
---     capacity: integer,
---     entries: State<T>[],
--- } # Record of recent states in the path
local Path = class()

function Path:_init(controller, starting, recordCapacity)
    self.controller = tablex.deepcopy(controller)

    self.traceRecord_ = {
        capacity = recordCapacity,
        entries = {}
    }

    --- @type boolean # Flag to determine whether movement is multidimensional
    local scalarValue = (type(starting.position) == "number")

    self.current_ = {
        timestamp    = starting.timestamp,
        position     = starting.position,
        velocity     = starting.velocity     or (scalarValue and 0 or {}), -- ternary construction
        acceleration = starting.acceleration or (scalarValue and 0 or {})  -- ternary construction
    }
    if self.traceRecord_.capacity > 0 then
        table.insert(self.traceRecord_.entries, tablex.deepcopy(self.current_))
    end
end

function Path:current()
    return tablex.deepcopy(self.current_)
end

function Path:record()
    return tablex.deepcopy(self.traceRecord_.entries)
end

function Path:clear(relevant, recordCapacity)
    -- Clear trace record data and update trace record capacity if passed
    self.traceRecord_.entries = {}
    if recordCapacity ~= nil then
        self.traceRecord_.capacity = recordCapacity
    end

    -- Update current state values if relevant values are passed
    if relevant ~= nil then
        self.current_ = tablex.deepcopy(relevant)
    end
    if self.traceRecord_.capacity > 0 then
        table.insert(self.traceRecord_.entries, tablex.deepcopy(self.current_))
    end
end

function Path:move(targetPosition, deltaTime)
    --- @type boolean # Flag to determine whether movement is multidimensional
    local scalarValue = (type(targetPosition) == "number")

    --- @generic T: (number | Vector<number>)
    --- @type State<T> # Next state
    local next = tablex.deepcopy(self.current_)

    -- Calculate next timestamp
    next.timestamp = next.timestamp + deltaTime
    -- Calculate next acceleration value
    next.acceleration = self.controller:update(self.current_.position, targetPosition, deltaTime)
    if scalarValue then -- movement is multidimensional
        -- Calculate next position
        next.position = next.position + next.velocity * deltaTime + next.acceleration * deltaTime ^ 2 / 2
        -- Calculate next velocity value
        next.velocity = next.velocity + next.acceleration * deltaTime
    else -- movement along single axis
        -- Calculate next position
        for axis, _ in pairs(next.velocity) do
            next.position[axis] = (next.position[axis] or 0) + next.velocity[axis] * deltaTime
        end
        for axis, _ in pairs(next.acceleration) do
            next.position[axis] = (next.position[axis] or 0) + next.acceleration[axis] * deltaTime ^ 2 / 2
        end
        -- Calculate next velocity value
        for axis, _ in pairs(next.acceleration) do
            next.velocity[axis] = (next.velocity[axis] or 0) + next.acceleration[axis] * deltaTime
        end
    end

    -- Update current state
    self.current_ = next

    -- Add current state to path record
    if #self.traceRecord_.entries > 0 then
        -- Uniformly accelerated motion
        self.traceRecord_.entries[#self.traceRecord_.entries].acceleration = tablex.deepcopy(self.current_.acceleration)
    end
    table.insert(self.traceRecord_.entries, tablex.deepcopy(self.current_))
    while #self.traceRecord_.entries > self.traceRecord_.capacity do
        table.remove(self.traceRecord_.entries, 1)
    end

    -- Return current state
    return tablex.deepcopy(self.current_)
end

return Path
