default:
	sudo groupadd -f glacier
	sudo cp myedit /usr/local/bin/myedit
	sudo usermod -a -G glacier $(USER)
	sudo cp editors /etc/sudoers.d/glacier
