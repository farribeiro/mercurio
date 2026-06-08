
hangglider = {
	translator = core.get_translator('hangglider'),
}
local S = hangglider.translator

local has_player_monoids = core.get_modpath("player_monoids")
local has_pova = core.get_modpath("pova")
local has_areas = core.get_modpath("areas")

local enable_hud_overlay = core.settings:get_bool("hangglider.enable_hud_overlay", true)
local enable_flak = has_areas and core.settings:get_bool("hangglider.enable_flak", true)
local flak_warning_time = tonumber(core.settings:get("hangglider.flak_warning_time")) or 2
local hangglider_uses = tonumber(core.settings:get("hangglider.uses")) or 250

local flak_warning = S("You have entered restricted airspace!@n"
	.. "You will be shot down in @1 seconds by anti-aircraft guns!",
	flak_warning_time)

local hanggliding_players = {}
local physics_overrides = {}
local hud_overlay_ids = {}


if enable_flak then
	core.register_chatcommand("area_flak", {
		params = S("<ID>"),
		description = S("Toggle airspace restrictions for area <ID>."),
		func = function(name, param)
			local id = tonumber(param)
			if not id then
				return false, S("Invalid usage, see /help area_flak.")
			end
			if not areas:isAreaOwner(id, name) then
				return false, S("Area @1 does not exist or is not owned by you.", id)
			end
			local open = not areas.areas[id].flak
			-- Save false as nil to avoid inflating the DB.
			areas.areas[id].flak = open or nil
			areas:save()
			return true, S("Area @1 airspace is @2.", id,
				open and S("closed") or S("opened"))
		end
	})
end

function hangglider.is_gliding(player)
	if not player then
		return false
	end
	return hanggliding_players[player:get_player_name()]
end

local function set_hud_overlay(player, name, show)
	if not enable_hud_overlay then
		return
	end
	if not hud_overlay_ids[name] and show == true then
		hud_overlay_ids[name] = player:hud_add({
			[core.features.hud_def_type_field and "type" or "hud_elem_type"] = "image",
			text = "hangglider_overlay.png",
			position = {x = 0, y = 0},
			scale = {x = -100, y = -100},
			alignment = {x = 1, y = 1},
			offset = {x = 0, y = 0},
			z_index = -150
		})
	elseif hud_overlay_ids[name] and show == false then
		player:hud_remove(hud_overlay_ids[name])
		hud_overlay_ids[name] = nil
	end
end

local function set_physics_overrides(player, overrides)
	local player_name = player:get_player_name()
	if has_player_monoids then
		for name, value in pairs(overrides) do
			player_monoids[name]:add_change(player, value, "hangglider:glider")
		end
	elseif has_pova then
		pova.add_override(player_name, "hangglider:glider",
				{jump = 0, speed = overrides.speed, gravity = overrides.gravity})
		pova.do_override(player)
	else
		local def = player:get_physics_override()
		if not physics_overrides[player_name] then
			physics_overrides[player_name] = {
				physics = {
					speed = def.speed,
					jump = def.jump,
					gravity = def.gravity,
				},
				deltas = {speed = 0, jump = 0, gravity = 0},
			}
		end
		-- Compute the new delta to apply (relative to current physics)
		local delta = {
			speed = (overrides.speed or def.speed) - def.speed,
			jump = (overrides.jump or def.jump) - def.jump,
			gravity = (overrides.gravity or def.gravity) - def.gravity,
		}
		-- Track the sum of all deltas for this session.
		physics_overrides[player_name].deltas.speed = physics_overrides[player_name].deltas.speed + delta.speed
		physics_overrides[player_name].deltas.jump = physics_overrides[player_name].deltas.jump + delta.jump
		physics_overrides[player_name].deltas.gravity = physics_overrides[player_name].deltas.gravity + delta.gravity
		-- Apply new delta on top of current physics
		player:set_physics_override({
			speed = def.speed + delta.speed,
			jump = def.jump + delta.jump,
			gravity = def.gravity + delta.gravity,
		})
	end
end

local function remove_physics_overrides(player)
	local player_name = player:get_player_name()
	if has_player_monoids then
		for _, name in pairs({"jump", "speed", "gravity"}) do
			player_monoids[name]:del_change(player, "hangglider:glider")
		end
	elseif has_pova then
		pova.del_override(player_name, "hangglider:glider")
		pova.do_override(player)
	else
		local def = player:get_physics_override()
		if physics_overrides[player_name]
			and physics_overrides[player_name].physics
			and physics_overrides[player_name].deltas then

			-- Subtract total delta from current values
			player:set_physics_override({
				speed = def.speed - physics_overrides[player_name].deltas.speed,
				jump = def.jump - physics_overrides[player_name].deltas.jump,
				gravity = def.gravity - physics_overrides[player_name].deltas.gravity,
			})
			physics_overrides[player_name] = nil
		else
			player:set_physics_override({speed = 1, jump = 1, gravity = 1})
		end
	end
