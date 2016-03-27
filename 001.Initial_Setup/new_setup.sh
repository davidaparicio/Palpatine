#!/bin/bash

# FROM RASPI-CONFIG
INTERACTIVE=True
ASK_TO_REBOOT=0
BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
CONFIG=/boot/config.txt

# FROM RASPI-CONFIG
is_pione() {
   if grep -q "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo; then
      return 0
   elif  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo ; then
      return 0
   else
      return 1
   fi
}

# FROM RASPI-CONFIG
is_pitwo() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

# FROM RASPI-CONFIG
is_pizero() {
   grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]09[0-9a-fA-F]$" /proc/cpuinfo
   return $?
}

# FROM RASPI-CONFIG
get_pi_type() {
   if is_pione; then
      echo 1
   elif is_pitwo; then
      echo 2
   else
      echo 0
   fi
}

# FROM RASPI-CONFIG
get_init_sys() {
  if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
    SYSTEMD=1
  elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
    SYSTEMD=0
  else
    echo "Unrecognised init system"
    return 1
  fi
}

# FROM RASPI-CONFIG
calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error
  # output from tput. However in this case, tput detects neither stdout or
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]
  then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]
  then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

# FROM RASPI-CONFIG
expand_rootfs() {
  get_init_sys
  if [ $SYSTEMD -eq 1 ]; then
    ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
  else
    if ! [ -h /dev/root ]; then
      whiptail --msgbox "/dev/root does not exist or is not a symlink. Don't know how to expand" 20 60 2
      return 0
    fi
    ROOT_PART=$(readlink /dev/root)
  fi

  PART_NUM=${ROOT_PART#mmcblk0p}
  if [ "$PART_NUM" = "$ROOT_PART" ]; then
    whiptail --msgbox "$ROOT_PART is not an SD card. Don't know how to expand" 20 60 2
    return 0
  fi

  # NOTE: the NOOBS partition layout confuses parted. For now, let's only
  # agree to work with a sufficiently simple partition layout
  if [ "$PART_NUM" -ne 2 ]; then
    whiptail --msgbox "Your partition layout is not currently supported by this tool. You are probably using NOOBS, in which case your root filesystem is already expanded anyway." 20 60 2
    return 0
  fi

  LAST_PART_NUM=$(parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)
  if [ $LAST_PART_NUM -ne $PART_NUM ]; then
    whiptail --msgbox "$ROOT_PART is not the last partition. Don't know how to expand" 20 60 2
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF
  ASK_TO_REBOOT=1

  # now set up an init.d script
cat <<EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/$ROOT_PART &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
  chmod +x /etc/init.d/resize2fs_once &&
  update-rc.d resize2fs_once defaults &&
  if [ "$INTERACTIVE" = True ]; then
    whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" 20 60 2
  fi
}


# FROM RASPI-CONFIG
config_keyboard() {
  dpkg-reconfigure keyboard-configuration &&
  printf "Reloading keymap. This may take a short while\n" &&
  invoke-rc.d keyboard-setup start || return $?
  udevadm trigger --subsystem-match=input --action=change
  return 0
}

# FROM RASPI-CONFIG
chg_locale() {
  dpkg-reconfigure locales
}

# FROM RASPI-CONFIG
chg_timezone() {
  dpkg-reconfigure tzdata
}

# PART FROM RASPI-CONFIG
chg_usr_pwd () {
	# Usage : chg_usr_pwd <USER>
    # Input  :
    #   $1-<USER>       : User account name
    # Output : None
    # Brief  : Change password for <USER>
	if [ "$#" -ne 1 ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
    	local USR=$1
		whiptail --msgbox "You will now be asked to enter a new password for the user : ${USR} " 20 60 1
  		passwd ${USR} &&
  			whiptail --msgbox "Password changed successfully" 20 60 1 :
  			whiptail --msgbox "Failed to change password" 20 60 1
  	fi
}

update_sudoer () {
	# Usage  : update_sudoer
    # Input  : None
    # Output : None
    # Brief  :
    #   Ask if change sudoer to ask root passwd instead of first user and make a backup
    #   of old sudoers file.
    if ( whiptail --title "Update sudoer file" --yesno "\
    Do you want to add the following line to sudoer ? \n \n\
    		\"Defaults rootpw\" \n \n\
	This will make OS to ask root password when using sudo instead of user password." 20 60  )
    then
    	sudo sed -i.bak -e "\$aDefaults rootpw" /etc/sudoers
    	return 0
    else
    	return 1
    fi
}

ask_arch () {
	# Usage  : ask_arch
    # Input  : None
    # Output : None
    # Brief  :
    #   Ask if arch is the right one, and if arch is RPi, ask if user want to expand rootfs
    ARCH=$( arch )
    if echo ${ARCH} | grep "arm"
    then
    	if ( whiptail --title "Setup RPi" --yesno "\
			It seems you are on an arm machine. \n \
			Is it a raspberry ? " 20 60 )
    	then
    		ARCH="RPI"
    		if ( whiptail --title "Setup RPi" --yesno "\
				Do you want to expand rootfs ? \n"  20 60 )
    		then
	    		expand_rootfs
    		fi
    	else
    		ARCH="ARM"
    	fi
    elif [[ "${ARCH}" == "x86_64" ]]
    then
    	if ( whiptail --title "Setup Archictecture" --yesno "\
			It seems you are on an ${ARCH} machine. \n\
			Is it alright ? "  20 60 )
    	then
    		ARCH="x86-64"
    	else
    		ARCH="Unknown_x86_64"
    	fi
   	# TODO : Add other arch
    fi
}


fullupdate () {
	# Usage  : setup_base
    # Input  : None
    # Output : None
    # Brief  :
    #   Do a fullupdate of the system.
    whiptail --title "Update Repo and Upgrade" --msgbox "\
    This script will now update and upgrade the system" 20 60
    # TODO : Manage multiple system
    apt-get update && apt-get upgrade && apt-get dist-upgrade
}

setup_base_pkg () {
	# Usage  : setup_all_pkg
    # Input  : None
    # Output : None
    # Brief  :
    # 	Install multiple utility for later
    whiptail --title "Setup Base Package" --msgbox "\
    This script will now install the following packages : \n\
    	- apt-transport-https \n\
    	- software-properties-common \n\
    	- python-software-properties \n" 20 60
    # TODO : Manage multiple system
    apt-get install -y apt-transport-https software-properties-common python-software-properties
}

setup_ask_pkg () {
	# Usage  : setup_all_pkg
  # Input  : None
  # Output : None
  # Brief  :
  # 	Menu to ssk user which package he wants to install
  calc_wt_size
  source menu_function.sh
	FUN=$(whiptail --title "Package to setup" --menu "Whatever the choice to make, \
		you will be able to come back to this menu before running the setup. \n\
		Do you whant to :" \
		$WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --ok-button Select \
		"1 Go through" "Let the script go through all categories of programm to setup." \
		"2 Choose" "Choose the categorie of programs you want to setup." \
		"3 Direct setup" "Setup my minimalistic apps." \
		3>&1 1>&2 2>&3)
	RET=$?
  if [ $RET -eq 1 ]; then
  	exit 1
    	table_of_content # TODO : Code this function
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) setup_ask_go_through ;;
      2\ *) setup_ask_categories ;;
      3\ *) setup_direct_finish ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || RET=$?
      if [ $RET -eq 2 ]; then
        return 2
      fi
  else
    exit 1
  fi
}

