-- translation and mod support check

local S = core.get_translator("bakedclay")
local mod_flowerpot = core.get_modpath("flowerpot")

-- helper function

local function add_flower(name, desc, f_groups)

	f_groups.snappy = 3
	f_groups.flower = 1
	f_groups.flora = 1
	f_groups.attached_node = 1

	core.register_node("bakedclay:" .. name, {
		description = desc,
		drawtype = "plantlike",
		waving = 1,
		tiles = {"baked_clay_" .. name .. ".png"},
		inventory_image = "baked_clay_" .. name .. ".png",
		wield_image = "baked_clay_" .. name .. ".png",
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		groups = f_groups,
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {type = "fixed", fixed = {-0.15, -0.5, -0.15, 0.15, 0.3, 0.15}}
	})

	if mod_flowerpot then
		flowerpot.register_node("bakedclay:" .. name)
	end
end

-- register new flowers to fill in missing dye colours

add_flower("delphinium", S("Blue Delphinium"), {color_cyan = 1})
add_flower("thistle", S("Thistle"), {color_magenta = 1})
add_flower("lazarus", S("Lazarus Bell"), {color_pink = 1})
add_flower("mannagrass", S("Reed Mannagrass"), {color_dark_green = 1})

-- add new flowers to mapgen

core.register_decoration({
	deco_type = "simple",
	place_on = {"default:dirt_with_grass"},
	sidelen = 16,
	noise_params = {
		offset = 0,
		scale = 0.004,
		spread = {x = 100, y = 100, z = 100},
		seed = 7133,
		octaves = 3,
		persist = 0.6
	},
	y_min = 10, y_max = 90,
	decoration = "bakedclay:delphinium"
})

core.register_decoration({
	deco_type = "simple",
	place_on = {"default:dirt_with_grass", "default:dirt_with_dry_grass"},
	sidelen = 16,
	noise_params = {
		offset = 0,
		scale = 0.004,
		spread = {x = 100, y = 100, z = 100},
		seed = 7134,
		octaves = 3,
		persist = 0.6
	},
	y_min = 15, y_max = 90,
	decoration = "bakedclay:thistle"
})

core.register_decoration({
	deco_type = "simple",
	place_on = {"default:dirt_with_grass", "default:dirt_with_rainforest_litter"},
	sidelen = 16,
	noise_params = {
		offset = 0,
		scale = 0.01,
		spread = {x = 100, y = 100, z = 100},
		seed = 7135,
		octaves = 3,
		persist = 0.6
	},
	y_min = 1, y_max = 90,
	decoration = "bakedclay:lazarus",
	spawn_by = "default:jungletree", num_spawn_by = 1
})

core.register_decoration({
	deco_type = "simple",
	place_on = {"default:dirt_with_grass", "default:sand"},
	sidelen = 16,
	noise_params = {
		offset = 0,
		scale = 0.009,
		spread = {x = 100, y = 100, z = 100},
		seed = 7136,
		octaves = 3,
		persist = 0.6
	},
	y_min = 1, y_max = 15,
	decoration = "bakedclay:mannagrass",
	spawn_by = "group:water", num_spawn_by = 1
})
