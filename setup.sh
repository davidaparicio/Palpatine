#!/bin/bash

cd ~/

wget https://github.com/RDeville/Palpatine/archive/master.zip
unzip master.zip
cd Palpatine-master

sudo ./main.sh

rm -rf ~/master.zip ~/Palpatine-master
