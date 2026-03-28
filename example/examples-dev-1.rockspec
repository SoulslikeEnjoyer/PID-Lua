-- TODO: move configs into JSON file and generate rockspec on the fly

rockspec_format = "3.0"

local project  = { package = "Examples", version = "dev" }
local rockspec = { revision = 1 }
local git = {
    user   = "SoulslikeEnjoyer",
    repo   = "PID",
    branch = project.version == "dev" and "master" or project.version -- TODO: what happens here?.. i dunno
}

package = project.package
version = project.version .. "-" .. rockspec.revision

source = {
    url = "git+https://github.com/" .. git.user .. '/' .. git.repo .. ".git",
    branch = git.branch,
    dir = "example"
}

description = {
    summary = "PID controller usage examples",
    detailed = [[
        Examples including two versions of PID controllers implemented. Standard and modified.
        Step response example and spiral movement example.
        To run example scripts, run following commands, from the root of the project:
        "lua -l deps example/script/StepResonse.lua" or "lua -l deps example/script/SpiralMovement.lua"
    ]],
    license = "GPL-3",
}

dependencies = {
    "plotly"
}

build = {
    type = "none",
}