end

local function can_fly(pos, name)
	if not enable_flak then
		return true
	end
	local flak = false
	local owners = {}
	for _, area in pairs(areas:getAreasAtPos(pos)) do
		if area.flak then
			flak = true
		end
		owners[area.owner] = true
	end
	if flak and not owners[name] then
		return false
	end
	return true
end

local function safe_node_below(pos)
	local node = core.get_node_or_nil(vector.new(pos.x, pos.y - 0.5, pos.z))
	if not node then
		return false
	end
	local def = core.registered_nodes[node.name]
	if def and (def.walkable or (def.liquidtype ~= "none" and def.damage_per_second <= 0)) then
		return true
	end
	return false
end

local function shoot_flak_sound(pos)
	core.sound_play("hangglider_flak_shot", {
		pos = pos,
		max_hear_distance = 30,
		gain = 10.0,
	}, true)
end

local function hangglider_step(self, dtime)
	local gliding = false
	local player = self.object:get_attach("parent")
	if player then
		local pos = player:get_pos()
		local name = player:get_player_name()
		if hanggliding_players[name] then
			if not safe_node_below(pos) then
				gliding = true
				local vel = player:get_velocity().y
				if vel < 0 and vel > -3 then
					set_physics_overrides(player, {
						speed = math.abs(vel / 2.0) + 1.0,
						gravity = (vel + 3) / 20,
					})
				elseif vel <= -3 then
					set_physics_overrides(player, {
						speed = 2.5,
						gravity = -0.1,
					})
					if vel < -5 then
						-- Extra airbrake when falling too fast
						player:add_velocity(vector.new(0, math.min(5, math.abs(vel / 10.0)), 0))
					end
				else  -- vel > 0
					set_physics_overrides(player, {
						speed = 1.0,
						gravity = 0.25,
					})
				end
			end
			if not can_fly(pos, name) then
				if not self.flak_timer then
					self.flak_timer = 0
					shoot_flak_sound(pos)
					core.chat_send_player(name, flak_warning)
				else
					self.flak_timer = self.flak_timer + dtime
				end
				if self.flak_timer > flak_warning_time then
					player:set_hp(1, {type = "set_hp", cause = "hangglider:flak"})
					player:get_inventory():remove_item("main", ItemStack("hangglider:hangglider"))
					shoot_flak_sound(pos)
					gliding = false
				end
			end
			if not gliding then
				remove_physics_overrides(player)
				hanggliding_players[name] = nil
				set_hud_overlay(player, name, false)
			end
		end
	end
	if not gliding then
		self.object:set_detach()
		self.object:remove()
	end
end

local function hangglider_use(stack, player)
	if type(player) ~= "userdata" then
		return  -- Real players only
	end
	local pos = player:get_pos()
	local name = player:get_player_name()
	if not hanggliding_players[name] then
		core.sound_play("hanggliger_equip", {pos = pos, max_hear_distance = 8, gain = 1.0}, true)
		local entity = core.add_entity(pos, "hangglider:glider")
		if entity then
			entity:set_attach(player, "", vector.new(0, 10, 0), vector.new(0, 0, 0))
			local color = stack:get_meta():get("hangglider_color")
			if color then
				entity:set_properties({
					textures = {xcompat.textures.wool.white.."^[multiply:#"..color, xcompat.textures.wood.apple.planks}
				})
			end
			set_hud_overlay(player, name, true)
			set_physics_overrides(player, {jump = 0, gravity = 0.25})
			hanggliding_players[name] = true
			if hangglider_uses > 0 then
				stack:add_wear(65535 / hangglider_uses)
			end
			return stack
		end
	else
		set_hud_overlay(player, name, false)
		remove_physics_overrides(player)
		hanggliding_players[name] = nil
	end
end

core.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	hanggliding_players[name] = nil
	remove_physics_overrides(player)
end)

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	hanggliding_players[name] = nil
	hud_overlay_ids[name] = nil
	remove_physics_overrides(player)
end)

core.register_on_player_hpchange(function(player, hp_change, reason)
	local name = player:get_player_name()
	if hanggliding_players[name] and reason.type == "fall" then
		-- Stop all fall damage when hanggliding
		return 0, true
	end
	return hp_change
end, true)

core.register_entity("hangglider:glider", {
	initial_properties = {
		visual = "mesh",
		visual_size = {x = 12, y = 12},
		collisionbox = {0,0,0,0,0,0},
		mesh = "hangglider.obj",
		textures = {xcompat.textures.wool.white, xcompat.textures.wood.apple.planks},
		immortal = true,
		static_save = false,
	},
	on_step = hangglider_step,
})

core.register_tool("hangglider:hangglider", {
	description = S("Glider"),
	inventory_image = "hangglider_item.png",
	sound = {breaks = "default_tool_breaks"},
	on_use = hangglider_use,
})

dofile(core.get_modpath("hangglider").."/crafts.lua")
