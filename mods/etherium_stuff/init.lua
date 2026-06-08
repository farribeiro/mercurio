etherium_stuff = {}

local modpath=core.get_modpath("etherium_stuff")

-- Intllib
local S
if core.global_exists("intllib") then
	if intllib.make_gettext_pair then
		-- New method using gettext.
		S = intllib.make_gettext_pair()
	else
		-- Old method using text files.
		S = intllib.Getter()
	end
else
	S = function(s) return s end
end
etherium_stuff.intllib = S

dofile(core.get_modpath("etherium_stuff").."/torch.lua")
dofile(core.get_modpath("etherium_stuff").."/crafting.lua")
dofile(core.get_modpath("etherium_stuff").."/water.lua")
dofile(core.get_modpath("etherium_stuff").."/nodes.lua")
dofile(core.get_modpath("etherium_stuff").."/stairs.lua")
dofile(core.get_modpath("etherium_stuff").."/lucky_block.lua")
