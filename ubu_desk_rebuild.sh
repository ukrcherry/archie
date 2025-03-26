#!/bin/bash

sudo apt update
sudo apt install apt-src dpkg-dev ubuntu-dev-tools
sudo apt install live-build debootstrap squashfs-tools genisoimage

dpkg --get-selections | awk '{print $1}' > installed-packages.txt

mkdir -p ~/git/ubusrc
cd ~/git/ubusrc

while read package; do
    apt source $package
done < ~/installed-packages.txt

sudo apt update

while read package; do
    sudo apt build-dep -y $package
done < ~/installed-packages.txt

for dir in ~/git/ubusrc/*; do
    if [ -d "$dir" ]; then
        cd "$dir"
        dpkg-buildpackage -b -uc -us
        cd ~/git/ubusrc
    fi
done
