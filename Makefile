run: 
	docker-compose down && docker-compose up --build --detach

backup:
	./backup.sh

shell:
	docker-compose exec game bash

fix-perms:
	sudo chown -R 30000:$$(id -g) .minetest/world
	sudo chmod -R g+w .minetest/world
	sudo find .minetest/world -type d -exec chmod g+rwx {} ';'
	sudo chgrp $$(id -g) .minetest
	sudo chmod g+rwx .minetest