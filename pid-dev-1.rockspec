-- TODO: move configs into JSON file and generate rockspec on the fly

rockspec_format = "3.0"

local project  = { package = "PID", version = "dev" }
local rockspec = { revision = 1 }
local git = {
    user   = "SoulslikeEnjoyer",
    repo   = project.package .. "-Lua",
    branch = project.version == "dev" and "main" or project.version -- TODO: what happens here?.. i dunno
}

package = project.package
version = project.version .. "-" .. rockspec.revision

source = {
    url = "git+https://github.com/" .. git.user .. '/' .. git.repo .. ".git",
    branch = git.branch
}

description = {
    summary = "PID controller implemented in Lua",
    detailed = [[
        Two versions of PID controller implemented. Standard and modified.
        To use standard or modified version require "PID.std" or "PID.mod" modules respectively.
    ]],
    license = "GPL-3",
    homepage = "https://github.com/" .. git.user .. '/' .. git.repo,
    issues_url = "https://github.com/" .. git.user .. '/' .. git.repo .. "/issues",
}

dependencies = {
    "lua >= 5.1",
    "penlight"
}

build = {
    type = "builtin",
    modules = {
        ["PID.std"] = "module/PID/Standard.lua",
    }
}
