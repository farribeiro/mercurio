local players_income = {}

local income_enabled = core.settings:get_bool("currency.income_enabled", true)
local creative_income_enabled = core.settings:get_bool("currency.creative_income_enabled", true)
local income_item = core.settings:get("currency.income_item") or "currency:minegeld_10"
local income_count = tonumber(core.settings:get("currency.income_count")) or 1
local income_period = tonumber(core.settings:get("currency.income_period")) or 720

if income_enabled then
	local timer = 0
	if creative_income_enabled then
		core.register_globalstep(function(dtime)
			timer = timer + dtime;
			if timer >= income_period then
				timer = 0
				for _, player in ipairs(core.get_connected_players()) do
					local name = player:get_player_name()
					players_income[name] = income_count
					core.log("info", "[Currency] basic income for "..name)
				end
			end
		end)
	else
		core.register_globalstep(function(dtime)
			timer = timer + dtime;
			if timer >= income_period then
				timer = 0
				for _, player in ipairs(core.get_connected_players()) do
					local name = player:get_player_name()
					local privs = core.get_player_privs(name)
					if not (privs.creative or privs.give) then
						players_income[name] = income_count
						core.log("info", "[Currency] basic income for "..name)
					end
				end
			end
		end)
	end

	local function earn_income(player)
		if not player or player.is_fake_player then return end
		local name = player:get_player_name()

		local ic = players_income[name]
		if ic and ic > 0 then
			local inv = player:get_inventory()
			inv:add_item("main", {name=income_item, count=ic})
			players_income[name] = nil
			core.log("info", "[Currency] added basic income for "..name.." to inventory")
		end
	end

	core.register_on_dignode(function(pos, oldnode, digger) earn_income(digger) end)
	core.register_on_placenode(function(pos, node, placer) earn_income(placer) end)
	core.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv) earn_income(player) end)
end
