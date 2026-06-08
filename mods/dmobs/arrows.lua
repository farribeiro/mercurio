
-- Fire arrow

local fire_def = {
	visual = "sprite",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"dmobs_fire.png"},
	velocity = 8,
	tail = 1, -- enable tail
	tail_texture = "fire_basic_flame.png",
	glow = 10,

	hit_player = function(self, player)

		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 8}
		}, nil)
	end,

	hit_mob = function(self, player)

		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 8}
		}, nil)
	end,

	hit_node = function(self, pos, node)
		self.object:remove()
	end
}

-- if destructive mode active then replace hit_node with something more explosive :)
if dmobs.destructive == true then

	fire_def.hit_node = function(self, pos, node)
		mobs:explosion(pos, 2, 1, 1)
	end
end

mobs:register_arrow("dmobs:fire", fire_def)

-- Dragon arrows

local base_arrow = {
	visual = "sprite",
	visual_size = {x = 0.5, y = 0.5},
	velocity = 8,
	textures = {},
	tail = 1, -- enable tail
	tail_texture = "dmobs_ice.png",

	hit_player = function(self, player)

		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 8}
		}, nil)
	end,

	hit_mob = function(self, player)

		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 8}
		}, nil)
	end,

	hit_node = function(self, pos, node)
		self.object:remove()
	end
}

for _,arrowtype in pairs({"ice", "lightning", "poison"}) do

	base_arrow.textures = {"dmobs_" .. arrowtype .. ".png"}

	mobs:register_arrow("dmobs:" .. arrowtype, dmobs.deepclone(base_arrow))
end

-- Sting

mobs:register_arrow("dmobs:sting", {
	visual = "sprite",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"dmobs_sting.png"},
	velocity = 8,
	tail = 0, -- enable tail
	tail_texture = "fire_basic_flame.png",

	hit_player = function(self, player)

		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 1}
		}, nil)
	end,

	hit_mob = function(self, player)
	end,

	hit_node = function(self, pos, node)
		self.object:remove()
	end
})

-- Dragonfire arrows

-- function to register tamed dragon attacks
function dmobs.register_fire(
		fname, texture, dmg, replace_node, explode, ice, variance, size)

	core.register_entity(fname, {

		initial_properties = {
			textures = {texture},
			collisionbox = {0.2, 0.2, 0.2, 0.2, 0.2, 0.2}
		},

		velocity = 0.1,
		damage = dmg,

		on_step = function(self, dtime)

			local remove = core.after(2, function()
				self.object:remove()
			end)

			local pos = self.object:get_pos()
			local objs = core.get_objects_inside_radius(pos, 2)

			for k, obj in pairs(objs) do

				local ent = obj:get_luaentity()

				if ent then

					if ent.name ~= fname
					and ent.name ~= "dmobs:dragon_red"
					and ent.name ~= "dmobs:dragon_blue"
					and ent.name ~= "dmobs:dragon_black"
					and ent.name ~= "dmobs:dragon_green"
					and ent.name ~= "dmobs:dragon_great_tame"
					and ent.name ~= "__builtin:item" then

						obj:punch(self.object, 1.0, {
							full_punch_interval = 1.0,
							damage_groups={fleshy = 8}
						}, nil)

						self.object:remove() ; return
					end
				end
			end

			for dx = 0, 1 do
				for dy = 0, 1 do
					for dz = 0, 1 do

						local p = {x = pos.x + dx, y = pos.y, z = pos.z + dz}
						local t = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
						local n = core.get_node(p).name
						local nd = core.registered_nodes[n]

						if n ~= fname and n ~="default:dirt_with_grass"
						and n ~="default:dirt_with_dry_grass"
						and n ~="default:stone" then

							if ice and n == "default:water_source" then
								core.set_node(t, {name = "default:ice"})
								self.object:remove() ; return
							end

							if nd and nd.groups.flammable then

								core.set_node(t, {name = replace_node})
								self.object:remove() ; return
							end
						end
					end
				end
			end

			core.add_particlespawner({
				amount = 6,
				time = 0.3,
				minpos = {x = pos.x - variance, y = pos.y - variance, z = pos.z - variance},
				maxpos = {x = pos.x + variance, y = pos.y + variance, z = pos.z + variance},
				minvel = {x = -0, y = -0, z = -0},
				maxvel = {x = 0, y = 0, z = 0},
				minacc = {x = variance, y = -0.5 - variance, z = variance},
				maxacc = {x = 0.5 + variance, y = 0.5 + variance, z = 0.5 + variance},
				minexptime = 0.1,
				maxexptime = 0.3,
				minsize = size,
				maxsize = size + 2,
				collisiondetection = false,
				texture = texture
			})
		end
	})
end


dmobs.register_fire("dmobs:fire_plyr", "dmobs_fire.png", 2,
		"fire:basic_flame", true, false, 0.3, 1)

dmobs.register_fire("dmobs:ice_plyr", "dmobs_ice.png", 2,
		"default:ice", false, true, 0.5, 10)

dmobs.register_fire("dmobs:poison_plyr", "dmobs_poison.png", 2,
		"air", false, false, 0.3, 1)

dmobs.register_fire("dmobs:lightning_plyr", "dmobs_lightning.png", 2,
		"air", true, false, 0, 0.5)
