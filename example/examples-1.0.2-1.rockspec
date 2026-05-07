rockspec_format = "3.0"

local project  = { package = "Examples", version = "1.0.2" }
local rockspec = { revision = 1 }
local git = {
    user   = "SoulslikeEnjoyer",
    repo   = "PID-Lua",
    branch = project.version ~= "dev" and "main" or "dev", -- ternary construction
    tag    = project.version ~= "dev" and "v" .. project.version or nil
}

package = project.package
version = project.version .. "-" .. rockspec.revision

source = {
    url = "git+https://github.com/" .. git.user .. '/' .. git.repo .. ".git",
    branch = git.branch,
    tag = git.tag,
    dir = "example"
}

description = {
    summary = "PID-Controller usage examples",
    detailed = [[
        To run example scripts, run following commands from the root of the project tree:
        
            lua -l deps example/script/StepResonse.lua
        
        or

            lua -l deps example/script/MultidimRegulation.lua
        
        You will need "plotly" module installed and available as a dependency and an internet connection to render the plots:
        Run 
        
            luarocks install --only-deps example/examples-1.0.2-1.rockspec
        
        from the root of the project tree or run 

            luarocks install --server=https://luarocks.org/dev plotly
            
        to install "plotly" module manually (See: https://luarocks.org/modules/kenloen/plotly).
    ]],
    license = "GPL-3",
}

dependencies = {
    "plotly"
}

build = {
    type = "none",
}