setup_all_pkg() {
	# Usage  : setup_all_pkg
    # Input  : None
    # Output : None
    # Brief  :
    # 	Call function multiple function that update

	fullupdate
	setup_base_pkg
	setup_ask_pkg
}

set_user_pwd() {
    # Usage  : set_user_pwd <USER>
    # Input  :
    #   $1-<USER> : User account name
    # Output : None
    # Brief  : Ask new password for <USER>
    if [ "$#" -ne 1  ]
    then
        echo "[WARNING]-Calling ${FUNCNAME} without the right number of argument"
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
        echo "[WARNING]-Calling ${FUNCNAME} without the right number of argument"
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
    local USER=$1

    local MAIL_OK=false
    while ! ${PASSWORD_OK}
    do
      local EMAIL1=$(whiptail --title "SSH Key" --passwordbox "Email adress of the user  " 8 78   3>&1 1>&2 2>&3)
      RET=$?
      if [[ ${RET} == 1 ]]
      then
        return 1
      fi

      # REGEX PASSWORD
      #^([a-zA-Z0-9@*#_]{8,15})$
      #Description
      #Password matching expression.
      #Match all alphanumeric character and predefined wild characters.
      #Password must consists of at least 8 characters and not more than 15 characters.
      if [[ ! "${EMAIL1}" =~ ^([a-zA-Z0-9@*#]{8,15})$ ]]
      then
        whiptail --title "Add Users" --msgbox "This is not an email adresse. Please enter one of the form : \n\
        email.example@domain.com " 8 78   3>&1 1>&2 2>&3
      else
        local EMAIL2=$(whiptail --title "Add Users" --passwordbox "Please enter the email adress again  " 8 78   3>&1 1>&2 2>&3)
        RET=$?
        if [[ ${RET} == 1 ]]
        then
          return 1
        fi
        if [[ ! ${EMAIL1} == ${EMAIL2} ]]
        then
          whiptail --title "Add Users" --msgbox "Emails do not match" 8 78   3>&1 1>&2 2>&3
        else
          EMAIL_OK=true
        fi
      fi
    done
    su $1 -c "ssh-keygen -t rsa -b 4096 -C '$2'"
    # Add  key to ssh-agent
    su $1 -c "eval '$(ssh-agent -s)'"
    su $1 -c "ssh-add ~/.ssh/id_rsa"
    su $1 -c "cat ~/.ssh/id_rsa.pub"
            echo "Above is the content of $1 public ssh key"
            echo "Please copy it and put them into your account (github,...)"
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
        echo "[WARNING]-Calling ${FUNCNAME} without the right number of argument"
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
        echo "[WARNING]-Calling ${FUNCNAME} without the right number of argument"
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

update_user () {
  calc_wt_size
  local FULL_NAME[0]=$( getent passwd root | cut -d: -f5 | cut -d, -f1 )
  local USERNAME[0]=$( getent passwd root | cut -d: -f1 )
  idx=1
  for i in /home/*
  do
    if ! echo ${i} | grep -q "lost+found"
    then
      USER=${i##*/}
      FULL_NAME[${idx}]=$( getent passwd ${USER} | cut -d: -f5 | cut -d, -f1 )
      USERNAME[${idx}]=$( getent passwd ${USER} | cut -d: -f1 )
      idx=$(( $idx + 1 ))
    fi
  done
  local NB_USER=${#USERNAME[@]}

  local MENU_USER="whiptail --title 'Update User' --menu  'Select which user informations you want to update :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=0 ; idx <= ${NB_USER}-1 ; idx++ ))
  do
    MENU_USER="${MENU_USER} '${USERNAME[${idx}]}' '${FULL_NAME[${idx}]}'"
  done

  bash -c "${MENU_USER} " 2> results_menu.txt
  RET=$?
  if [[ ${RET} == 1 ]]
  then
    return 1
  fi

  CHOICE=$( cat results_menu.txt )

  local EMAIL1="empty"

  if ( whiptail --title "Update User" --yesno "Do you want to change GECOS informations of user :  ${CHOICE}" 8 60 )
  then
    chfn ${CHOICE}
  fi

  if ( whiptail --title "Update User" --yesno "Do you want to change password user :  ${CHOICE}" 8 60 )
  then
    passwd ${CHOICE}
  fi

  if ( whiptail --title "Update User" --yesno "Do you want to set an email adress for user :  ${CHOICE} \n \
  If no, you will be ask email adress again when setting up git.) " 8 60 )
  then
    local MAIL_OK=false
    while ! ${MAIL_OK}
    do
      EMAIL1=$(whiptail --title "Update User" --passwordbox "Email adress of the user  " 8 78   3>&1 1>&2 2>&3)
      RET=$?
      if [[ ${RET} == 1 ]]
      then
        return 1
      fi

      # REGEX PASSWORD
      #^([a-zA-Z0-9@*#_]{8,15})$
      #Description
      #Password matching expression.
      #Match all alphanumeric character and predefined wild characters.
      #Password must consists of at least 8 characters and not more than 15 characters.
      if [[ ! "${EMAIL1}" =~ ^([a-zA-Z0-9@*#]{8,15})$ ]] # TODO : Update regex
      then
        whiptail --title "Add Users" --msgbox "This is not an email adresse. Please enter one of the form : \n\
        email.example@domain.com " 8 78   3>&1 1>&2 2>&3
      else
        local EMAIL2=$(whiptail --title "Add Users" --passwordbox "Please enter the email adress again  " 8 78   3>&1 1>&2 2>&3)
        RET=$?
        if [[ ${RET} == 1 ]]
        then
          return 1
        fi
        if [[ ! ${EMAIL1} == ${EMAIL2} ]]
        then
          whiptail --title "Add Users" --msgbox "Emails do not match" 8 78   3>&1 1>&2 2>&3
        else
          EMAIL_OK=true
        fi
      fi
    done
  fi

  if ( whiptail --title "Update User" --yesno "Do you want to set an ssh key for user (userfull for git) :  ${CHOICE}" 8 60 )
  then
    if [[ ${EMAIL1} == "empty" ]]
    then
      while ! ${MAIL_OK}
      do
        EMAIL1=$(whiptail --title "Update User" --passwordbox "Email adress of the user  " 8 78   3>&1 1>&2 2>&3)
        RET=$?
        if [[ ${RET} == 1 ]]
        then
          return 1
        fi

        # REGEX PASSWORD
        #^([a-zA-Z0-9@*#_]{8,15})$
        #Description
        #Password matching expression.
        #Match all alphanumeric character and predefined wild characters.
        #Password must consists of at least 8 characters and not more than 15 characters.
        if [[ ! "${EMAIL1}" =~ ^([a-zA-Z0-9@*#]{8,15})$ ]] # TODO : Update regex
        then
          whiptail --title "Add Users" --msgbox "This is not an email adresse. Please enter one of the form : \n\
          email.example@domain.com " 8 78   3>&1 1>&2 2>&3
        else
          local EMAIL2=$(whiptail --title "Add Users" --passwordbox "Please enter the email adress again  " 8 78   3>&1 1>&2 2>&3)
          RET=$?
          if [[ ${RET} == 1 ]]
          then
            return 1
          fi
          if [[ ! ${EMAIL1} == ${EMAIL2} ]]
          then
            whiptail --title "Add Users" --msgbox "Emails do not match" 8 78   3>&1 1>&2 2>&3
          else
            EMAIL_OK=true
          fi
        fi
      done
    generate_ssh_key ${CHOICE} ${EMAIL1}
  fi

  if type -t git &>/dev/null && ( whiptail --title "Update User" --yesno "Do you want set git informations for user  :  ${CHOICE}" 8 60 )
  then
    if [[ ${EMAIL1} == "empty" ]]
    then
      while ! ${MAIL_OK}
      do
        EMAIL1=$(whiptail --title "Update User" --passwordbox "Email adress of the user  " 8 78   3>&1 1>&2 2>&3)
        RET=$?
        if [[ ${RET} == 1 ]]
        then
          return 1
        fi

        # REGEX PASSWORD
        #^([a-zA-Z0-9@*#_]{8,15})$
        #Description
        #Password matching expression.
        #Match all alphanumeric character and predefined wild characters.
        #Password must consists of at least 8 characters and not more than 15 characters.
        if [[ ! "${EMAIL1}" =~ ^([a-zA-Z0-9@*#]{8,15})$ ]] # TODO : Update regex
        then
          whiptail --title "Add Users" --msgbox "This is not an email adresse. Please enter one of the form : \n\
          email.example@domain.com " 8 78   3>&1 1>&2 2>&3
        else
          local EMAIL2=$(whiptail --title "Add Users" --passwordbox "Please enter the email adress again  " 8 78   3>&1 1>&2 2>&3)
          RET=$?
          if [[ ${RET} == 1 ]]
          then
            return 1
          fi
          if [[ ! ${EMAIL1} == ${EMAIL2} ]]
          then
            whiptail --title "Add Users" --msgbox "Emails do not match" 8 78   3>&1 1>&2 2>&3
          else
            EMAIL_OK=true
          fi
        fi
      done
    fi
    local USER_FOUND=false
    local idx=0
    while ! ${USER_FOUND}
    do
      if [[ ${CHOICE} == ${USERNAME[${idx}]} ]]
      then
        setup_git_config ${USERNAME[${idx}]} ${FULL_NAME[${idx}]} ${EMAIL1}
      else
        echo "Programmer Error : User ${CHOICE} not found"
        read
      fi
      idx=$(( ${idx} + 1 ))
    done
  fi

  # TODO : Get dofiles from git and vcsh 
  local MENU_USER="whiptail --title 'Update user' --menu  'Select what you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MENU_USER="${MENU_USER} 'Update GECOS' 'Update GEOCS information such as Fullname, Room...'"
  MENU_USER="${MENU_USER} 'Change password' 'Change the password of the user'"
  MENU_USER="${MENU_USER} 'Set git info' 'Set some git information, such as mail, username, etc.'"
  MENU_USER="${MENU_USER} 'Set git dotfiles' 'Set dotfiles from a git repo'"
  MENU_USER="${MENU_USER} 'Set vcs/mr dotfiles' 'Set myRepos vcsh dotfile from a vcsh/ repo'"
}

add_user () {
  local USERNAME_OK=false
  while ! ${USERNAME_OK}
  do
    local USERNAME="whiptail --title 'Add Users' --inputbox 'Username for the new user (only lowerscript char) ' 8 78 "
    bash -c "${USERNAME}" 2>results_menu.txt
    RET=$?
    if [[ ${RET} == 1 ]]
    then
      return 1
    fi

    USERNAME=$( cat results_menu.txt )
    if [[ ${#USERNAME} == 0 ]]
    then
      whiptail --title "Add Users" --msgbox "Username must be at least one char long " 8 78   3>&1 1>&2 2>&3
    else
      getent passwd ${USERNAME} >/dev/null 2>&1 && RET=true
      if [[ ${RET} == true ]]
      then
        whiptail --title "Add Users" --msgbox "User already exist " 8 78   3>&1 1>&2 2>&3
      else
        USERNAME_OK=true
      fi
    fi
  done

  local FIRST_NAME=$(whiptail --title "Add Users" --inputbox "First name of the new user (you can leave it empty) " 8 78   3>&1 1>&2 2>&3)
  local LAST_NAME=$(whiptail --title "Add Users" --inputbox "Last name of the new user (you can leave it empty) " 8 78   3>&1 1>&2 2>&3)

  local PASSWORD_OK=false
  while ! ${PASSWORD_OK}
  do
    local PASSWORD1=$(whiptail --title "Add Users" --passwordbox "Password for the new user  " 8 78   3>&1 1>&2 2>&3)
    RET=$?
    if [[ ${RET} == 1 ]]
    then
      return 1
    fi

    # REGEX PASSWORD
    #^([a-zA-Z0-9@*#_]{8,15})$
    #Description
    #Password matching expression.
    #Match all alphanumeric character and predefined wild characters.
    #Password must consists of at least 8 characters and not more than 15 characters.
    if [[ ! "${PASSWORD1}" =~ ^([a-zA-Z0-9@*#]{8,15})$ ]]
    then
      whiptail --title "Add Users" --msgbox "Password must be at least eight char long and contains alphanumeric char and predefined wild characters " 8 78   3>&1 1>&2 2>&3
    else
      local PASSWORD2=$(whiptail --title "Add Users" --passwordbox "Please enter the password again  " 8 78   3>&1 1>&2 2>&3)
      RET=$?
      if [[ ${RET} == 1 ]]
      then
        return 1
      fi
      if [[ ! ${PASSWORD1} == ${PASSWORD2} ]]
      then
        whiptail --title "Add Users" --msgbox "Passwords do not match" 8 78   3>&1 1>&2 2>&3
      else
        PASSWORD_OK=true
      fi
    fi
  done

  if ( whiptail --title "Add User" --yesno "Does this user will have sudo abilities ? " 8 78   3>&1 1>&2 2>&3 )
  then
    SUDO=true
  else
    SUDO=false
  fi

  if ( whiptail --title "Add User" --yesno "Do you confirm following informations about new user : \n\
Username       : ${USERNAME} \n\
User Fullname  : ${FIRST_NAME} ${LAST_NAME}  \n\
Password        : The one you set
" 15 78   3>&1 1>&2 2>&3 )
  then
    if ${SUDO}
    then
      useradd -c "${FIRST_NAME} ${LAST_NAME}" -G "sudo" -m -p "'${PASSWORD1}'"  ${USERNAME}
    else
      useradd -c "${FIRST_NAME} ${LAST_NAME}" -m -p "'${PASSWORD1}'" ${USERNAME}
    fi
  else
    return 1
  fi
  return 2
}

delete_user () {
  calc_wt_size
  idx=0
  for i in /home/*
  do
    if ! echo ${i} | grep -q "lost+found"
    then
      USER=${i##*/}
      FULL_NAME[${idx}]=$( getent passwd ${USER} | cut -d: -f5 | cut -d, -f1 )
      USERNAME[${idx}]=$( getent passwd ${USER} | cut -d: -f1 )
      idx=$(( $idx + 1 ))
    fi
  done
  local NB_USER=${#USERNAME[@]}
  echo ${USERNAME[@]}
  echo $NB_USER
  read


  local MENU_USER="whiptail --title 'Delete User' --menu  'Select whihc user you want to delete :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=0 ; idx <= ${NB_USER}-1 ; idx++ ))
  do
    MENU_USER="${MENU_USER} '${USERNAME[${idx}]}' '${FULL_NAME[${idx}]}'"
  done

  echo $MENU_USER
  read


  bash -c "${MENU_USER} " 2> results_menu.txt
  RET=$?
  if [[ ${RET} == 1 ]]
  then
    return 1
  fi

  CHOICE=$( cat results_menu.txt )

  if ( whiptail --title "Update User" --yesno "Do you really want to delete user :  ${CHOICE}" 8 60 )
  then
    userdel ${CHOICE}
    mkdir -p /root/user.backup
    mv /home/${CHOICE} /root/user.backup/${CHOICE}
    return 2
  else
    return 1
  fi
}

config_user () {
  calc_wt_size
  local MENU_USER="whiptail --title 'User modification' --menu  'Select what you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MENU_USER="${MENU_USER} 'Update User' 'Update user information such as setting a git/vcsh dotfiles, name, mail etc.'"
  MENU_USER="${MENU_USER} 'Add User' 'Add a new user'"
  MENU_USER="${MENU_USER} 'Delete User' 'Delete an existing user'"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to the next step'"

  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} == 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    if [[ ${CHOICE} == "CONTINUE" ]]
    then
      return 2
    elif [[ ${CHOICE} == "Update User" ]]
    then
      update_user
    elif [[ ${CHOICE} == "Add User" ]]
    then
      add_user
      RET=$?
      if [[ ${RET} == 2 ]]
      then
        update_user
      fi
    elif [[ ${CHOICE} == "Delete User" ]]
    then
      delete_user
    fi
  done
}

#chg_usr_pwd "root"
#ask_arch
#chg_locale
#chg_timezone
#config_keyboard
#setup_all_pkg
config_user
