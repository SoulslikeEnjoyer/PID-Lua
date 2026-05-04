# PID-Controller

## Overview

PID-Controller implemented in Lua, supporting such features as:

- On fly modification of the controller terms' gains (Kp, Ki, Kd);
- Weighted Proportional term calculation (on Error and on Measurement approaches mixed);
- "Derivative Kick" prevention mechanism (Derivative on Measurement calculation approach);
- Multidimensional values regulation;
- etc.

## Usage

You can see full PID-Controller class interface in the [PID.lua](module/PID.lua) module in the [LuaLS](https://luals.github.io) documentation block.

## Examples

For usage examples, please, see [example](example) folder, containing [Trajectory.lua](example/module/Trajectory.lua), [Path.lua](example/module/Path.lua) modules and [StepResponse.lua](example/script/StepResponse.lua), [SpiralMovement.lua](example/script/SpiralMovement.lua) scripts, which implement movement of an inertial body along precalculated trajectory, using several differently tuned PID-Controllers.

To run example scripts, run following commands from the root of the project tree:
`lua -l deps example/script/StepResonse.lua`
or
`lua -l deps example/script/SpiralMovement.lua`

Resulting plots will appear in the "out" folder.

## Demostration

### Step response

![PonEFull](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(3).png) ![PonEPartial](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(4).png)
![PonMFull](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(5).png) ![PonMPartial](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(6).png)
![wobblyFull](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(7).png) ![wobblyPartial](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(8).png)
![bouncyFull](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(9).png) ![bouncyPartial](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(10).png)
![stepLikeFull](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(11).png) ![stepLikePartial](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(12).png)

### Spiral movement

![PonE](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(13).png) ![PonM](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(14).png)
![50/50](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/newplot(15).png)

## Dependencies

[PID.lua](module/PID.lua) module requires [Penlight](https://github.com/lunarmodules/Penlight) package installed and available and utilises [pl.class](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/class.lua) and [pl.tablex](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/tablex.lua) modules.

Example modules also rely on the same modules of the Penlight package. Example scripts utilise [pl.dir](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/dir.lua) module for the output directory creation.

Usage examples also require [plotly](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/dir.lua) package installed as a dependency and an internet connection to render the plots:
