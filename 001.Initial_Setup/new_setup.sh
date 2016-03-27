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

###############################################################################
# SETUP USER UPDATE MAIL PART
###############################################################################
setup_user_update_mail_ssh_key () {
  local USER=$1
  local EMAIL1=$2

  local MAIL_OK=false
  if [[ ${EMAIL1} == "empty" ]]
  then
    ask_email
  fi
  whiptail --title "SSH Key ${USER}" --msgbox "You will now be ask some informations to create your ssh key. First enter ${USER} password}" 8 60
  su ${USER} -c "ssh-keygen -t rsa -b 4096 -C '${EMAIL1}'"
  # Add  key to ssh-agent
  su ${USER} -c "eval '$(ssh-agent -s)'"
  whiptail --title "SSH Key ${CHOICE}" --msgbox 'You will now be ask your ssh key password' 8 60
  su ${USER} -c "ssh-add ~/.ssh/id_rsa"

  echo "Here is the content of your ssh key : \n\n\
  Please copy it and past it into your version control system (github, bitbucket, gitlab...) \n\n\
  BE WARNED THAT IF YOU DON'T DO IT, FOLLOWING STEP MIGHT NOT BE WORKING"
  su ${USER} -c "cat ~/.ssh/id_rsa.pub"
  return 2
}

setup_user_update_git_config() {
  local USERNAME=$1
  local FULLNAME=$2

  if ( whiptail --title "Update ${USERNAME}" --yesno "Script will now running following command : \n\
      - su $1 -c 'git config --global user.name '${FULLNAME}' \n\
      local EMAIL=$3
      - su $1 -c 'git config --global user.email '${EMAIL1}'  \n\
      - su $1 -c 'git config --global push.default matching " 10 80)
  then
    su $1 -c "git config --global user.name '${FULLNAME}'"
    su $1 -c "git config --global user.email '${EMAIL1}'"
    su $1 -c "git config --global push.default matching"
  else
    return 1
  fi
  return 2
}

setup_user_update_mail_git_dotfiles () {
  # TODO
  echo
}

setup_user_update_mail_vcsh_dotfiles () {
  local VCSH_MR_REPO_OK=false
  local VCSH_MR_REPO=""
  while ! ${VCSH_MR_REPO_OK}
  do
    VCSH_MR_REPO=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter myRepos address to clone via vcsh" 8 60  3>&1 1>&2 2>&3)
    if [[ ${#VCSH_MR_REPO}  > 0 ]] && ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Are you sure this is the right adress ? \n\
    ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
    then
      vcsh clone ${VCSH_MR_REPO}
      mr up
      if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Does everything work ? ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
      then
        VCSH_MR_REPO_OK=true
      fi
    fi

    if ! ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to retry ? ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
    then
      VCSH_MR_REPO_OK=true
    fi
  done
}

setup_user_update_mail_cmd_dotfiles () {
  local CMD_OK=""
  while ! ${CMD_OK}
  do
    CMD=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter command in one line format if you can. \n\
If you can't, you can create a script in your git repo or accessible with wget and run a command like : \n\n\
'wget -O - http://link.to/your_script.sh | bash' " 10 80  3>&1 1>&2 2>&3)
    if [[ ${#CMD}  > 0 ]] && ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Are you sure this is the right adress ? \n\
    ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
    then
      ${CMD}
      if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Does everything work ? ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
      then
        CMD_OK=true
      fi
    fi

    if ! ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to retry ? ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
    then
      CMD_OK=true
    fi
  done
}

setup_user_update_mail_ask () {
 local MAIL_OK=false
 local EMAIL_REGEX="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

 while ! ${MAIL_OK}
 do
   EMAIL1=$(whiptail --title "Update ${CHOICE}" --inputbox "Email adress of the user  " 8 78   3>&1 1>&2 2>&3)
   RET=$?
   if [[ ${RET} -eq 1 ]]
   then
     return 1
   fi

   if [[ ! ${EMAIL1} =~ ${EMAIL_REGEX} ]]
   then
     whiptail --title "Update ${CHOICE}" --msgbox "This is not an email adresse. Please enter one of the form : \n\
     email.example@domain.com " 8 78   3>&1 1>&2 2>&3
   else
     local EMAIL2=$(whiptail --title "Update ${CHOICE}" --inputbox "Please enter the email adress again  " 8 78   3>&1 1>&2 2>&3)
     RET=$?
     if [[ ${RET} -eq 1 ]]
     then
       return 1
     fi
     if [[ ! ${EMAIL1} == ${EMAIL2} ]]
     then
       whiptail --title "Update  ${CHOICE}" --msgbox "Emails do not match" 8 78   3>&1 1>&2 2>&3
     else
       return 2
     fi
   fi
 done
}

###############################################################################
# SETUP USERR UPDATE PART
###############################################################################
setup_user_update_gecos () {
  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to change GECOS informations of user :  ${USER_CHOOSEN}" 8 60 )
  then
    chfn ${USER_CHOOSEN}
  else
    return 1
  fi
}

setup_user_update_chg_passwd () {
  if ( whiptail --title "Update ${USER_CHOOSEN}r" --yesno "Do you want to change password user :  ${USER_CHOOSEN}" 8 60 )
  then
    passwd ${USER_CHOOSEN}
  else
    return 1
  fi
}

setup_user_update_chg_shell () {
  if ( whiptail --title "Update ${USER_CHOOSEN}r" --yesno "Do you want to change shell for user :  ${USER_CHOOSEN}" 8 60 )
  then
    su $1 -c "chsh -s /bin/zsh"
  else
    return 1
  fi
}

setup_user_update_set_email () {
  local EMAIL1="empty"

  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to enter the email adress for user :  ${USER_CHOOSEN} \n \
  If no, Following step will not be launch \n\
    - Generating SSH Key \n\
    - Setup git user information \n\
    - Setup dotfiles repos from git \n\
    - Setup dotfiles with vcsh and myRepos " 12 60 )
  then
    setup_user_update_mail_ask
  else
    return 1
  fi

  local MENU_USER="whiptail --title 'Update ${USER_CHOOSEN}' --menu  'Select action :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MENU_USER="${MENU_USER} 'SSH Key' 'Generate or update ssh key of the user ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Git information' 'Update git information of the user ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Git dotfiles' 'Get dotfiles from a git repo'"
  MENU_USER="${MENU_USER} 'Vcsh and mr dotfiles' 'Get myRepos config via vcsh from a git repo'"
  MENU_USER="${MENU_USER} 'Command dotfiles' 'Get dotfiles from a one line command '"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 2
      ;;
      "SSH Key" )
        setup_user_update_mail_ssh_key ${USER_CHOOSEN} ${EMAIL1}
      ;;
      "Git information" )
        local USER_FOUND=false
        local idx=0
        while ! ${USER_FOUND}
        do
          if echo ${USER_CHOOSEN} | grep -q  ${USERNAME[${idx}]}
          then
            setup_user_update_mail_git_config ${USERNAME[${idx}]} ${FULL_NAME[${idx}]} ${EMAIL1}
            USER_FOUND=true
          else
            echo "Programmer Error : User ${USER_CHOOSEN} not found"
            read
          fi
          idx=$(( ${idx} + 1 ))
        done
      ;;
      "Git dotfiles" )
        setup_user_update_mail_git_dotfiles
      ;;
      "Vcsh and mr dotfiles" )
        setup_user_update_mail_vcsh_dotfiles
      ;;
      "Command dotfiles" )
        setup_user_update_mail_cmd_dotfiles
      ;;
    esac
  done
}

setup_user_update_go_through () {
  setup_user_update_gecos
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi

  setup_user_update_chg_passwd
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi

  setup_user_update_chg_shell
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi

  setup_user_update_set_email
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi
  return 2
}

setup_user_update_loop () {
  local MENU_USER="whiptail --title 'Update user' --menu  'Select what you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MENU_USER="${MENU_USER} 'Update GECOS' 'Update GEOCS information such as Fullname, Room...'"
  MENU_USER="${MENU_USER} 'Change password' 'Change the password of the ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Change shell' 'Change the shell of the ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Set email' 'Set email and continue with ssh key and dotfiles'"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 2
      ;;
      "Update GECOS" )
        setup_user_update_gecos
      ;;
      "Change password" )
        setup_user_update_chg_passwd
      ;;
      "Change shell" )
        setup_user_update_chg_shell
      ;;
      "Set email" )
        setup_user_update_set_email
      ;;
    esac
  done
}

