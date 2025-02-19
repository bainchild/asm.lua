
# asm.lua standard library

## Prelude
`include` includes a Lua file located in the path specified by `ss`. Equivalent
to `require(_R.ss)`. will set the syserr flag if it fails, and will set the ds register to the output if it is a string

writing to memory address 81921 will print what was wrote to it

`itoa` converts a number into a string.

`atoi` converts a string into a number (with optional argument <base> as `b`).

`memset` sets `c` cells in memory, starting from `b` to `a`.

`memcpy` copies `c` cells from `a` to `b`.

`memcmp` compares `c` cells at `a` and `b`.

## Math
`abs`
`mod`
`floor`
`round`
`ceil`
`min`
`max`

`sqrt`
`pow`
`exp`
`log`
`log10`

`deg`
`rad`
`sin`
`cos`
`tan`
`asin`
`acos`
`atan`
`atan2`

## String library
`strlen`
`strsub`
`strrep`
`strup`
`strlow`
`strfind`
`strmatch`

`ord`
`chr`

## OS calls

`system`
`exit`
`env`
`time`
