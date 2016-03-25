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

# More explicit variable
SCRIPT=$0

###############################################################################
#                                 LOG & HELP                                  #
###############################################################################
usage() {
    # Usage  : usage
    # Input  : None
    # Output : None
    # Brief  : Print usage of this script to stdout
    cat <<- EOM
    Usage: ${SCRIPT} [OPTION]

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


verbose () {
    # Usage  : verbose <FUNCNAME>
    # Input  :
    #   $1-<FUNCNAME> : Function that call this
    # Output : None
    # Desc   : Verbose parsing to know witch log to print to stdout
    if [ "$#" -ne 1  ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
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
# End of verbose()

###############################################################################
#                              ALL USER CONFIG                                #
###############################################################################
full_update() {
    # Usage  : full_update
    # Input  : None
    # Output : None
    # Brief  : Update source, upgrade all package and upgrade distrib
    verbose ${FUNCNAME}
    sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
}
# End of full_update()

set_sudoers_rootpw() {
    # Usage  : set_sudoers_rootpw
    # Input  : None
    # Output : None
    # Brief  : 
    #   Change sudoer to ask root passwd instead of user one and make a backup
    #   of old sudoers file.
    verbose ${FUNCNAME}
    echo "Set sudo passwd to ask root password."
    ask_continue ${FUNCNAME}
    if [[ $yn == [Yy] ]]
    then
      echo "First change root password to avoid problems"
      su root -c "passwd"
      sudo sed -i.bak -e "\$aDefaults rootpw" /etc/sudoers
    fi
}
# End of set_sudoers_rootpw()

add_repo_awesome3.5() {
    # Usage  : add_repo_awesome3.5
    # Input  : None
    # Output : None
    # Brief  : Add ppa for awesome 3.5 on ubuntu 14.04
    verbose ${FUNCNAME}
    echo "Add ppa for awesome-3.5"
    ask_continue ${FUNCNAME}
    if [[ $yn == [Yy] ]]
    then
        sudo add-apt-repository ppa:klaus-vormweg/awesome
        sudo apt-get update
    else 
        AWESOME_WM=false
    fi
}
# End of add_repo_awesome3.5

install_base_pkg() {
    # Usage  : install_base_pkg
    # Input  : None
    # Output : None
    # Brief  : Instal minimal usefull soft
    verbose ${FUNCNAME}
    sudo apt-get install \
        apt-transport-https
    if $AWESOME_WM
    then
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
          terminator \
	  tree
    else
        sudo apt-get install \
          vim \
          git \
          mr \
          vcsh \
          zsh \
          keychain \
          xclip \
          terminator \
	      tree
    fi
}
# End of install_base_pkg

setup_distrib()
{
  full_update
  set_sudoers_rootpw
  add_repo_awesome3.5
  install_base_pkg
}
# Enf of setup_distrib()


###############################################################################
#                           USER SPECIFIC CONFIG                              #
###############################################################################
set_user_pwd() {
    # Usage  : set_user_pwd <USER>
    # Input  : 
    #   $1-<USER> : User account name 
    # Output : None
    # Brief  : Ask new password for <USER>
    if [ "$#" -ne 1  ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
        verbose ${FUNCNAME}
        echo "Please change $1 password."
        ask_continue ${FUNCNAME}
        if [[ $yn == [Yy] ]]
        then
            su $1 -c 'passwd'
        fi
    fi
}
# End of set_user_pwd()

setup_git_config() {
    # Usage  : setup_git_config <USER> <USER_FNAME> <USER_LNAME> <USER_MAIL>
    # Input  : 
    #   $1-<USER>       : User account name 
    #   $2-<USER_FNAME> : User first name
    #   $3-<USER_LNAME> : User last name
    #   $4-<USER_MAIL>  : User email
    # Output : None
    # Brief  : Set  git config globally for <USER>
    if [ "$#" -ne 4  ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
        verbose ${FUNCNAME}
        echo "Set user $1 git config."
        ask_continue  ${FUNCNAME}
        if [[ $yn == [Yy] ]]
        then 
            su $1 -c "git config --global user.name '$2 $3'"
            su $1 -c "git config --global user.email '$4'"
            su $1 -c "git config --global push.default matching"
        fi
    fi
}
# End of setup_git_config

generate_ssh_key () {
    # Usage  : generate_ssh_key <USER> <USER_MAIL>
    # Input  : 
    #   $1-<USER>       : User account name 
    #   $2-<USER_MAIL>  : User email
    # Output : None
    # Brief  : Setup ssh key for <USER>
    if [ "$#" -ne 2  ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
        verbose ${FUNCNAME}
        echo "Generate ssh key for user $1"
        ask_continue ${FUNCNAME}
        if [[ $yn == [Yy] ]]
        then 
            su $1 -c "ssh-keygen -t rsa -b 4096 -C '$2'"
            # Add  key to ssh-agent
            su $1 -c "eval '$(ssh-agent -s)'"
            su $1 -c "ssh-add ~/.ssh/id_rsa"
            su $1 -c "cat ~/.ssh/id_rsa.pub"
            echo "Above is the content of $1 public ssh key"
            echo "Please copy it and put them into your account (github,...)"
            ask_continue ${FUNCNAME}
        fi
    fi
}
# End of setup_git_config

clone_dotfiles() {
    # Usage : clone_dotfile <USER> <DOTFILE_LOC>
    # Input  : 
    #   $1-<USER>         : User account name 
    #   $2-<DOTFILE_LOC>  : Location of dotfiles of the form git@ or https://
    # Output : None
    # Brief  : Get dotfiles from server <USER>
    if [ "$#" -ne 2 ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
        verbose ${FUNCNAME}
        echo "Get dotfiles from $2."
        ask_continue ${FUNCNAME}
        if [[ $yn == [Yy] ]]
        then 
          su $1 -c "vcsh clone $2"
          su $1 -c "mkdir ~/.log"
          su $1 -c "mr up"
        fi
    fi
}
# End of clone_dotfiles()

# Change shell
chg_shell() {
    # Usage : chg_shell <USER>
    # Input  : 
    #   $1-<USER>       : User account name 
    # Output : None
    # Brief  : Change shell for <USER>
    if [ "$#" -ne 1 ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
        verbose ${FUNCNAME}
        echo "Change shell for user $1"
        ask_continue ${FUNCNAME}
        if [[ $yn == [Yy] ]]
        then 
            su $1 -c "chsh -s /bin/zsh"
        fi
    fi
}
# End of chg_shell()

setup_user() {
    # Usage  : setup_user <USER> <USER_FNAME> <USER_LNAME> <USER_MAIL> <DOTFILE_LOC>
    # Input  : 
    #   $1-<USER>       : User account name 
    #   $2-<USER_FNAME> : User first name
    #   $3-<USER_LNAME> : User last name
    #   $4-<USER_MAIL>  : User email
    #   $5-<DOTFILE_LOC>  : Location of dotfiles of the form git@ or https://
    # Output : None
    # Brief  : Do all user specific configuration
    DEFAULT_YN="Y"
    echo "Does this informations are correct : [y/n] "
    echo " User account name : $1 "
    echo " User full name    : $2 $3 "
    echo " User email        : $4"
    echo " Dotfiles location : $5"
    read yn
    yn=${yn:-$DEFAULT_YN}

    if [[ $yn == [Yy] ]]
    then 
        if id -u "$1" >/dev/null 2>&1
        then
            echo "User $1 exists, will not be created"
            ask_continue ${FUNCNAME}
        else
            echo "User $1 does not exist, will be created"
            ask_continue ${FUNCNAME}
            if [[ $yn == [Yy] ]]
            then
                adduser $1
            fi
        fi

        if [[ $yn == [Yy] ]]
        then
            set_user_pwd $1
            setup_git_config $1 $2 $3 $4 
            generate_ssh_key $1 $4
            clone_dotfiles $1 $5
            chg_shell $1
        fi
    else
        echo "Please do review config file."
        return
    fi
}
# End of setup_user


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

###############################################################################
#                                   MAIN                                      #
###############################################################################

setup_distrib

NB_USER=${#USER_ACCOUNT[@]}
for (( i=0; i<${NB_USER}; i++ ))
do
    setup_user ${USER_ACCOUNT[$i]} ${USER_FNAME[$i]} ${USER_LNAME[$i]} ${USER_MAIL[$i]} ${DOTFILE_LOC[$i]}
done
