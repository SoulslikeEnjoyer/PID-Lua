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
--- }
--- @class Trajectory<T> # Trajectory class
--- public:
--- @field public calculationRule (fun(timestamp: number): T) # Rule to calculate position, corresponding to the specific timestamp
---
--- @field public _init function # Construct trajectory object
--- | fun(self: Trajectory<T>, calculationRule: (fun(timestamp: number): T), startingTimestamp: number, recordCapacity?: integer)
--- @field public current function | # Get current calculated state
--- | fun(self: Trajectory<T>): State<T>
--- @field public record function | # Access trace record data
--- | fun(self: Trajectory<T>): State<T>[]
--- @field public clear function # Clear record and set position corresponding to the relevant timestamp (if passed)
--- | fun(self: Trajectory<T>, relevantTimestamp?: number, recordCapacity?: integer)
--- @field public calculate function # Calculate next state
--- | fun(self: Trajectory<T>, deltaTime: number): State<T>
--- 
--- private:
--- @field private currentTimestamp_ number # Current timestamp in a trajectory
--- @field private traceRecord_ {
---     capacity: integer,
---     entries: number[],
--- } # Record of recent trajectory calculations
--- @field private cache_ {
---     [(fun(timestamp: number): T)]: {
---         [number]: T,
---     },
--- } # Cache storage for calculated positions, corresponding to specific calculation rule and specific timestamp
---
--- @field private cache_entry_ function | # Get position in a trajectory (precalculate if necessary)
--- | fun(self: Trajectory<T>, calculationRule: (fun(timestamp: number): T), timestamp: number): T
--- @field private record_entry_ function | # Form state object corresponding to the specific trace record entry
--- | fun(self: Trajectory<T>, entryIndex: integer): State<T>?
local Trajectory = class()

function Trajectory:_init(calculationRule, startingTimestamp, recordCapacity)
    self.calculationRule = tablex.deepcopy(calculationRule)

    self.traceRecord_ = {
        capacity = recordCapacity,
        entries  = {}
    }
    self.cache_ = {
        [self.calculationRule] = {}
    }

    self.currentTimestamp_ = startingTimestamp
    self.cache_[self.calculationRule][self.currentTimestamp_] = self.calculationRule(self.currentTimestamp_)

    if self.traceRecord_.capacity > 0 then
        table.insert(self.traceRecord_.entries, self.currentTimestamp_)
    end
end

function Trajectory:cache_entry_(calculationRule, timestamp)
    if self.cache_[calculationRule] == nil then
        self.cache_[calculationRule] = {}
    end
    if self.cache_[calculationRule][timestamp] == nil then
        self.cache_[calculationRule][timestamp] = self.calculationRule(timestamp)
    end

    return self.cache_[calculationRule][timestamp]
end

function Trajectory:current()
    --- @generic T: (number | Vector<number>)
    --- @type State<T> # Current state of the system
    local current = {
        timestamp = self.currentTimestamp_,
        position  = tablex.deepcopy(self:cache_entry_(self.calculationRule, self.currentTimestamp_))
    }

    return current
end

function Trajectory:record_entry_(entryIndex)
    if #self.traceRecord_.entries == 0 then
        return nil
    end

    -- Bring entry index to acceptable array boundaries 
    entryIndex = (entryIndex + (#self.traceRecord_.entries - 1)) % #self.traceRecord_.entries + 1

    --- @generic T: (number | Vector<number>)
    --- @type State<T> # Entry state of the system
    local entry = {
        timestamp = self.traceRecord_.entries[entryIndex],
        position  = tablex.deepcopy(self:cache_entry_(self.calculationRule, self.traceRecord_.entries[entryIndex]))
    }

    return entry
end

function Trajectory:record()
    --- @generic T: (number | Vector<number>)
    --- @type State<T>[] # Array of recent states of the system
    local traceRecord = {}

    for entryIndex = 1, #self.traceRecord_.entries do
        table.insert(traceRecord, self:record_entry_(entryIndex))
    end

    return traceRecord
end

function Trajectory:clear(relevantTimestamp, recordCapacity)
    -- Clear trace record data and update trace record capacity if passed
    self.traceRecord_.entries = {}
    if recordCapacity ~= nil then
        self.traceRecord_.capacity = recordCapacity
    end

    -- Clear cache data
    self.cache_ = {
        [self.calculationRule] = {}
    }

    -- Update current timestamp if its' relevant value is passed
    if relevantTimestamp ~= nil then
        self.currentTimestamp_ = relevantTimestamp
    end

    if self.traceRecord_.capacity > 0 then
        table.insert(self.traceRecord_.entries, self.currentTimestamp_)
    end
end

function Trajectory:calculate(deltaTime)
    -- Update current timestamp and add value to the trace record
    self.currentTimestamp_ = self.currentTimestamp_ + deltaTime
    table.insert(self.traceRecord_.entries, self.currentTimestamp_)
    while #self.traceRecord_.entries > self.traceRecord_.capacity do
        table.remove(self.traceRecord_.entries, 1)
    end

    --- @generic T: (number | Vector<number>)
    --- @type State<T> # Current state of the system
    local current = {
        timestamp = self.currentTimestamp_,
        position  = tablex.deepcopy(self:cache_entry_(self.calculationRule, self.currentTimestamp_))
    }

    -- Return calculated state
    return current
end

return Trajectory
