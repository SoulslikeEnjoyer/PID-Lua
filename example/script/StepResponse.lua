-- Path configuration for local modules ("Trajectory" and "Path" modules)
package.path  = "example/module/?.lua;" .. package.path

-- Components
local dir    = require("pl.dir")
local plotly = require("plotly")

-- Temporary components
local inspect = require("inspect")

-- Local components
local PID        = require("PID")
local Trajectory = require("Trajectory")
local Path       = require("Path")

-- Function to study controller's behaviour on - Heaviside step function
--- @type fun(t: number): number
local function Heaviside(t)
    if t >= 0 then
        return 1
    end
    return 0
end

local function main(...)
    -- Experiment configuration
    --- @type State<number>
    local starting = {
        timestamp = 0,
        position  = 0,
        velocity  = 0
    }
    local movementTime = 10.000 -- 10 seconds
    local    deltaTime =  0.001 -- 1 millisecond
    -- local    deltaTime =  0.500 -- half a second (instability)

    -- Object of the study - PID controller
    --- @type PID<number>
    -- local controller = PID(2.5, 0, 2.75) -- ideal on error
    -- local controller = PID(7.5, 4.5, 1.25, 0.25)
    local controller = PID(7.25, 2.5, 1.25, 0.5)
    -- local controller = PID(4.75, 2.5, 2.75, 1) -- ideal on measure

    -- Auxiliary experiment structures
    --- @type integer
    local recordCapacity = 1e6
    --- @type Trajectory<number>
    local trajectory = Trajectory(Heaviside, starting.timestamp, recordCapacity)
    --- @type Path<number>
    local path = Path(controller, starting, recordCapacity)

    -- Conduct an experiment: follow the trajectory and record actual path traveled
    --- @type number
    local totalTime = 0
    while totalTime < movementTime do
        -- Calculate next position in a trajectory
        local target = trajectory:calculate(deltaTime)
        -- Move towards next position
        path:move(target.position, deltaTime)
        -- or path:move(trajectory:current().position, deltaTime)

        totalTime = totalTime + deltaTime
    end

    -- Prepare data for plotting (convert array of tables into table of arrays)
    local trajectoryRecord = trajectory:record()
    --- @type { timestamps: number[], positions: number[] }
    local trajectoryTrace = {
        timestamps = {},
        positions  = {}
    }
    for index = 1, #trajectoryRecord do
        table.insert(trajectoryTrace.timestamps, trajectoryRecord[index].timestamp)
        table.insert(trajectoryTrace.positions, trajectoryRecord[index].position)
    end

    -- Plot experiment results: calculated trajectory and actual path traveled
    local figure = plotly.figure()
    figure:plot({ title="Calculated trajectory and actual path traveled", xlabel="Time", ylabel="Coordinate" })
    figure:plot({ x=trajectoryTrace.timestamps, y=trajectoryTrace.positions, mode="l", name="Trajectory" })
    figure:plot({ x=path.record.timestamps, y=path.record.positions, mode="l", name="Path" })
    figure:update_config({ scrollZoom = true })

    -- Save plot
    local output_dir = "out"
    dir.makepath(output_dir)
    figure:tofile(output_dir .. '/' .. "StepResponse.html")

    return 0
end
if not debug.getinfo(3) then
    main(table.unpack(arg))
end
