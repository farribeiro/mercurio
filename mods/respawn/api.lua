
local S = respawn.S



-- Round utility
local function round( num )
    return num >= 0 and math.floor( num + 0.5 ) or math.ceil( num - 0.5 )
end



-- Load from storage or config
respawn.load = function()
	-- Respawn points
	respawn.respawn_points = respawn.load_db( "respawn" )
	
	if respawn.respawn_points == nil then
		-- If not found, then try to default to some values
		respawn.reset_respawns()
	end
	
	-- Per team respawn
	respawn.team_respawn_points = respawn.load_db( "team_respawn" ) or {}
	
	-- Server global named places/fine points of view
	respawn.places = respawn.load_db( "places" ) or {}

	-- Per player named places/fine points of view
	respawn.player_places = respawn.load_db( "player_places" ) or {}
	
	-- Per player death
	respawn.player_deaths = respawn.load_db( "player_deaths" ) or {}

	-- Optimization
	respawn.restricted_places = {}
	for place_name , place in pairs( respawn.places ) do
		if place.restricted then
			respawn.restricted_places[ place_name ] = place
		end
	end

	-- Activate the place HUD
	respawn.activate_place_hud()
end



-- Reset respawn to default value
respawn.reset_respawns = function()
	respawn.respawn_points = {}
	respawn.save_db( "respawn" , respawn.respawn_points )
	return true
end



-- data contains pos and look
respawn.set_respawn = function( spawn_id , data )
	spawn_id = spawn_id or 1
	respawn.respawn_points[ spawn_id ] = data
	respawn.save_db( "respawn" , respawn.respawn_points )
	return true
end



-- Remove all teams' respawns
respawn.reset_team_respawns = function()
	respawn.team_respawns = {}
	respawn.save_db( "team_respawns" , respawn.team_respawns )
	return true
end



respawn.set_team_respawn = function( team_name , spawn_id , data )
	spawn_id = spawn_id or 1
	if not team_name or type( team_name ) ~= "string" or team_name == "" then return false end
	if not respawn.team_respawn_points[ team_name ] then respawn.team_respawn_points[ team_name ] = {} end
	respawn.team_respawn_points[ team_name ][ spawn_id ] = data
	respawn.save_db( "team_respawn" , respawn.team_respawn_points )
	return true
end



respawn.reset_places = function()
	respawn.places = {}
	respawn.save_db( "places" , respawn.places )
	return true
end



respawn.set_place = function( place_name , data )
	if not place_name or type( place_name ) ~= "string" or place_name == "" then return false end
	respawn.places[ place_name ] = data
	respawn.save_db( "places" , respawn.places )
	return true
end



respawn.remove_place = function( place_name )
	if not place_name or type( place_name ) ~= "string" or place_name == "" then return false end
	respawn.places[ place_name ] = nil
	respawn.save_db( "places" , respawn.places )
	return true
end



