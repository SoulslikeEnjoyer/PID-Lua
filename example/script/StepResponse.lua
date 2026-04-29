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
        position = 0
    }
    local movementTime = 10.000 -- 10 seconds
    local    deltaTime =  0.001 -- 1 millisecond
    -- local    deltaTime =  0.500 -- half a second (instability)

    -- Object of the study - PID controller
    --- @type PID<number>
    -- local controller = PID(2.5, 0, 2.75) -- ideal on error
    -- local controller = PID(4.75, 2.5, 2.75, 1) -- ideal on measure
    local controller = PID(7.25, 2.5, 1.25, 0.5) -- bouncy
    -- local controller = PID(16.25, 8.25, 1.5, 0.95) -- step-like

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
        -- Update total time passed
        totalTime = totalTime + deltaTime
    end

    -- Prepare trajectory trace record data for plotting (convert array of tables into table of arrays)
    local trajectoryRecord = trajectory:record()
    --- @type { timestamps: number[], positions: number[] }
    local trajectoryPlotData = {
        timestamps = {},
        positions  = {}
    }
    for index = 1, #trajectoryRecord do
        table.insert(trajectoryPlotData.timestamps, trajectoryRecord[index].timestamp)
        table.insert(trajectoryPlotData.positions , trajectoryRecord[index].position )
    end

    -- Prepare path trace record data for plotting (convert array of tables into table of arrays)
    local pathRecord = path:record()
    --- @type { timestamps: number[], positions: number[] }
    local pathPlotData = {
        timestamps    = {},
        positions     = {},
        velocities    = {},
        accelerations = {}
    }
    for index = 1, #pathRecord do
        table.insert(pathPlotData.timestamps   , pathRecord[index].timestamp   )
        table.insert(pathPlotData.positions    , pathRecord[index].position    )
        table.insert(pathPlotData.velocities   , pathRecord[index].velocity    )
        table.insert(pathPlotData.accelerations, pathRecord[index].acceleration)
    end

    -- Plot experiment results: calculated trajectory and actual path traveled
    local figure = plotly.figure()
    figure:plot({ title="Calculated trajectory and actual path traveled", xlabel="Time", ylabel="Coordinate" })
    figure:plot({ x=trajectoryPlotData.timestamps, y=trajectoryPlotData.positions, mode="l", name="Trajectory" })
    figure:plot({ x=pathPlotData.timestamps, y=pathPlotData.positions    , mode="l", name="Path" })
    figure:plot({ x=pathPlotData.timestamps, y=pathPlotData.velocities   , mode="l", name="Velocity" })
    figure:plot({ x=pathPlotData.timestamps, y=pathPlotData.accelerations, mode="l", line={ shape='hv' }, name="Acceleration" }) -- uniformly accelerated motion
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
