#!/bin/bash
PASSWORD=`sudo cat rootpass`
echo "New password: $PASSWORD"
echo "root:$PASSWORD" | sudo chpasswd
