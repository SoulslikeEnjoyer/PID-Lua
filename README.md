# PID-Controller

## Overview

PID-Controller implemented in Lua, supporting such features as:

- On fly modification of the controller terms' gains (Kp, Ki, Kd);
- Weighted calculation of the Proportional term (Proportional on Error (PonE) and Proportional on Measurement (PonM) approaches mixed);
- "Derivative Kick" prevention mechanism (Derivative on Measurement (DonM) calculation approach);
- Regulation of multidimensional values;
- etc.

## Installation

Installation via [LuaRocks](https://luarocks.org):

```shell
luarocks install pid-controller
```

## Usage

You can see full PID class interface in the source code of the [PID](module/PID.lua) module in the [LuaLS](https://luals.github.io) documentation block.

## Examples

For usage examples, please, see [example](example) directory, containing [Trajectory](example/module/Trajectory.lua), [Path](example/module/Path.lua) modules and [StepResponse.lua](example/script/StepResponse.lua), [MultidimRegulation.lua](example/script/MultidimRegulation.lua) scripts, which implement movement of an inertial body along precalculated trajectory, using several differently tuned PID-Controllers.

To run example scripts, run following commands from the root of the project tree:

```shell
lua -l deps example/script/StepResonse.lua
```

or

```shell
lua -l deps example/script/MultidimRegulation.lua
```

Resulting plots will appear in the `out` directory.

## Demostration

### Step response

![StepResponse](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/StepResponse.png)

### Regulation of multidimensional value

![MultidimRegulation](https://raw.githubusercontent.com/SoulslikeEnjoyer/PID-Lua/refs/heads/dev/.github/images/MultidimRegulation.png)

## Dependencies

[PID](module/PID.lua) module requires [Penlight](https://github.com/lunarmodules/Penlight) package installed ([e.g. via LuaRocks](https://luarocks.org/modules/tieske/penlight)) and available and utilises [pl.class](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/class.lua) and [pl.tablex](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/tablex.lua) modules.

Example modules rely on the same modules of the Penlight package as the [PID](module/PID.lua) module. Example scripts utilise [pl.dir](https://github.com/lunarmodules/Penlight/blob/master/lua/pl/dir.lua) module for the output directory creation.

Usage examples also require [plotly](https://github.com/kenloen/plotly.lua) package installed ([e.g. via LuaRocks](https://luarocks.org/modules/kenloen/plotly)) and available as a dependency and an internet connection to render the plots.

## Contribution

Any helpful PRs are highly appreciated =)
