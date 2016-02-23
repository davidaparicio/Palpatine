#!/bin/bash

# Import variable
if [ -e config.sh ]
then
    source config.sh
else
    echo "ERROR : config.sh does not exist !!"
    echo "Please copy config-sample.sh to config.sh with your own value."
    exit
fi

# Import functions
source ../function/ask_continue.sh

# Boolean for verbose
VERBOSE=false
VERBOSE_STEP=false
# Usefull variable
SCRIPT=$0


usage() {
    # Usage  : usage
    # Input  : None
    # Output : None
    # Brief  : Print usage of this script to stdout
    cat <<- EOM
    Usage: ${SCRIPT} [OPTION]"

    Available option :
        -v : Verbose level 1. Only print current function called
        -s : Verbose lvl 1 and step-by-step. Will ask user to continue or not
        -h : Help. Just print this help.

    Example :
        ${SCRIPT} -h
        Print this help
        ${SCRIPT} -vs
        Print multiple verbose
EOM
}

# Verbose parsing to know witch output to print
verbose () {
    # Usage  : verbose <FUNCNAME>
    # Input  :
    #   $1-<FUNCNAME> : Function that call this
    # Output : None
    # Desc   : Print log to stdout
    if [ "$#" -ne 1  ]
    then
        echo "[WARNING] - Calling $0 without argument"
    else
        if [[ ${VERBOSE} == true ]]
        then
            echo "[LOG] Running $1"
        elif [[ ${VERBOSE_STEP} == true ]]
        then
            echo "[LOG] Running $1"
            ask_continue $1
        fi
    fi
}

# Update Distrib and package
full_update() {
    # Usage  : full_update
    # Input  : None
    # Output : None
    # Brief  : Update source, upgrade all package and upgrade distrib
    if [ "$#" -ne 1  ]
    then
    verbose ${FUNCNAME}
    sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
}

# Ask to change root password
set_user_pwd() {
    # Usage  : set_user_pwd <USER>
    verbose ${FUNCNAME}
    echo "Please change root password."
    ask_continue $1
    su -c 'passwd'
}

# Change sudoer to ask root passwd instead of user one
set_sudoers_rootpw() {
  verbose ${FUNCNAME}
  sudo sed -i.bak -e "\$aDefaults rootpw" /etc/sudoers
}

# Add ppa for awesome 3.5 on ubuntu 14.04
add_repo_awesome3-5() {
  verbose ${FUNCNAME}
  sudo add-apt-repository ppa:klaus-vormweg/awesome
  sudo apt-get update
}

#Setup usefull littlelittle soft
install_base_pkg() {
  verbose ${FUNCNAME}
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

# Add git config
setup_git_config() {
    verbose ${FUNCNAME}
    # Usage : setup_git_config <USER> 
    su $1 -c "git config --global user.name '${USER_FNAME} ${USER_LNAME}'"
    su $1 -c "git config --global user.email '${USER_MAIL}'"
    su $1 -c "git config --global push.default matching"
}

# Generate Keygen 
generate_ssh_key () {
    verbose ${FUNCNAME}
    # Usage : generate_ssh_key <USER>
    su $1 -c "ssh-keygen -t rsa -b 4096 -C '$USER_MAIL'"
    # Add  key to ssh-agent
    su $1 -c "eval '$(ssh-agent -s)'"
    su $1 -c "sh-add ~/.ssh/id_rsa"
    # Copy public key to put it into account (gitlab, github, bitbucket ...)
    su $1 -c "xclip -sel clip < ~/.ssh/id_rsa.pub"

    echo "The content of your public ssh key is stored into your clipboard"
    echo "Please put them into your account (github, gitlab, bitbucket ...)"
    ask_continue ${FUNCNAME}
}

# Get back your dotfile
clone_dotfiles() {
    # Usage : clone_dotfile <USER>
    verbose ${FUNCNAME}
    su $1 -c "vcsh clone git@bitbucket.org:vcsh/mr.git"
    su $1 -c "mkdir ~/.log"
    su $1 -c "mr up"
}

# Change shell
chg_shell () {
     verbose ${FUNCNAME}
     su $1 -c "chsh -s /bin/zsh"
}


# Argument parser
while getopts ":vsh" opt; do
  case ${opt} in
    v)
      if [[ ${VERBOSE_STEP} == false ]]  
      then
        VERBOSE=true 
      fi
      ;;
    s)
      if [[ ${VERBOSE} == true ]]
      then
       VERBOSE=false
      fi 
      VERBOSE_STEP=true
      ;;
    h)
      usage
  esac
done
