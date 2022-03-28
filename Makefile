default:
	sudo groupadd -f glacier
	sudo cp glacier.sh /usr/local/bin/glacier
	sudo usermod -a -G glacier $(USER)
	sudo cp editors /etc/sudoers.d/glacier
	./settargets.sh
rootpass:
	./setpass.sh
uninstall:
	sudo rm -rf /usr/local/bin/glacier
	sudo rm -rf /usr/local/etc/glacier-rootpass
	rm -rf ~/.glacier_targets
