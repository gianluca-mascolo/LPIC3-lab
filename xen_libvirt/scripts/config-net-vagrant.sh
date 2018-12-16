#!/bin/bash

sudo apt-get -y install bridge-utils net-tools
sudo cp /tmp/interfaces /etc/network/interfaces
sudo find /etc/systemd/network -type f -exec rm -f '{}' ';'
sudo systemctl disable systemd-networkd
sudo systemctl mask systemd-networkd
sudo systemctl daemon-reload
sudo /etc/init.d/networking restart

