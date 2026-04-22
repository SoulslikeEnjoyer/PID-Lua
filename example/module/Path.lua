-- Components
local class  = require("pl.class" )
local tablex = require("pl.tablex")
local types  = require("pl.types" )

-- Temporary components
local inspect = require("inspect")

-- Auxiliary type definitions
--- @class Vector<T>: { [(integer | string)]: T } # Vector value type

-- Module class declaration
--- @generic T: (number | Vector<number>)
--- @class Path<T> # Path class
--- public:
--- @field public controller PID<T> # PID-Controller used for path correction
--- @field public current {
---     timestamp: number,
---     position: T,
---     velocity: T,
--- } # Current timestamp, position and velocity of the body, moving along the trajectory
--- @field public record {
---     size: integer,
---     timestamps: number[],
---     positions: T[],
---     velocities: T[],
--- } # Record of recent timestamps, positions and velociries
--- 
--- @field public _init function # Constructor
--- | fun(self: Path<T>, controller: PID<T>, starting: { timestamp: number, position: T, velocity: T }, record_size?: integer)
--- @field public clear function # Clear record and change current timestamp, position and velocity to relevant values (if passed)
--- | fun(self: Path<T>, current?: { timestamp: number, position: T, velocity: T })
--- @field public move function # Move to the target position, using PID-Controller control output for acceleration control
--- | fun(self: Path<T>, target: T, delta_time: number): T
local Path = class()

function Path:_init(controller, starting, record_size)
    self.controller = tablex.deepcopy(controller)
    self.current = {
        timestamp = starting.timestamp,
        position  = tablex.deepcopy(starting.position),
        velocity  = tablex.deepcopy(starting.velocity)
    }
    self.record = {
        size = record_size or 0,
        timestamps = {},
        positions  = {},
        velocities = {}
    }
    if self.record.size > 0 then
        table.insert(self.record.timestamps, self.current.timestamp)
        table.insert(self.record.positions, tablex.deepcopy(self.current.position))
        table.insert(self.record.velocities, tablex.deepcopy(self.current.velocity))
    end
end

function Path:clear(current)
    -- Clearing record data
    self.record.timestamps = {}
    self.record.positions  = {}
    self.record.velocities = {}

    if current ~= nil then
        self.current = {
            timestamp = current.timestamp,
            position  = tablex.deepcopy(current.position),
            velocity  = tablex.deepcopy(current.velocity)
        }
    end
end

function Path:move(target, deltaTime)
    local scalarValue = types.is_type(target, "number")

    -- Next record data
    local next = {
        timestamp = 0,
        position  = scalarValue and 0 or {}, -- ternary construction
        velocity  = scalarValue and 0 or {}  -- ternary construction
    }

    -- Calculate next timestamp
    next.timestamp = self.current.timestamp + deltaTime
    -- Calculate control value (acceleration)
    local acceleration = self.controller:update(self.current.position, target, deltaTime)
    if scalarValue then
        -- Calculate next velocity value
        next.velocity = self.current.velocity + acceleration * deltaTime
        -- Calculate next position
        next.position = self.current.position + next.velocity * deltaTime
    else
        for key, _ in pairs(self.current.position) do
            -- Calculate next velocity value
            next.velocity[key] = (self.current.velocity[key] or 0) + acceleration[key] * deltaTime
            -- Calculate next position
            next.position[key] = self.current.position[key] + next.velocity[key] * deltaTime
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

    -- Add current velocity to path record
    table.insert(self.record.velocities, tablex.deepcopy(self.current.velocity))
    while #self.record.velocities > self.record.size do
        table.remove(self.record.velocities, 1)
    end

    -- Return current position
    return self.current.position
end

return Path
