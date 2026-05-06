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
--- @type fun(t: number): Vector<number>
local function spiral(t)
    local coords = { x = t * math.cos(t), y = t * math.sin(t) }
    return coords
end

--- Test run function
--- @param controller PID<Vector<number>>
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
    --- @type State<Vector<number>>
    local starting = {
        timestamp = 0,
        position = { x=0, y=0 }
    }
    local movementTime = 10.000 -- 10 seconds
    local    deltaTime =  0.001 -- 1 millisecond

    -- Secondary structures
    --- @type integer
    local recordCapacity = 1e6
    --- @type Trajectory<Vector<number>>
    local trajectory = Trajectory(spiral, starting.timestamp, recordCapacity)
    --- @type Path<Vector<number>>
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
    ---     positions: { x: number[], y: number[] },
    --- }
    local trajectoryPlotData = {
        timestamps = {},
        positions  = { x = {}, y = {} }
    }
    for index = 1, #trajectoryRecord do
        table.insert(trajectoryPlotData.timestamps, trajectoryRecord[index].timestamp)

        table.insert(trajectoryPlotData.positions.x, trajectoryRecord[index].position.x)
        table.insert(trajectoryPlotData.positions.y, trajectoryRecord[index].position.y)
    end

    -- Prepare path trace record data for plotting (convert array of tables into table of arrays)
    local pathRecord = path:record()
    --- @type {
    ---     timestamps: number[],
    ---     positions: { x: number[], y: number[] },
    ---     velocities: { x: number[], y: number[] },
    ---     accelerations: { x: number[], y: number[] },
    --- }
    local pathPlotData = {
        timestamps    = {},
        positions  = { x = {}, y = {} },
        velocities    = { x = {}, y = {} },
        accelerations = { x = {}, y = {} }
    }
    for index = 1, #pathRecord do
        table.insert(pathPlotData.timestamps, pathRecord[index].timestamp)

        table.insert(pathPlotData.positions.x, pathRecord[index].position.x)
        table.insert(pathPlotData.positions.y, pathRecord[index].position.y)

        table.insert(pathPlotData.velocities.x, pathRecord[index].velocity.x)
        table.insert(pathPlotData.velocities.y, pathRecord[index].velocity.y)

        table.insert(pathPlotData.accelerations.x, pathRecord[index].acceleration.x)
        table.insert(pathPlotData.accelerations.y, pathRecord[index].acceleration.y)
    end

    -- Plot test run results: calculated trajectory and actual path traveled
    local figure = plotly.figure()
    figure:plot({ title=testTitle, xlabel="X Coordinate", ylabel="Y Coordinate" })
    figure:plot({ x=trajectoryPlotData.positions.x, y=trajectoryPlotData.positions.y, mode="l", name="Trajectory" })
    figure:plot({ x=pathPlotData.positions.x, y=pathPlotData.positions.y, mode="l", name="Path" })
    figure:update_config({ scrollZoom = true })

    io.write("Finished\n")

    -- Return plot figure
    return figure
end

local function main(...)
    --- @type table[] # List of figures to be plotted
    local figures = {}

    -- Series of test runs with differently tuned controllers
    table.insert(figures, run(PID(8.75, 0.75, 4.50      ))) -- Correctly tuned PID-Controller (PonE)
    table.insert(figures, run(PID(7.50, 8.75, 2.50, 1.00))) -- Correctly tuned PID-Controller (PonM)
    table.insert(figures, run(PID(7.25, 6.50, 2.25, 0.50))) -- Correctly tuned PID-Controller (50% PonE / 50% PonM)

    -- Save plot
    io.write("Writing plot data to file... ")
    local output_dir = "out"
    dir.makepath(output_dir)
    plotly.tofile(output_dir .. '/' .. "SpiralMovement.html", figures)
    io.write("Finished\n")

    return 0
end
if not debug.getinfo(3) then
    main(table.unpack(arg))
end
