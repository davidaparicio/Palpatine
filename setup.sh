#!/bin/bash
#
# Author : Romain Deville
#
#

cd ~/
wget https://github.com/RDeville/Palpatine/archive/master.zip
unzip master.zip
cd palpatine-master.zip
sudo ./main.sh
rm -rf palpatine-master.zip
