#!/bin/sh

pacman -Sy --noprogressbar --noconfirm git base-devel gd
git clone https://github.com/fsphil/fswebcam.git
cd fswebcam
git checkout e9f8094b6a3d1a49f99b2abec4e6ab4df33e2e33
./configure
make fswebcam
cp fswebcam /root/files/