setup_user_update_select () {
  FULL_NAME[0]=$( getent passwd root | cut -d: -f5 | cut -d, -f1 )
  USERNAME[0]=$( getent passwd root | cut -d: -f1 )
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
  NB_USER=${#USERNAME[@]}

  local MENU_USER="whiptail --title 'Update User' --menu  'Select which user informations you want to update :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=0 ; idx <= ${NB_USER}-1 ; idx++ ))
  do
    MENU_USER="${MENU_USER} '${USERNAME[${idx}]}' '${FULL_NAME[${idx}]}'"
  done

  bash -c "${MENU_USER} " 2> results_menu.txt
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi

  CHOICE=$( cat results_menu.txt )
}

###############################################################################
# SETUP USERR CONFIG PART
###############################################################################
setup_user_update () {
  local FULL_NAME
  local USERNAME
  local NB_USER
  local USER_CHOOSEN

  setup_user_update_select

  USER_CHOOSEN=${CHOICE}

  local MENU_USER="whiptail --title 'Update user' --menu  'Select how you want to manage user update :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MENU_USER="${MENU_USER} 'Go though' 'Let the script go through all actions'"
  MENU_USER="${MENU_USER} 'Choose action' 'Let you choose what you want to update'"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
     "CONTINUE" )
      return 2
     ;;
    "Go through" )
      setup_user_update_go_through
      RET=$?
      if [[ ${RET} -eq 1 ]]
      then
        setup_user_update_loop
      elif [[ ${RET} -eq 2 ]]
      then
        return 2
      fi
    ;;
    "Choose action" )
      setup_user_update_loop
      RET=$?
      return ${RET}
    ;;
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      return 1
    ;;
    esac
  done
}

setup_user_add () {
  local USERNAME_OK=false
  while ! ${USERNAME_OK}
  do
    local USERNAME="whiptail --title 'Add Users' --inputbox 'Username for the new user (only lowerscript char) ' 8 78 "
    bash -c "${USERNAME}" 2>results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
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
    if [[ ${RET} -eq 1 ]]
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
      if [[ ${RET} -eq 1 ]]
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
  return 0
}

