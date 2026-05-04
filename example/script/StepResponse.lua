-- Path configuration for local modules ("Trajectory" and "Path" modules)
package.path  = "example/module/?.lua;" .. package.path

-- Components
local dir    = require("pl.dir")
local plotly = require("plotly")

-- Local components
local PID        = require("PID")
local Trajectory = require("Trajectory")
local Path       = require("Path")

-- Auxiliary type definitions
--- @class Vector<T>: { [(integer | string)]: T } # Vector value type

-- Trajectory function
--- @type fun(t: number): number
local function Heaviside(t)
    if t >= 0 then
        return 1
    end
    return 0
end

--- Test run function
--- @param controller PID<number>
--- @return table plotly.figure
local function run(controller)
    --- @type string # Title of the test run, describing PID-Controller configuration
    local testTitle = "PID(" ..
            "Kp="   .. controller.term.proportional.gain .. ", " ..
            "Ki="   .. controller.term.integral.gain     .. ", " ..
            "Kd="   .. controller.term.derivative.gain   .. ", " ..
            "PonM=" .. controller.term.proportional.on.measurement.weight() * 100 .. "%" ..
        ")"

    -- Test configuration
    --- @generic T: (number | Vector<number>)
    --- @class State<T>: {
    ---     timestamp: number,
    ---     position: T,
    --- } # State value type
    --- @type State<number>
    local starting = {
        timestamp = 0,
        position = 0
    }
    local movementTime = 10.000 -- 10 seconds
    local    deltaTime =  0.001 -- 1 millisecond

    -- Secondary structures
    --- @type integer
    local recordCapacity = 1e6
    --- @type Trajectory<number>
    local trajectory = Trajectory(Heaviside, starting.timestamp, recordCapacity)
    --- @type Path<number>
    local path = Path(controller, starting, recordCapacity)

    io.write("Started " .. testTitle .. "... ")

    -- Follow the trajectory and record actual path traveled
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
    --- @type {
    ---     timestamps: number[],
    ---     positions: number[],
    --- }
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
    --- @type {
    ---     timestamps: number[],
    ---     positions: number[],
    ---     velocities: number[],
    ---     accelerations: number[],
    --- }
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

    -- Plot test run results: calculated trajectory and actual path traveled
    local figure = plotly.figure()
    figure:plot({ title=testTitle, xlabel="Time", ylabel="Coordinate" })
    figure:plot({ x=trajectoryPlotData.timestamps, y=trajectoryPlotData.positions, mode="l", name="Trajectory" })
    figure:plot({ x=pathPlotData.timestamps, y=pathPlotData.positions    , mode="l", name="Path" })
    figure:plot({ x=pathPlotData.timestamps, y=pathPlotData.velocities   , mode="l", name="Velocity" })
    figure:plot({ x=pathPlotData.timestamps, y=pathPlotData.accelerations, mode="l", line={ shape='hv' }, name="Acceleration" }) -- uniformly accelerated motion
    figure:update_config({ scrollZoom = true })

    io.write("Finished\n")

    -- Return plot figure
    return figure
end

local function main(...)
    --- @type table[] # List of figures to be plotted
    local figures = {}

    -- Series of test runs with differently tuned controllers
    table.insert(figures, run(PID( 2.25, 0.00, 2.75      ))) -- Correctly tuned PID-Controller (PonE)
    table.insert(figures, run(PID( 4.75, 2.50, 2.75, 1.00))) -- Correctly tuned PID-Controller (PonM)
    -- other interesting controller behaviours
    table.insert(figures, run(PID( 5.00, 2.50, 1.75, 0.25)))
    table.insert(figures, run(PID( 7.25, 2.50, 1.25, 0.50)))
    table.insert(figures, run(PID(16.25, 8.25, 1.50, 1.00)))

    -- Save plot
    io.write("Writing plot data to file... ")
    local output_dir = "out"
    dir.makepath(output_dir)
    plotly.tofile(output_dir .. '/' .. "StepResponse.html", figures)
    io.write("Finished\n")

    return 0
end
if not debug.getinfo(3) then
    main(table.unpack(arg))
end
