#!/bin/bash

# Import variable
source config.sh

# Import functions
source ../function/ask_continue.sh

VERBOSE=false
VERBOSE_STEP=false

# Argument parser
while getopts ":vs" opt; do
  case $opt in 
    v)
      if [[ $VERBOSE_STEP == false ]]  
      then
        VERBOSE=true 
      fi
      ;;
    s)
      if [[ $VERBOSE == true ]]
      then
       VERBOSE=false
      fi 
      VERBOSE_STEP=true
      ;;
  esac 
done

# Verbose traclog
verbose_info() {
    echo "[LOG] Running $1"
}

verbose_step() {
    verbose_info $1
    ask_continue $1
}

verbose () {
  echo $1 
  if [[ $VERBOSE == true ]]
  then
    verbose_info $1
  elif [[ $VERBOSE_STEP == true ]]
  then
    verbose_step $1
  fi
}
#Update Distrib
full_update() {
  verbose $FUNCNAME
  sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
}

# Ask to change root password
set_root_pwd() {
  verbose $FUNCNAME
  echo "Please change root password."
  ask_continue $1
  su -c 'passwd'
}
 
# Change sudoer to ask root passwd instead of user one
set_sudoers_rootpw() {
  verbose $FUNCNAME
  sudo sed -i.bak -e "\$aDefaults rootpw" /etc/sudoers
}

# Add ppa for awesome 3.5 on ubuntu 14.04
add_repo_awesome3-5() {
  verbose $FUNCNAME
  sudo add-apt-repository ppa:klaus-vormweg/awesome
  sudo apt-get update
}

#Setup usefull littlelittle soft
install_base_pkg() {
  verbose $FUNCNAME
  sudo apt-get install \
    vim \
    git \
    mr \
    vcsh \
    zsh \
    keychain \
    xclip \
    awesome \
    awesome-extra \
    terminator
}

echo $VERBOSE
echo $VERBOSE_STEP
install_base_pkg


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
