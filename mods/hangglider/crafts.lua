local S = hangglider.translator
local colors = assert(dofile(core.get_modpath("hangglider").."/colors.lua"))

local repair_items      = {"group:wool", xcompat.materials.paper}
local repair_percentage = 100


-- Placeholder repairing recipes (Doesn't directly apply repair, see handler)
core.register_craft({
	output = "hangglider:hangglider",
	recipe = {
		{xcompat.materials.paper, xcompat.materials.paper, xcompat.materials.paper},
		{xcompat.materials.paper, "hangglider:hangglider", xcompat.materials.paper},
		{xcompat.materials.paper, xcompat.materials.paper, xcompat.materials.paper},
	},
})

core.register_craft({
	output = "hangglider:hangglider",
	recipe = {"hangglider:hangglider", "group:wool"},
	type = "shapeless",
})

-- Placeholder color recipe (Doesn't drectly apply color, see handler)
do
	local item = ItemStack("hangglider:hangglider")
	item:get_meta():set_string("description", S("Colored Glider"))
	core.register_craft({
		output = item:to_string(),
		recipe = {"hangglider:hangglider", "group:dye"},
		type = "shapeless",
	})
end

-- Recipe handler (This is what applies color and repair)
local function crafting_callback_handle_placeholder_recipe(crafted_item, _, old_craft_grid)
	if crafted_item:get_name() ~= "hangglider:hangglider" then
		-- Function called for an unrelated crafting recipe
		return
	end
	-- Get existing state and present materials
	local wear, repaired, dye_name, color, color_name = 0, false, nil, nil, nil
	for _,stack in ipairs(old_craft_grid) do
		local name = stack:get_name()
		if not name or name == "" then
			do end -- The stack is empty, do nothing and skip all checks for this stack.
		elseif name == "hangglider:hangglider" then
			wear       = stack:get_wear()
			color      = stack:get_meta():get("hangglider_color")
			color_name = colors.get_color_name_from_color(color)
		elseif core.get_item_group(name, "dye") ~= 0 then
			dye_name = name
		else
			for _,repair_item in ipairs(repair_items) do
				if name == repair_item
					or core.get_item_group(name, string.match(repair_item, "^group:(.*)$")) ~= 0
				then
					repaired = true
				end
			end
		end
	end

	-- Overwrite color with dye if present
	if dye_name then
		color      = colors.get_dye_color(dye_name)
		color_name = colors.get_color_name(dye_name)
	end

	-- Repair if any repair item present
	if repaired then
		wear = wear - (65535 * (repair_percentage / 100))
		if wear < 0 then wear = 0 end
	end

	-- Apply item changes if valid
	if wear and color and color_name then
		if color == "ffffff" then
			-- Return an uncolored glider
			return ItemStack({name = "hangglider:hangglider", wear = wear})
		end
		local meta = crafted_item:get_meta()
		meta:set_string("description", S("@1 Glider", color_name))
		meta:set_string("inventory_image", "hangglider_item.png^(hangglider_color.png^[multiply:#"..color..")")
		meta:set_string("hangglider_color", color)
		crafted_item:set_wear(wear)
		return crafted_item
	end
end
-- Register handler as a callback for any crafting action
core.register_on_craft(crafting_callback_handle_placeholder_recipe)


-- Hangglider recipe
core.register_craft({
	output = "hangglider:hangglider",
	recipe = {
		{"group:wool", "group:wool", "group:wool"},
		{xcompat.materials.stick, "", xcompat.materials.stick},
		{"", xcompat.materials.stick, ""},
	}
})
