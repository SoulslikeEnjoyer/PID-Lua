-- Cross-platform LuaRocks module path configuration

local version = _VERSION:match("%d+%.%d+")
if version == "" then return end

local  path = {}
local cpath = {}

--- Project-local Module Paths ---
table.insert( path, "lua_modules/share/lua/" .. version .. "/?.lua"     )
table.insert( path, "lua_modules/share/lua/" .. version .. "/?/init.lua")
table.insert(cpath, "lua_modules/lib/lua/" .. version .. "/?.so" )
table.insert(cpath, "lua_modules/lib/lua/" .. version .. "/?.dll")

--- LuaRocks Paths ---
table.insert( path, ".luarocks/share/lua/" .. version .. "/?.lua"     )
table.insert( path, ".luarocks/share/lua/" .. version .. "/?/init.lua")
table.insert(cpath, ".luarocks/lib/lua/" .. version .. "/?.so" )
table.insert(cpath, ".luarocks/lib/lua/" .. version .. "/?.dll")

--- User Local LuaRocks Paths ---
local home = os.getenv("HOME")
if home then
    table.insert( path, home .. ".luarocks/share/lua/" .. version .. "/?.lua"     )
    table.insert( path, home .. ".luarocks/share/lua/" .. version .. "/?/init.lua")
    table.insert(cpath, home .. ".luarocks/lib/lua/" .. version .. "/?.so" )
    table.insert(cpath, home .. ".luarocks/lib/lua/" .. version .. "/?.dll")
end

--- MSYS Environments Support (Windows) ---
local msys = os.getenv("MSYSTEM")
if msys then
    table.insert( path, '/' .. msys .. "/local/share/lua/" .. version .. "/?.lua"     )
    table.insert( path, '/' .. msys .. "/local/share/lua/" .. version .. "/?/init.lua")
    table.insert( path, '/' .. msys .. "/share/lua/"       .. version .. "/?.lua"     )
    table.insert( path, '/' .. msys .. "/share/lua/"       .. version .. "/?/init.lua")
    table.insert(cpath, '/' .. msys .. "/local/lib/lua/" .. version .. "/?.so" )
    table.insert(cpath, '/' .. msys .. "/local/lib/lua/" .. version .. "/?.dll")
    table.insert(cpath, '/' .. msys .. "/lib/lua/"       .. version .. "/?.so" )
    table.insert(cpath, '/' .. msys .. "/lib/lua/"       .. version .. "/?.dll")
end

--- System Paths (Unix-like) ---
table.insert( path, "/usr/local/share/lua/" .. version .. "/?.lua"     )
table.insert( path, "/usr/local/share/lua/" .. version .. "/?/init.lua")
table.insert( path, "/usr/share/lua/"       .. version .. "/?.lua"     )
table.insert( path, "/usr/share/lua/"       .. version .. "/?/init.lua")
table.insert(cpath, "/usr/local/lib/lua/" .. version .. "/?.so" )
table.insert(cpath, "/usr/local/lib/lua/" .. version .. "/?.dll")
table.insert(cpath, "/usr/lib/lua/"       .. version .. "/?.so" )
table.insert(cpath, "/usr/lib/lua/"       .. version .. "/?.dll")

--- Prepending existing paths ---
package.path  = table.concat( path, ';') .. ';' .. package.path
package.cpath = table.concat(cpath, ';') .. ';' .. package.cpath
