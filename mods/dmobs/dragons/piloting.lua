
dmobs.dragon.step_custom = function(self, dtime)

	-- set required values if not already present
	if not self.v3 then
		self.v3 = true
		self.driver_attach_at = {x = 0, y = 1, z = -2}
		self.driver_eye_offset = {x = 0, y = 3, z = 0}
		self.driver_scale = {x = 0.5, y = 0.5} -- shrink driver to fit model
	end

	if self.driver then

		mobs.fly(self, dtime, 10, true, self.arrow, "walk", "stand")

		if self.state == "attack" then
			self.state = nil
		end

		return false -- skip rest of mob functions
	end

	return true
end


dmobs.dragon.ride = function(self, clicker)

	if self.tamed and self.owner == clicker:get_player_name() then

		local inv = clicker:get_inventory()

		if self.driver and clicker == self.driver then

			mobs.detach(clicker)

			if inv:room_for_item("main", "mobs:saddle") then
				inv:add_item("main", "mobs:saddle")
			else
				core.add_item(clicker:get_pos(), "mobs:saddle")
			end

		elseif not self.driver then

			if clicker:get_wielded_item():get_name() == "mobs:saddle" then

				mobs.attach(self, clicker)

				inv:remove_item("main", "mobs:saddle")
			end
		end
	end
end


dmobs.dragon.on_rc = function(self, clicker)

	if not clicker or not clicker:is_player() then return end

	if mobs:feed_tame(self, clicker, 1, false, false) then return end

	dmobs.dragon.ride(self, clicker)
end
