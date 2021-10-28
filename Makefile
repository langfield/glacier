default:
	sudo groupadd -f glacier
	sudo cp glacier.sh /usr/local/bin/glacier
	sudo usermod -a -G glacier $(USER)
	sudo cp editors /etc/sudoers.d/glacier
	./settargets.sh
rootpass:
	./setpass.sh
