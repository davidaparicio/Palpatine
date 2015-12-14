#!/bin/bash

#Update Distrib
sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade

# Ask to change root password
echo "Please change root password."
echo "Enter following line : "
echo "   # passwd " 
echo "   # exit " 
read -p "Ready ? [Y/n]" yn  # TODO Verif_step

sudo su
 
# Change sudoer to ask root passwd instead of user one
sudo sed -i.bak -e "\$aDefaults rootpw" /etc/sudoers

# Add ppa for awesome 3.5 on ubuntu 14.04
sudo add-apt-repository ppa:klaus-vormweg/awesome
sudo apt-get update

#Setup usefull littlelittle soft
sudo apt-get install vim git mr vcsh zsh keychain xclip awesome awesome-extra terminator

# Add git config
git config --global user.name "Your Name"       #TODO Gene
git config --global user.email "your@email.com" #TODO Gen
git config --global push.default matching 

# Generate Keygen 
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" # TODO: Make mail variable

# Add  key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Copy public key to put it into account (gitlab, github, bitbucket ...)
xclip -sel clip < ~/.ssh/id_rsa.pub

echo "The content of your public ssh key is stored into your clipboard"
echo "Please put them into your account (github, gitlab, bitbucket ...)"
read -p "Done ? [Y/n]" yn #TODO : Verfif_step

# Then get back your dotfile

vcsh clone git@bitbucket.org:vcsh/mr.git 
vcsh mr remote rename origin bitbucket.vcsh

mkdir ~/.log #TODO GENE
mr up

chsh -s /bin/zsh
