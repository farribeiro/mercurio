
-- giant baby

local giant_baby = function(pos, player)

	local self = minetest.add_entity(pos, "mobs_npc:npc"):get_luaentity()

	if self then

		self.nametag = "Big Baby" ; self.hp_max = 150 ; self.health = 150
		self.light_damage = 0 ; self.water_damage = 0 ; self.jump = false
		self.reach = 7 ; self.sounds = {damage = "mobs_punch", random = "fart1"}

		self.drops = {
			{name = "mobs:meat_raw", chance = 1, min = 5, max = 15},
			{name = "mobs:meat_raw", chance = 1, min = 5, max = 15}
		}

		if core.get_modpath("wool") then
			table.insert(self.drops, {name = "wool:white", chance = 1, min = 1, max = 5})
		end

		mobs:scale_mob(self, 5, 5)

		self.object:set_properties({
			nametag = self.nametag, hp_max = 150, textures = {"mobs_npc_baby.png"}
		})

		pos.y = pos.y + 5 ; self.object:set_pos(pos)
	end
end

-- add lucky blocks

lucky_block:add_blocks({
	{"spw", "mobs_npc:npc", 1, true, true},
	{"spw", "mobs_npc:igor", 1, true, true, 5, "Igor"},
	{"spw", "mobs_npc:trader", 1, false, false},
	{"lig", "fire:permanent_flame"},
	{"cus", giant_baby}
})
