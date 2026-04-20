# TODO List

- [x] Check wether P term weighting works correctly now
- [x] Rename PID.std to just PID and forget about PID.mod
- [x] Equality function to PID.lua module
- [x] Rewrite Trajectory
- [ ] Think about whether passing a current table to Trajectory methods is a good idea (since position effectively depends on timestamp):
  - [ ] I thought of _cache storage with the following layout { [timestamp]: { [rule]: position } } and position in current and record are just accessor function
- [ ] Rewrite Path:
  - [x] Class documentation
  - [ ] Finish
- [ ] So, apparently, I don't even need coroutines (peepoSad):
  - [ ] Try to hide accumulators inside coroutine of a PID-Controller
- [ ] Change Trajectory and Path records to store "{...}[]":
  - [ ] Trajectory
  - [ ] Path
- [ ] Try to rewrite StepResponse example to draw 4 graphs in one go
- [ ] Add vector PID-Controller implementation
- [ ] If it is possible to draw multiple plots in one script call, then change SpiralMovement also
