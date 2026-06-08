local modpath = core.get_modpath("currency")

core.log("info", "Currency mod loading...")

currency = {}
if core.global_exists("default") then
	currency.node_sound_wood_defaults = default.node_sound_wood_defaults
else
	currency.node_sound_wood_defaults = function() end
end

dofile(modpath.."/craftitems.lua")
core.log("info", "[Currency] Craft_items Loaded!")
dofile(modpath.."/shop.lua")
core.log("info", "[Currency] Shop Loaded!")
dofile(modpath.."/barter.lua")
core.log("info", "[Currency] Barter Loaded!")
dofile(modpath.."/safe.lua")
core.log("info", "[Currency] Safe Loaded!")
dofile(modpath.."/crafting.lua")
core.log("info", "[Currency] Crafting Loaded!")

if core.settings:get_bool("creative_mode") then
	core.log("info", "[Currency] Creative mode in use, skipping basic income.")
else
	dofile(modpath.."/income.lua")
	core.log("info", "[Currency] Income Loaded!")
end
