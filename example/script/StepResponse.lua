-- Path configuration for local modules ("Trajectory" and "Path" modules)
package.path  = "example/module/?.lua;" .. package.path

-- Components --
local dir = require("pl.dir")
local plotly = require("plotly")

-- Local components --
local PID = require("PID.std")
local Trajectory = require("Trajectory")
local Path = require("Path")

-- Function to study controller's behaviour on - Heaviside step function
local function Heaviside(t)
    if t > 0 then
        return 1
    end
    return 0
end

local function main(...)
    -- Experiment configuration
    local start_position = Heaviside(0)
    local total_time = 10    -- 10 seconds
    local delta_time = 0.001 -- 1 millisecond

    -- Object of the study - PID controller
    local controller = PID:new(1, 0, 0)

    -- Auxiliary experiment structures
    local record_size = 1e6
    local trajectory = Trajectory:new(Heaviside, record_size)
    local path = Path:new(controller, start_position, record_size)

    -- Conduct an experiment: follow the trajectory and record actual path traveled
    local movement_time = 0
    while movement_time < total_time do
        -- Calculate next position in a trajectory
        local _, next_position = coroutine.resume(trajectory:calculate(), delta_time)
        -- Move towards next position
        coroutine.resume(path:move(), next_position, delta_time)
        -- or "coroutine.resume(path:move(), trajectory.current.position, delta_time)"
        -- since Trajectory and Path classes keep trace records

        movement_time = movement_time + delta_time
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