setup_user_delete () {
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
  if [[ ${RET} -eq 1 ]]
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

###############################################################################
# SETUP INSTALL PACKAGE PART
###############################################################################
setup_pkg_fullupdate () {
  whiptail --title "Update Repo and Upgrade" --msgbox "\
  This script will now update and upgrade the system" 20 60
  # TODO : Manage multiple system
  apt-get update && apt-get upgrade && apt-get dist-upgrade
}

setup_pkg_base () {
  whiptail --title "Setup Base Package" --msgbox "\
  This script will now install the following packages : \n\
  	- apt-transport-https \n\
  	- software-properties-common \n\
  	- python-software-properties \n" 20 60
  # TODO : Manage multiple system
  apt-get install -y apt-transport-https software-properties-common python-software-properties
}

setup_pkg_ask () {
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
  	return 1
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
    return 1
  fi
}

###############################################################################
# FIRST SETUP PART
###############################################################################
setup_chg_usr_pwd () {
  local USR=$1

  while true
  do
    whiptail --msgbox "You will now be asked to enter a new password for the user : ${USR} " 20 60 1
    passwd ${USR}
    RET=$?
    echo ${RET}
    read
    if [[ ${RET} -eq 1 ]]
    then
    	whiptail --msgbox "Password changed successfully" 20 60 1
      return 0
    elif ! ( whiptail --yesno "Failed to change password. Do you wan to retry ? " 20 60 1 )
    then
      return 1
    fi
  done
}

setup_ask_arch () {
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

setup_chg_locale() {
  dpkg-reconfigure locales
}

setup_chg_timezone() {
  dpkg-reconfigure tzdata
}

setup_config_keyboard() {
  dpkg-reconfigure keyboard-configuration &&
  printf "Reloading keymap. This may take a short while\n" &&
  invoke-rc.d keyboard-setup start || return $?
  udevadm trigger --subsystem-match=input --action=change
  return 0
}

setup_update_sudoer () {
  if ! grep -q "Defaults rootpw" /etc/sudoers
  then
    whiptail --title "Update sudoer file" --msgbox "\
    The following line is already present in /etc/sudoers \n \n\
    		\"Defaults rootpw\" \n \n\
    Nothing to do. Will continue" 20 60
    return 0
  elif ( whiptail --title "Update sudoer file" --yesno "\
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

setup_all_pkg() {
	setup_pk_fullupdate
	setup_pkg__base
	setup_pkg_ask
}

setup_user () {
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
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 2
      ;;
      "Update User" )
        setup_user_update
      ;;
      "Add User" )
        setup_user_add
        RET=$?
        if [[ ${RET} -eq 0 ]]
        then
          setup_user_update
        fi
      ;;
      "Delete User" )
        setup_user_delete
      ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
        return 1
    esac
  done
}

first_setup_go_through () {
  if ( whiptail --title 'Change root password' --yesno 'Do you want to change root password ? ' 10 60 )
  then
    setup_chg_usr_pwd 'root'
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Confirm distro' --yesno 'Do you want to confirm information about linux disctribution ? ' 10 60 )
  then
    setup_ask_arch
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Change Locale' --yesno 'Do you want to change the Locale ? ' 10 60 )
  then
    setup_chg_locale
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Change timezone' --yesno 'Do you want to change the timezone ? ' 10 60 )
  then
    setup_chg_timezone
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Change keyboard' --yesno 'Do you want to change the keyboard layout ? ' 10 60 )
  then
    setup_config_keyboard
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Update sudoer' --yesno 'Do you want to update sudoer files ? ' 10 60 )
  then
    setup_update_sudoer
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Install packages' --yesno 'Do you want to choose a list package to install ? ' 10 60 )
  then
    setup_all_pkg
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi

  if ( whiptail --title 'Config users' --yesno 'Do you want to manage users ? ' 10 60 )
  then
    setup_user
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi
  fi
  return 0
}

first_setup_loop () {
  local SETUP_LOOP="whiptail --title 'First Setup' --menu  'Select how do you whant to manage first setup :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  SETUP_LOOP="${SETUP_LOOP} 'Change root password' 'Change root password'"
  SETUP_LOOP="${SETUP_LOOP} 'Confirm distro' 'Ask you to confirm some linux distribution information'"
  SETUP_LOOP="${SETUP_LOOP} 'Change locale' 'Change Locale information'"
  SETUP_LOOP="${SETUP_LOOP} 'Change timezone' 'Change timezone'"
  SETUP_LOOP="${SETUP_LOOP} 'Change keyboard' 'Change keyboard layout'"
  SETUP_LOOP="${SETUP_LOOP} 'Install packages' 'Update and upgrade system and choose packages to install'"
  SETUP_LOOP="${SETUP_LOOP} 'Config users' 'Let you add, update or delete users'"
  SETUP_LOOP="${SETUP_LOOP} 'CONTINUE' 'Continue to the next step'"
  while true
  do
    bash -c "${SETUP_LOOP} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 0
      ;;
      "Change root password" )
        setup_chg_usr_pwd 'root'
      ;;
      "Confirm distro" )
        setup_ask_arch
      ;;
      "Change locale" )
        setup_chg_locale
      ;;
      "Change timezone" )
        setup_chg_timezone
      ;;
      "Change keyboard" )
        setup_config_keyboard
      ;;
      "Install packages" )
        setup_all_pkg
      ;;
      "Config users" )
        setup_user
      ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
        return 1
      ;;
   esac
  done
}

first_setup () {
  local FIRST_SETUP="whiptail --title 'First Setup' --menu  'Select how do you whant to manage first setup :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  FIRST_SETUP="${FIRST_SETUP} 'Go through' 'Let the script go through all actions'"
  FIRST_SETUP="${FIRST_SETUP} 'Choose actions' 'Let you choose what action you want to do'"
  FIRST_SETUP="${FIRST_SETUP} 'CONTINUE' 'Continue to the next step'"
  while true
  do
    bash -c "${FIRST_SETUP} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 0
      ;;
      "Go through" )
        first_setup_go_through
        RET=$?
        if [[ ${RET} -eq 1 ]]
        then
          first_setup_loop
        fi
      ;;
      "Choose actions" )
        first_setup_loop
      ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
        return 1
      ;;
   esac
  done
}

# TODO : Move the two following menu to root of project later
main_menu () {
  calc_wt_size
  local MAIN_MENU="whiptail --title 'Main Menu' --menu  'Select what you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MAIN_MENU="${MAIN_MENU} 'First setup' 'Let the script go through all actions'"
  MAIN_MENU="${MAIN_MENU} 'FINISH' 'Exit the script'"
  while true
  do
    bash -c "${MAIN_MENU} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "FINISH" )
      if [[ ${ASK_TO_REBOOT} -eq 1 ]] && (whiptail --title 'Reboot needed' --yesno 'A reboot is needed. Do you want to reboot now ? '  10 80 )
      then
        reboot
      fi
      return 0
      ;;
     "First setup" )
      first_setup
     ;;
     * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      return 1
   esac
  done
}

main_menu
