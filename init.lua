optional_depends = {}

local path = core.get_modpath "optional_depends"
local S = core.get_translator "optional_depends"

optional_depends.get_modpath = path
optional_depends.get_translator = S

dofile (path .. "/functions.lua")