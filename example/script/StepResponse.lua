-- Path configuration for local modules ("Trajectory" and "Path" modules)
package.path  = "example/module/?.lua;" .. package.path

-- Components
local dir    = require("pl.dir")
local plotly = require("plotly")

-- Local components
local PID        = require("PID")
local Trajectory = require("Trajectory")
local Path       = require("Path")

-- Function to study controller's behaviour on - Heaviside step function
local function Heaviside(t)
    if t >= 0 then
        return 1
    end
    return 0
end

local function main(...)
    -- Experiment configuration
    local starting = {
        timestamp = 0,
        position  = 0,
        velocity  = 0
    }
    local movement_time = 10    -- 10 seconds
    local    delta_time = 0.001 -- 1 millisecond

    -- Object of the study - PID controller
    -- local controller = PID(2.5, 0, 2.75) -- ideal on error
    -- local controller = PID(7.5, 4.5, 1.25, 0.25)
    -- local controller = PID(7.25, 2.5, 1.25, 0.5)
    local controller = PID(4.75, 2.5, 2.75, 1) -- ideal on measure

    -- Auxiliary experiment structures
    local record_size = 1e6
    local trajectory = Trajectory(Heaviside, starting.timestamp, record_size)
    local path = Path(controller, starting, record_size)

    -- Conduct an experiment: follow the trajectory and record actual path traveled
    local total_time = 0
    while total_time < movement_time do
        -- Calculate next position in a trajectory
        local target = trajectory:calculate(delta_time)
        -- Move towards next position
        path:move(target, delta_time)
        -- or path:move(trajectory.current.position, delta_time)
        -- since trajectory and path classes keep trace records

        total_time = total_time + delta_time
    end

    -- Plot experiment results: calculated trajectory and actual path traveled
    local figure = plotly.figure()
    figure:plot({ title="Calculated trajectory and actual path traveled", xlabel="Time", ylabel="Coordinate" })
    figure:plot({ x=trajectory.record.timestamps, y=trajectory.record.positions, mode="l", name="Trajectory" })
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