--[[
	place.restricted: object, should exists if the area is restricted, where:
		non_players: boolean, true if non-player are always granted
		players: array of string, player names of allowed players, CAN BE NULL because of json serilizer
		teams: array of string, team names of allowed teams, CAN BE NULL because of json serilizer
]]--
respawn.restrict_place = function( place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or respawn.places[ place_name ].restricted
	then
		return false
	end

	respawn.places[ place_name ].restricted = {
		players = {} ,
		teams = {} ,
		non_players = false
	}
	respawn.restricted_places[ place_name ] = respawn.places[ place_name ]
	respawn.save_db( "places" , respawn.places )
	return true
end



respawn.unrestrict_place = function( place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	respawn.places[ place_name ].restricted = nil
	respawn.restricted_places[ place_name ] = nil
	respawn.save_db( "places" , respawn.places )
	return true
end



-- Grant dig/place_node to a player
respawn.grant_place = function( player_name , place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	if not respawn.places[ place_name ].restricted.players then
		respawn.places[ place_name ].restricted.players = {}
	elseif respawn.places[ place_name ].restricted.players[ player_name ] then
		-- Nothing to do, avoid serialization
		return false
	end

	respawn.places[ place_name ].restricted.players[ player_name ] = true
	respawn.save_db( "places" , respawn.places )
	return true
end



-- Grant dig/place_node to a team
respawn.team_grant_place = function( team_name , place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	if not respawn.places[ place_name ].restricted.teams then
		respawn.places[ place_name ].restricted.teams = {}
	elseif respawn.places[ place_name ].restricted.teams[ team_name ] then
		-- Nothing to do, avoid serialization
		return false
	end

	respawn.places[ place_name ].restricted.teams[ team_name ] = true
	respawn.save_db( "places" , respawn.places )
	return true
end



-- Grant dig/place_node to a non-players
respawn.non_player_grant_place = function( place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	-- Nothing to do?
	if respawn.places[ place_name ].restricted.non_players then return false end

	respawn.places[ place_name ].restricted.non_players = true
	respawn.save_db( "places" , respawn.places )
	return true
end



-- Revoke dig/place_node to a player
respawn.revoke_place = function( player_name , place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	-- Nothing to do?
	if not respawn.places[ place_name ].restricted.players or not respawn.places[ place_name ].restricted.players[ player_name ] then
		return false
	end

	respawn.places[ place_name ].restricted.players[ player_name ] = nil
	respawn.save_db( "places" , respawn.places )
	return true
end



-- Revoke dig/place_node to a team
respawn.team_revoke_place = function( team_name , place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	-- Nothing to do?
	if not respawn.places[ place_name ].restricted.teams or not respawn.places[ place_name ].restricted.teams[ team_name ] then
		return false
	end

	respawn.places[ place_name ].restricted.teams[ team_name ] = nil
	respawn.save_db( "places" , respawn.places )
	return true
end



-- Revoke dig/place_node to a non-players
respawn.non_player_revoke_place = function( place_name )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ]
		or not respawn.places[ place_name ].restricted
	then
		return false
	end

	-- Nothing to do?
	if not respawn.places[ place_name ].restricted.non_players then return false end

	respawn.places[ place_name ].restricted.non_players = false
	respawn.save_db( "places" , respawn.places )
	return true
end



local function enlarge_area( area , pos , player_mode )
	local ymin_delta = 0
	local ymax_delta = 0

	if player_mode then
		ymin_delta = -1	-- one node below for player mode
		ymax_delta = 2	-- two nodes above for player mode

		if type( player_mode ) == "number" then
			local delta = round( player_mode )
			if delta <= 0 then ymin_delta = delta end
			if delta >= 0 then ymax_delta = delta end
		end
	end

	local xmin = round( player_mode and ( pos.x - 1 ) or pos.x )
	local xmax = round( player_mode and ( pos.x + 1 ) or pos.x )
	local ymin = round( pos.y + ymin_delta )
	local ymax = round( pos.y + ymax_delta )
	local zmin = round( player_mode and ( pos.z - 1 ) or pos.z )
	local zmax = round( player_mode and ( pos.z + 1 ) or pos.z )

	if area.xmin > xmin then area.xmin = xmin end
	if area.xmax < xmax then area.xmax = xmax end
	if area.ymin > ymin then area.ymin = ymin end
	if area.ymax < ymax then area.ymax = ymax end
	if area.zmin > zmin then area.zmin = zmin end
	if area.zmax < zmax then area.zmax = zmax end
end



-- If y_axis_mode is set, it only shrinks this axis, else it only shrinks on the XZ plane
local function shrink_area( area , origin , pos , y_axis_mode )
	if y_axis_mode then
		local pos_y = round( pos.y )
		local origin_y = round( origin.y )
		if pos_y >= origin_y then area.ymax = pos_y end
		if pos_y <= origin_y then area.ymin = pos_y end
	else
		local pos_x = round( pos.x )
		local pos_z = round( pos.z )
		local origin_x = round( origin.x )
		local origin_z = round( origin.z )
		if pos_x >= origin_x then area.xmax = pos_x end
		if pos_x <= origin_x then area.xmin = pos_x end
		if pos_z >= origin_z then area.zmax = pos_z end
		if pos_z <= origin_z then area.zmin = pos_z end
	end
end



local function is_inside_area( area , pos )
	local x = round( pos.x )
	local y = round( pos.y )
	local z = round( pos.z )
	return x >= area.xmin and x <= area.xmax and y >= area.ymin and y <= area.ymax and z >= area.zmin and z <= area.zmax
end



respawn.enlarge_place_area = function( place_name , pos , player_mode )
	if not place_name or type( place_name ) ~= "string" or place_name == "" or not respawn.places[ place_name ] then return false end

	local place = respawn.places[ place_name ]
	if not place.area then
		place.area = {
			xmin = round( place.pos.x ) , xmax = round( place.pos.x ) ,
			ymin = round( place.pos.y ) , ymax = round( place.pos.y ) ,
			zmin = round( place.pos.z ) , zmax = round( place.pos.z )
		}
	end

	enlarge_area( place.area , pos , player_mode )
	respawn.save_db( "places" , respawn.places )
	return true
end



respawn.shrink_place_area = function( place_name , pos , y_axis_mode )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ] or not respawn.places[ place_name ].area
	then
		return false
	end

	local place = respawn.places[ place_name ]
	shrink_area( place.area , place.pos , pos , y_axis_mode )
	respawn.save_db( "places" , respawn.places )
	return true
end



respawn.is_inside_place = function( place_name , pos )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.places[ place_name ] or not respawn.places[ place_name ].area
	then
		return false
	end

	return is_inside_area( respawn.places[ place_name ].area , pos )
end



-- Remove all players' places
respawn.reset_all_players_places = function()
	respawn.player_places = {}
	respawn.save_db( "player_places" , respawn.player_places )
	return true
end



-- Reset personal places for one player only
respawn.reset_player_places = function( player )
	if not player then return false end
	local player_name = player:get_player_name()
	if not player_name then return false end
	respawn.player_places[ player_name ] = {}
	respawn.save_db( "player_places" , respawn.player_places )
	return true
end



respawn.set_player_place = function( player , place_name , data )
	if not player then return false end
	local player_name = player:get_player_name()
	if not player_name then return false end
	if not place_name or type( place_name ) ~= "string" or place_name == "" then place_name = "home" end
	if not respawn.player_places[ player_name ] then respawn.player_places[ player_name ] = {} end
	respawn.player_places[ player_name ][ place_name ] = data
	respawn.save_db( "player_places" , respawn.player_places )
	return true
end



respawn.remove_player_place = function( player , place_name )
	if not player then return false end
	local player_name = player:get_player_name()
	if not player_name then return false end
	if not place_name or type( place_name ) ~= "string" or place_name == "" then return false end
	
	-- Nothing to do
	if not respawn.player_places[ player_name ] then return true end
	
	respawn.player_places[ player_name ][ place_name ] = nil
	respawn.save_db( "player_places" , respawn.player_places )
	return true
end



respawn.enlarge_player_place_area = function( player , place_name , pos , player_mode )
	if not player then return false end
	local player_name = player:get_player_name()
	if not player_name then return false end

	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.player_places[ player_name ] or not respawn.player_places[ player_name ][ place_name ]
	then
		return false
	end

	local place = respawn.player_places[ player_name ][ place_name ]
	if not place.area then
		place.area = {
			xmin = round( place.pos.x ) , xmax = round( place.pos.x ) ,
			ymin = round( place.pos.y ) , ymax = round( place.pos.y ) ,
			zmin = round( place.pos.z ) , zmax = round( place.pos.z )
		}
	end

	enlarge_area( place.area , pos , player_mode )
	respawn.save_db( "player_places" , respawn.player_places )
	return true
end



respawn.shrink_player_place_area = function( place_name , pos , y_axis_mode )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.player_places[ player_name ] or not respawn.player_places[ player_name ][ place_name ]
		or not respawn.player_places[ player_name ][ place_name ].area
	then
		return false
	end

	local place = respawn.player_places[ player_name ][ place_name ]
	shrink_area( place.area , place.pos , pos , y_axis_mode )
	respawn.save_db( "player_places" , respawn.player_places )
	return true
end



respawn.is_inside_player_place = function( place_name , pos )
	if
		not place_name or type( place_name ) ~= "string" or place_name == ""
		or not respawn.player_places[ place_name ] or not respawn.player_places[ place_name ].area
	then
		return false
	end

	return is_inside_area( respawn.player_places[ place_name ].area , pos )
end



respawn.output_teams = function( chat_player )
	if not chat_player then return false end

	local chat_player_name = chat_player:get_player_name()
	if chat_player_name == "" then return false end
	
	local str = S("List of teams:")
	local teams = {}
	local players = core.get_connected_players()
	
	for k, player in ipairs( players ) do
		local player_name = player:get_player_name()
		local meta = player:get_meta()
		local team_name = meta:get_string( "team" )
		
		if team_name and team_name ~= "" then
			if not teams[ team_name ] then teams[ team_name ] = {} end
			table.insert( teams[ team_name ] , player_name )
		end
	end
	
	for team_name, members in pairs( teams ) do
		str = str .. "\n  " .. team_name .. ":"
		
		for k2, player_name in ipairs( members ) do
			str = str .. " " .. player_name
		end
	end
	
	core.chat_send_player( chat_player_name , str )
	return true
end



-- TODO: for instance it just counts how many there are
respawn.output_respawn_points = function( player )
	if not player then return false end

	local player_name = player:get_player_name()
	if player_name == "" then return false end
	
	core.chat_send_player( player_name , S("There are @1 respawn points." , #respawn.respawn_points) )
	return true
end



-- TODO: for instance it just counts how many there are
respawn.output_team_respawn_points = function( player , team_name )
	if not player then return false end

	local player_name = player:get_player_name()
	if player_name == "" then return false end
	
	if not team_name then
		local meta = player:get_meta()
		team_name = meta:get_string( "team" )
		if not team_name or team_name == "" then
			core.chat_send_player( player_name , S("Team not found.") )
		end
	end
	
	if not respawn.team_respawn_points[ team_name ] then
		core.chat_send_player( player_name , S("There are no team respawn points.") )
	else
		core.chat_send_player( player_name , S("There are @1 team respawn points." , #respawn.team_respawn_points[ team_name ]) )
	end
	return true
end



respawn.output_places = function( player )
	if not player then return false end

	local player_name = player:get_player_name()
	if player_name == "" then return false end
	
	local places_str = ""
	local count = 0
	
	for key , value in pairs( respawn.places ) do
		if value.full_name then
			places_str = places_str .. "\n  " .. value.full_name .. " [" .. key .. "]"
		else
			places_str = places_str .. "\n  [" .. key .. "]"
		end
		
		count = count + 1
	end
	
	if count == 0 then
		core.chat_send_player( player_name , S("There is no place defined.") )
	else
		core.chat_send_player( player_name , S("Global places:@1" , places_str ) )
	end
	return true
end



respawn.output_player_places = function( player )
	if not player then return false end

	local player_name = player:get_player_name()
	if player_name == "" then return false end
	
	if not respawn.player_places[ player_name ] then
		core.chat_send_player( player_name , S("You have no own place defined.") )
		return true
	end
	
	local places_str = ""
	local count = 0
	
	for key , value in pairs( respawn.player_places[ player_name ] ) do
		if value.full_name then
			places_str = places_str .. "\n  " .. value.full_name .. " [" .. key .. "]"
		else
			places_str = places_str .. "\n  [" .. key .. "]"
		end

		count = count + 1
	end
	
	if count == 0 then
		core.chat_send_player( player_name , S("You have no own place defined.") )
	else
		core.chat_send_player( player_name , S("Your personal places:@1" , places_str ) )
	end
	return true
end



respawn.output_allowed_place_players = function( chat_player , place_name )
	if not chat_player then return false end

	local chat_player_name = chat_player:get_player_name()
	if chat_player_name == "" then return false end

	local place = respawn.places[ place_name ]
	if not place then return false end
	
	local allowed_players_str = ""
	if place.restricted.players then
		for player_name , granted in pairs( place.restricted.players ) do
			if allowed_players_str ~= "" then allowed_players_str = allowed_players_str .. ", " end
			allowed_players_str = allowed_players_str .. player_name
		end
	end

	local allowed_teams_str = ""
	if place.restricted.teams then
		for team_name , granted in pairs( place.restricted.teams ) do
			if allowed_teams_str ~= "" then allowed_teams_str = allowed_teams_str .. ", " end
			allowed_teams_str = allowed_teams_str .. team_name
		end
	end

	if allowed_players_str == "" and allowed_teams_str == "" then
		core.chat_send_player( chat_player_name , S("'@1' is restricted.", place_name) )
	elseif allowed_players_str ~= "" and allowed_teams_str ~= "" then
		core.chat_send_player( chat_player_name , S("'@1' is owned by: @2. And team-owned by: @3.", place_name , allowed_players_str , allowed_teams_str) )
	elseif allowed_players_str ~= "" then
		core.chat_send_player( chat_player_name , S("'@1' is owned by: @2.", place_name , allowed_players_str) )
	elseif allowed_teams_str ~= "" then
		core.chat_send_player( chat_player_name , S("'@1' is team-owned by: @2.", place_name , allowed_teams_str) )
	end

	return true
end



-- If safe_radius is set to a number, try to teleport to a safe spot near the original point, if no safe spot is found, do not teleport.
-- If safe_radius = true, it's like safe_radius = 0.
-- If safe_radius = false or nil, do not check anything and always teleport.
respawn.teleport = function( player , point , safe_radius )
	if not player or not point then return false end

	if safe_radius then
		if safe_radius == true then safe_radius = 0 end
		local safe_pos = respawn.find_safe_spot( point.pos , safe_radius )
		if not safe_pos then return false end
		player:set_pos( safe_pos )
	else
		player:set_pos( point.pos )
	end
	
	if point.look then
		player:set_look_horizontal( point.look.h )
		player:set_look_vertical( point.look.v )
	end
	
	return true
end



respawn.teleport_to_respawn = function( player , spawn_id , safe_radius )
	spawn_id = spawn_id or math.random( #respawn.respawn_points )
	
	local point = respawn.respawn_points[ spawn_id ]
	if not point then point = respawn.respawn_points[ 1 ] end
	
	return respawn.teleport( player , point , safe_radius )
end



respawn.teleport_to_team_respawn = function( player , spawn_id , safe_radius )
	local meta = player:get_meta()
	local team_name = meta:get_string( "team" )
	
	if not team_name or team_name == "" or not respawn.team_respawn_points[ team_name ] then
		return false
	end
	
	spawn_id = spawn_id or math.random( #respawn.team_respawn_points[ team_name ] )
	
	local point = respawn.team_respawn_points[ team_name ][ spawn_id ]
	if not point then point = respawn.team_respawn_points[ team_name ][ 1 ] end
	
	return respawn.teleport( player , point , safe_radius )
end



-- Argument "teams" is a hash of { team1 = true , ... }
respawn.teleport_teams_to_team_respawn = function( teams , safe_radius )
	local meta , team_name , spawn_id , point
	local players = core.get_connected_players()
	
	for k, player in ipairs( players ) do
		meta = player:get_meta()
		team_name = meta:get_string( "team" )
		
		if team_name and team_name ~= "" and ( not teams or teams[ team_name ] == true ) and respawn.team_respawn_points[ team_name ] then
			spawn_id = math.random( #respawn.team_respawn_points[ team_name ] )
			point = respawn.team_respawn_points[ team_name ][ spawn_id ]
			respawn.teleport( player , point , safe_radius )
		end
	end
	
	return true
end



respawn.teleport_to_place = function( player , place_name , safe_radius )
	local point = respawn.places[ place_name ]
	return respawn.teleport( player , point , safe_radius )
end



respawn.teleport_to_player_place = function( player , place_name , safe_radius )
	if not player then return false end

	local player_name = player:get_player_name()
	if player_name == "" or not respawn.player_places[ player_name ] then return false end
	
	local point = respawn.player_places[ player_name ][ place_name ]
	return respawn.teleport( player , point , safe_radius )
end



respawn.teleport_to_other_player_place = function( player , other_player , place_name , safe_radius )
	if not player or not other_player then return false end

	local other_player_name = other_player:get_player_name()
	if other_player_name == "" or not respawn.player_places[ other_player_name ] then return false end
	
	local point = respawn.player_places[ other_player_name ][ place_name ]
	return respawn.teleport( player , point , safe_radius )
end



respawn.teleport_to_other_player = function( player , other_player , safe_radius )
	if not player or not other_player then return false end
	
	local pos = other_player:get_pos()
	
	-- Avoid to invade one's personal place ^^
	pos.x = pos.x + math.random( -2 , 2 )
	pos.y = pos.y + math.random( 0 , 1 )
	pos.z = pos.z + math.random( -2 , 2 )
	
	return respawn.teleport( player , { pos = pos } , safe_radius )
end



respawn.teleport_to_player_last_death_place = function( player , safe_radius )
	if not player then return false end

	local player_name = player:get_player_name()
	if player_name == "" or not respawn.player_deaths[ player_name ] or #respawn.player_deaths[ player_name ] == 0 then return false end
	
	local point = respawn.player_deaths[ player_name ][ #respawn.player_deaths[ player_name ] ] ;
	return respawn.teleport( player , point , safe_radius )
end



respawn.teleport_delay = function( player , type , id , delay , safe_radius )
	core.after( delay , function()
		if type == "respawn" then
			respawn.teleport_to_respawn( player , id , safe_radius )
		elseif type == "team_respawn" then
			respawn.teleport_to_team_respawn( player , id , safe_radius )
		elseif type == "place" then
			respawn.teleport_to_place( player , id , safe_radius )
		elseif type == "player_place" then
			respawn.teleport_to_player_place( player , id , safe_radius )
		elseif type == "last_death" then
			respawn.teleport_to_player_last_death_place( player , safe_radius )
		end
	end )
end



-- a and b are position
function squared_distance( a , b )
	return ( a.x - b.x ) * ( a.x - b.x ) + ( a.y - b.y ) * ( a.y - b.y ) + ( a.z - b.z ) * ( a.z - b.z )
end



respawn.closest_thing = function( list , pos , max_dist , max_squared_dist )
	if not max_dist and not max_squared_dist then max_dist = 64000 end
	if not max_squared_dist then max_squared_dist = max_dist * max_dist end
	
	local closest_squared_dist = max_squared_dist
	local closest_place
	local closest_place_name
	local squared_dist
	
	for place_name , place in pairs( list ) do
		squared_dist = squared_distance( pos , place.pos )
		
		if squared_dist < closest_squared_dist then
			closest_squared_dist = squared_dist
			closest_place = place
			closest_place_name = place_name
		end
	end
	
	return closest_place_name , closest_place , closest_squared_dist
end



respawn.closest_respawn = function( pos , max_dist , max_squared_dist )
	return respawn.closest_thing( respawn.respawn_points , pos , max_dist , max_squared_dist )
end



respawn.closest_team_respawn = function( player_name , pos , max_dist , max_squared_dist )
	local player = core.get_player_by_name( player_name )
	local meta = player:get_meta()
	local team_name = meta:get_string( "team" )
	
	if respawn.team_respawn_points[ team_name ] then
		return respawn.closest_thing( respawn.team_respawn_points[ team_name ] , pos , max_dist , max_squared_dist )
	end
end



respawn.closest_place = function( pos , max_dist , max_squared_dist )
	return respawn.closest_thing( respawn.places , pos , max_dist , max_squared_dist )
end



respawn.closest_player_place = function( player_name , pos , max_dist , max_squared_dist )
	if respawn.player_places[ player_name ] then
		return respawn.closest_thing( respawn.player_places[ player_name ] , pos , max_dist , max_squared_dist )
	end
end



respawn.closest_place_or_player_place = function( player_name , pos , max_dist )
	local place_name , place , square_dist , place_name2 , place2 , square_dist2
	
	-- Use the chat player for player place, it makes more sense
	place_name , place , square_dist = respawn.closest_player_place( player_name , pos , max_dist )
	
	if place_name then
		place_name2 , place2 , square_dist2 = respawn.closest_place( pos , nil , square_dist )

		if place_name2 then
			return place_name2 , place2 , square_dist2
		else
			return place_name , place , square_dist
		end
	else
		return respawn.closest_place( pos , max_dist )
	end
end



-- Return all places that the position is into its area
respawn.get_encompassing_things = function( list , pos , type , matching_things )
	if not matching_things then matching_things = {} end
	
	for place_name , place in pairs( list ) do
		if place.area and is_inside_area( place.area , pos ) then
			matching_things[ #matching_things + 1 ] = { place_name , place , type }
		end
	end
	
	return matching_things
end

-- Same than get_encompassing_things() but only return the first matching
respawn.get_first_encompassing_thing = function( list , pos , type )
	for place_name , place in pairs( list ) do
		if place.area and is_inside_area( place.area , pos ) then
			return place_name , place , type
		end
	end
end



respawn.get_encompassing_places = function( pos )
	return respawn.get_encompassing_things( respawn.places , pos , "place" )
end

respawn.get_first_encompassing_place = function( pos )
	return respawn.get_first_encompassing_thing( respawn.places , pos , "place" )
end



respawn.get_encompassing_player_places = function( player_name , pos )
	if respawn.player_places[ player_name ] then
		return respawn.get_encompassing_things( respawn.player_places[ player_name ] , pos , "player_place" )
	end
end

respawn.get_first_encompassing_player_place = function( player_name , pos )
	if respawn.player_places[ player_name ] then
		return respawn.get_first_encompassing_thing( respawn.player_places[ player_name ] , pos , "player_place" )
	end
end



respawn.get_encompassing_places_or_player_places = function( player_name , pos )
	local list = respawn.get_encompassing_things( respawn.places , pos , "place" )
	if respawn.player_places[ player_name ] then
		respawn.get_encompassing_things( respawn.player_places[ player_name ] , pos , "player_place" , list )
	end
	return list
end

respawn.get_first_encompassing_place_or_player_place = function( player_name , pos )
	local place_name , place , place_type = respawn.get_first_encompassing_thing( respawn.places , pos , "place" )
	if not place and respawn.player_places[ player_name ] then
		place_name , place , place_type = respawn.get_first_encompassing_thing( respawn.player_places[ player_name ] , pos , "player_place" )
	end
	return place_name , place , place_type
end



respawn.respawn = function( player )
	-- We use a delay because returning true has no effect despite what the doc tells
	-- so we teleport after the regular spawn
	
	if core.settings:get_bool("enable_team_respawn") then
		local meta = player:get_meta()
		local team_name = meta:get_string( "team" )
		if team_name and team_name ~= "" and respawn.team_respawn_points[ team_name ] and #respawn.team_respawn_points[ team_name ] > 0 then
			respawn.teleport_delay( player , "team_respawn" , math.random( #respawn.team_respawn_points[ team_name ] ) , 0 )
			return true
		end
	end

	if core.settings:get_bool("enable_home_respawn") then
		local player_name = player:get_player_name()
		if player_name and respawn.player_places[ player_name ] and respawn.player_places[ player_name ].home then
			respawn.teleport_delay( player , "player_place" , "home" , 0 )
			return true
		end
	end

	if #respawn.respawn_points > 0 then
		respawn.teleport_delay( player , "respawn" , math.random( #respawn.respawn_points ) , 0 )
		return true
	end
	
	-- If no respawn points defined, let the default behavior kick in... then add the actual default spawn to our list!
	core.after( 0.5 , function()
		local pos = player:get_pos()
		
		-- Check if there is still no respawn point and if the player is still available
		if #respawn.respawn_points > 0 or not pos then return end

		respawn.set_respawn( 1 , {
			pos = pos ,
			look = { h = player:get_look_horizontal() , v = player:get_look_vertical() }
		} )
	end )
end



respawn.add_death_log = function( player , data )
	if not player then return false end
	local player_name = player:get_player_name()
	if not player_name then return false end

	if not respawn.player_deaths[ player_name ] then respawn.player_deaths[ player_name ] = {} end
	table.insert( respawn.player_deaths[ player_name ] , data )
	respawn.save_db( "player_deaths" , respawn.player_deaths )
	return true
end



local function message_node_name( node_name )
	node_name = node_name:gsub( "[^:]+:" , "" )
	node_name = node_name:gsub( "_" , " " )
	return node_name
end



local function message_biome_name( biome_name )
	biome_name = biome_name:gsub( "[^:]+:" , "" )
	biome_name = biome_name:gsub( "_" , " " )
	return biome_name
end



respawn.death_message = function( player_name , data )
	local place = S("at some unknown place")
	
	if data.place and data.place ~= "" and type( data.place ) == "string" then
		place = "near " .. message_biome_name( data.place )
	elseif data.biome and data.biome ~= "" and type( data.biome ) == "string" then
		place = "near " .. message_biome_name( data.biome )
	end
	
	if data.by_type == "player" then
		if data.using and data.using ~= "" and type( data.using ) == "string" then
			return S("@1 was killed by @2, using @3, @4." , player_name , data.by , message_node_name( data.using ) , place )
		else
			return S("@1 was killed by @2 @3." , player_name , data.by , place )
		end
	
	elseif data.by_type == "entity" then
		-- For instance there is no difference between player and entity death messages
		-- Also it's worth noting that we need to use message_node_name() because sometime we got an entity type as name (e.g. mobs_xxx:mob_type)
		if data.using and data.using ~= "" and type( data.using ) == "string" then
			return S("@1 was killed by @2, using @3, @4." , player_name , message_node_name( data.by ) , message_node_name( data.using ) , place )
		else
			return S("@1 was killed by @2 @3." , player_name , message_node_name( data.by ) , place )
		end
	
	elseif data.by_type == "fall" then
		return S("@1 has fallen @2." , player_name , place )
	
	elseif data.by_type == "drown" then
		if data.by and data.by ~= "" and type( data.by ) == "string" then
			return S("@1 has drown in @2, @3." , player_name , message_node_name( data.by ) , place )
		else
			return S("@1 has drown @2." , player_name , place )
		end
	
	elseif data.by_type == "node" then
		if data.by and data.by ~= "" and type( data.by ) == "string" then
			return S("@1 should not play with @2, @3." , player_name , message_node_name( data.by ) , place )
		else
			return S("@1 should not play with dangerous things @2." , player_name , place )
		end
	end

	return S("@1 was killed @2." , player_name , place )
end



respawn.death = function( player , data )
	if not player then return false end
	local player_name = player:get_player_name()
	if not player_name then return false end
	
	local pos = player:get_pos()
	data.pos = pos
	
	local place_name , place = respawn.closest_place( pos , 80 )
	
	if place then
		data.place = place.full_name or place_name
	end
	
	local biome_data = core.get_biome_data( pos )
	
	if biome_data then
		data.biome = core.get_biome_name( biome_data.biome )
	end
	
	respawn.add_death_log( player , data )
	core.chat_send_all( respawn.death_message( player_name , data ) )
	
	return true
end



respawn.output_deaths = function( chat_player , player_name )
	local chat_player_name = chat_player:get_player_name()
	if chat_player_name == "" then return false end
	
	if not player_name then player_name = chat_player_name end

	if not respawn.player_deaths[ player_name ] then
		core.chat_send_player( chat_player_name , S("@1 hasn't died already.", player_name ) )
		return true
	end
	
	local deaths_str = ""
	local count = 0
	
	for key , value in pairs( respawn.player_deaths[ player_name ] ) do
		deaths_str = deaths_str .. "\n  " .. key .. ": " .. respawn.death_message( player_name , value )
		count = count + 1
	end
	
	if count == 0 then
		core.chat_send_player( chat_player_name , S("@1 hasn't died already.") )
	else
		core.chat_send_player( chat_player_name , S("@1 has died @2 times: @3" , player_name , count , deaths_str ) )
	end
end



function respawn.find_safe_spot( pos , radius )
	-- Ensure the map is loaded, the map should have been generated beforehand.
	-- Since we use that to teleport player, we assume that a teleport point have been visited by someone already.
	core.load_area(
		{ x = pos.x - radius , y = pos.y - radius - 1 , z = pos.z - radius } ,
		{ x = pos.x + radius , y = pos.y + radius + 1 , z = pos.z + radius }
	)

	for pass_radius = 0 , radius do
		for dy = - pass_radius , pass_radius do
			for dx = - pass_radius , pass_radius do
				for dz = - pass_radius , pass_radius do
					if math.max( dx , dy , dz ) == pass_radius then
						local check_pos = { x = pos.x + dx , y = pos.y + dy , z = pos.z + dz }
						if respawn.is_safe_spot( check_pos ) then return check_pos end
					end
				end
			end
		end
	end
end



-- Used by teleport chat command, flying player deactivated the safe_radius for teleportation
-- We can't detect reliably if a player is flying, we will tell that if it has the fly privilege and surrounded by air nodes
respawn.is_player_flying = function( player )
	-- The player should at least have the fly privilege
	local privs = core.get_player_privs( player:get_player_name() )
	if not privs.fly then return false end

	-- This part does not work most of time: physics.fly is not set unless set_physics_override({fly=true}) is set by a mod,
	-- pressing the fly key does not set this...
	local physics = player:get_physics_override()
	if physics.fly then return true end

    local pos = player:get_pos()
	
	for dy = -2 , 2 do
		for dx = -1 , 1 do
			for dz = -1 , 1 do
				local node = core.get_node_or_nil( { x = pos.x + dx , y = pos.y + dy , z = pos.z + dz } )
				if node.name ~= "air" then return false end
			end
		end
	end

	return true
end



-- Check if a node is liquid or has water-like groups
local function is_water_def( node_def )
    return node_def.liquidtype == "source" or node_def.liquidtype == "flowing" or node_def.groups.water ~= nil
end

-- Check if a node damage the player
local function has_damage_def( node_def )
    return node_def.damage_per_second and node_def.damage_per_second > 0
end

-- Check if a node is solid
local function is_solid_ground_def( node_def )
    return node_def.walkable
end



-- Safe: head is in air, solid ground under OR in water, base in air or water, no node that hurts
function respawn.is_safe_spot( pos )
	local under_pos = { x = pos.x , y = pos.y - 1 , z = pos.z }
	local head_pos = { x = pos.x , y = pos.y + 1 , z = pos.z }

	local node = core.get_node_or_nil( pos )
	local under_node = core.get_node_or_nil( under_pos )
	local head_node = core.get_node_or_nil( head_pos )

	if not node or not under_node or not head_node then return false end

	--local head_node_def = core.registered_nodes[ head_node.name ]
	if head_node.name ~= "air" then return false end

	local node_def = core.registered_nodes[ node.name ]
	if node.name ~= "air" and ( not is_water_def( node_def ) or has_damage_def( node_def ) ) then
		return false
	end

	local under_node_def = core.registered_nodes[ under_node.name ]
	if under_node.name == "air" or ( not is_solid_ground_def( under_node_def ) and not is_water_def( under_node_def ) ) or has_damage_def( under_node_def ) then
		return false
	end

	return true
end



-- Return true if the position is protected against digging/building, sometime even against chest opening
-- Digger is either a player or a mob or nothing
function respawn.is_protected( pos , digger_name , give_feedback )
	-- Early out, for optimization
	if not next( respawn.restricted_places ) then return false end

	if not digger_name or not pos then return true end

	local player = core.get_player_by_name( digger_name )

	if player and player:is_player() then
		-- protector_bypass privileged users can override protection
		if core.check_player_privs( digger_name , { protection_bypass = true } ) then return false end

		local meta = player:get_meta()
		local team_name = meta:get_string( "team" ) or ""

		-- Search for any place having a restricted property, the player should pass all of them
		for place_name , place in pairs( respawn.restricted_places ) do
			if
				place.restricted and place.area
				and ( not place.restricted.players or not place.restricted.players[ digger_name ] )
				and ( not place.restricted.teams or not place.restricted.teams[ team_name ] )
				and is_inside_area( place.area , pos )
			then
				if give_feedback then respawn.output_allowed_place_players( player , place_name ) end
				return true
			end
		end
	else
		-- It's probably an entity, a mob, or some userland code

		-- Search for any place having a restricted property, the digger should pass all of them
		for place_name , place in pairs( respawn.restricted_places ) do
			if place.restricted and place.area and not place.restricted.non_players and is_inside_area( place.area , pos ) then
				return true
			end
		end
	end

	return false
end



-- backup old is_protected function
local old_is_protected = core.is_protected

-- Replace core's is_protected (by default it is an empty function)
-- check for protected area, return true if protected and digger isn't on list
function core.is_protected( pos , digger_name )
	digger_name = digger_name or "" -- nil check

	-- is area protected against digger?
	if respawn.is_protected( pos , digger_name , true ) then return true end

	-- otherwise, test with pre-existing core.is_protected
	return old_is_protected( pos , digger_name )
end



--[[
-- Can be used to add protector hurt/flip, but we don't use that here for instance
core.register_on_protection_violation( function( pos , digger_name )
	local player = core.get_player_by_name( digger_name )
	if not player or not player:is_player() then return end
end )
]]--



-- Place HUD
respawn.activate_place_hud = function()
	respawn.hud_delay = 1
	respawn.last_hud_update = 0
	respawn.player_hud = {}
	respawn.had_hud = false

	core.register_globalstep( function( dtime )
		-- No need to change that too many time, for better perfs
		respawn.last_hud_update = respawn.last_hud_update + dtime
		if respawn.last_hud_update < respawn.hud_delay then return end
		respawn.last_hud_update = 0

		local connected_players
		local show_hud = core.settings:get_bool( "show_place_hud" , true )

		if not show_hud then
			if respawn.had_hud then
				-- The settings has been changed just now, so we have to remove existing place HUD for all players
				connected_players = core.get_connected_players()
				for _, player in ipairs( connected_players ) do
					local player_name = player:get_player_name()
					if player_name then
						local hud = respawn.player_hud[ player_name ]
						if hud and hud.id then
							player:hud_remove( hud.id )
							respawn.player_hud[ player_name ] = nil
						end
					end
				end
			end

			respawn.had_hud = false
			return
		end

		respawn.had_hud = true
		connected_players = core.get_connected_players()

		for _, player in ipairs( connected_players ) do
			local player_name = player:get_player_name()

			if player_name then
				local hud = respawn.player_hud[ player_name ]
				local place_name , place , place_type = respawn.get_first_encompassing_place_or_player_place( player_name , player:get_pos() )

				if place then
					if not hud then
						hud = { id = nil , last_message = "" , last_color = "" }
						respawn.player_hud[ player_name ] = hud
					end

					local message = place.full_name or place_name

					-- Colors: red for restricted, yellow for global, green for personal
					local color =
						( place_type == "place" and ( place.restricted and 0xffaaaa or 0xffffaa ) )
						or ( place_type == "player_place" and 0xaaffaa )
						or 0xffffff

					if not hud.id then
						hud.id = player:hud_add( {
							type = "text",
							position = {x=0.5, y=0.8},
							text = message,
							alignment = {x=0, y=0},
							size = {x=2},
							number = color
						} )
					else
						if message ~= hud.last_message then player:hud_change( hud.id , "text" , message ) end
						if color ~= hud.last_color then player:hud_change( hud.id , "number" , color ) end
					end

					hud.last_message = message
					hud.last_color = color
				elseif hud and hud.id then
					player:hud_remove( hud.id )
					hud.id = nil
					hud.last_message = ""
					hud.last_color = ""
				end
			end
		end
	end )
end

