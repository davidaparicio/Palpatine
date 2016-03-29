#!/bin/bash

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
expand_rootfs() {
  get_init_sys
  if [ ${SYSTEMD} -eq 1 ]; then
    ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
  else
    if ! [ -h /dev/root ]; then
      whiptail --msgbox "/dev/root does not exist or is not a symlink. Don't know how to expand" 20 60 2
      return 0
    fi
    ROOT_PART=$(readlink /dev/root)
  fi

  PART_NUM=${ROOT_PART#mmcblk0p}
  if [ "${PART_NUM}" = "${ROOT_PART}" ]; then
    whiptail --msgbox "${ROOT_PART} is not an SD card. Don't know how to expand" 20 60 2
    return 0
  fi

  # NOTE: the NOOBS partition layout confuses parted. For now, let's only
  # agree to work with a sufficiently simple partition layout
  if [ "${PART_NUM}" -ne 2 ]; then
    whiptail --msgbox "Your partition layout is not currently supported by this tool. You are probably using NOOBS, in which case your root filesystem is already expanded anyway." 20 60 2
    return 0
  fi

  LAST_PART_NUM=$(parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)
  if [ ${LAST_PART_NUM} -ne ${PART_NUM} ]; then
    whiptail --msgbox "${ROOT_PART} is not the last partition. Don't know how to expand" 20 60 2
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "${PART_START}" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
${PART_NUM}
n
p
${PART_NUM}
${PART_START}

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
    resize2fs /dev/${ROOT_PART} &&
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
  if [ "${INTERACTIVE}" = True ]; then
    whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" 20 60 2
  fi
}

###############################################################################
# SETUP USER UPDATE MAIL PART
###############################################################################
setup_user_update_mail_ssh_key () {
  whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "You will now be ask some informations to create your ssh key." 8 60

  local PASSWORD_OK=false
  local PASSWORD1=""

  while ! ${PASSWORD_OK}
  do
    PASSWORD1=$(whiptail --title "SSH Key ${USER_CHOOSEN}" --passwordbox "First enter the password you want for the ssh key for ${USER_CHOOSEN} " 8 78   3>&1 1>&2 2>&3)
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    # REGEX PASSWORD
    #^([a-zA-Z0-9@*#_]{8,15})$
    #Description
    #Password matching expression.
    #Match all alphanumeric character and predefined wild characters.
    #Password must consists of at least 8 characters and not more than 15 characters.
    if [[ ! "${PASSWORD1}" =~ ^([a-zA-Z0-9@\*#]{8,15})$ ]]
    then
      whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "Password must be at least eight char long and contains alphanumeric char and predefined wild characters " 8 78   3>&1 1>&2 2>&3
    else
      local PASSWORD2=$(whiptail --title "SSH Key ${USER_CHOOSEN}" --passwordbox "Please enter the password again  " 8 78   3>&1 1>&2 2>&3)
      RET=$?
      [[ ${RET} -eq 1 ]] && return 1
      if [[ ! ${PASSWORD1} == ${PASSWORD2} ]]
      then
        whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "Passwords do not match" 8 78   3>&1 1>&2 2>&3
      else
        PASSWORD_OK=true
      fi
    fi
  done
  local PATH_RSA
  if [[ ${USER_CHOOSEN} == "root" ]]
  then
    PATH_RSA=$( whiptail --title "SSH Key ${USER_CHOOSEN}" --inputbox "Where do you want to store ssh key for ${USER_CHOOSEN}" 8 78 "/${USER_CHOOSEN}/.ssh/id_rsa" 3>&1 1>&2 2>&3)
  else
    PATH_RSA=$( whiptail --title "SSH Key ${USER_CHOOSEN}" --inputbox "Where do you want to store ssh key for ${USER_CHOOSEN}" 8 78 "/home/${USER_CHOOSEN}/.ssh/id_rsa" 3>&1 1>&2 2>&3)
  fi
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "Will now generate ssh key file for user ${USER_CHOOSEN}." 8 60
  su ${USER_CHOOSEN} -c "ssh-keygen -t rsa -b 4096 -N '${PASSWORD1}' -f '${PATH_RSA}' -C '${EMAIL1}'"
  whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "You will now be ask to enter ssh key password" 8 60
  su ${USER_CHOOSEN} -c "eval '$(ssh-agent -s)'; ssh-add ${PATH_RSA}"

  clear
  echo 'Here is the content of your ssh key'
  echo '========================================================================'
  [[ ${USER_CHOOSEN} == "root" ]] && cat /root/.ssh/id_rsa.pub || cat /home/${USER_CHOOSEN}/.ssh/id_rsa.pub
  echo '========================================================================'
  echo 'Please copy it and past it into your version control system (github, bitbucket, gitlab...) \n\n\
  BE WARNED THAT IF YOU DO NOT DO IT, FOLLOWING STEP MIGHT NOT BE WORKING'
  read
  return 2
}

setup_user_update_mail_git_config() {
  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Script will now running following command for user ${USER_CHOOSEN}: \n\
      - 'git config --global user.name '${USER_CHOOSEN_FULLNAME}' \n\
      - 'git config --global user.email '${EMAIL1}'  \n\
      - 'git config --global push.default matching \n\n\
      You will now be ask password for user ${USER_CHOOSEN}" 10 80)
  then
    su ${USER_CHOOSEN} -c "git config --global user.name '${USER_CHOOSEN_FULLNAME}';\
              git config --global user.email '${EMAIL1}'; \
              git config --global push.default matching;"
  else
    return 1
  fi
  return 0
}

setup_user_update_mail_vcsh_dotfiles () {
  local VCSH_MR_REPO_OK=false
  local VCSH_MR_REPO=""
  while ! ${VCSH_MR_REPO_OK}
  do
    VCSH_MR_REPO=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter myRepos address to clone via vcsh" 8 60  3>&1 1>&2 2>&3)
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    if ! [[ ${#VCSH_MR_REPO}  > 0 ]]
    then
      whiptail --title "Update ${USER_CHOOSEN}" --msgbox "Please enter something " 8 60  3>&1 1>&2 2>&3
    elif ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Are you sure this is the right adress ? \n ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
    then
      su ${USER_CHOOSEN} -c "vcsh clone ${VCSH_MR_REPO}; cd ~/; mr up"
      read
      if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Does everything work ? " 8 78   3>&1 1>&2 2>&3 )
      then
        VCSH_MR_REPO_OK=true
      fi
    elif ! ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to retry ? " 8 78   3>&1 1>&2 2>&3 )
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
    EMAIL1=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Email adress of the user ${USER_CHOOSEN}" 8 78   3>&1 1>&2 2>&3)
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    if [[ ! ${EMAIL1} =~ ${EMAIL_REGEX} ]]
    then
     whiptail --title "Update ${CHOICE}" --msgbox "This is not an email adresse. Please enter one of the form : \n\
     email@domain.com " 8 78
    else
     local EMAIL2=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter the email adress again" 8 78 3>&1 1>&2 2>&3)
     RET=$?
     [[ ${RET} -eq 1 ]] && return 1

     if [[ ! ${EMAIL1} == ${EMAIL2} ]] && ! ( whiptail --title "Update  ${USER_CHOOSEN}" --yesno "Emails do not match. Do you want to retry ?" 8 78 3>&1 1>&2 2>&3)
     then
       return 1
     else
      whiptail --title "Update ${USER_CHOOSEN}" --msgbox "Email successfully set" 8 78
      return 0
     fi
    fi
  done
}

###############################################################################
# SETUP USERR UPDATE PART
###############################################################################
setup_user_update_gecos () {
    chfn ${USER_CHOOSEN}
}

setup_user_update_chg_passwd () {
  while true
  do
    passwd ${USER_CHOOSEN}
    RET=$?
    if [[ ${RET} -eq 0 ]]
    then
      whiptail --msgbox "Password changed successfully" 20 60 1
      return 0
    elif ! ( whiptail --yesno "Failed to change password. Do you want to retry ? " 20 60 1 )
    then
      return 1
    fi
  done
}

setup_user_update_chg_shell () {
    chsh ${USER_CHOOSEN}
}

setup_user_update_set_email () {
  local EMAIL1="empty"

  setup_user_update_mail_ask
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  local MENU_USER="whiptail --title 'Update ${USER_CHOOSEN}' --menu  'Select action :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  MENU_USER="${MENU_USER} 'SSH Key' 'Generate or update ssh key of the user ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Git information' 'Update git information of the user ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Vcsh and mr dotfiles' 'Get myRepos config via vcsh from a git repo'"
  MENU_USER="${MENU_USER} 'Command dotfiles' 'Get dotfiles from a one line command '"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 2
      ;;
      "SSH Key" )
        setup_user_update_mail_ssh_key ${USER_CHOOSEN} ${EMAIL1}
      ;;
      "Git information" )
        setup_user_update_mail_git_config ${EMAIL1}
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
  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to change GECOS informations of user :  ${USER_CHOOSEN}" 8 60 )
  then
    setup_user_update_gecos
  fi

  if ( whiptail --title "Update ${USER_CHOOSEN}r" --yesno "Do you want to change password user :  ${USER_CHOOSEN}" 8 60 )
  then
    setup_user_update_chg_passwd
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title "Update ${USER_CHOOSEN}r" --yesno "Do you want to change shell for user :  ${USER_CHOOSEN}" 8 60 )
  then
    setup_user_update_chg_shell
  fi

  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to enter the email adress for user :  ${USER_CHOOSEN} \n \
  If no, Following step will not be launch \n\
    - Generating SSH Key \n\
    - Setup git user information \n\
    - Setup dotfiles repos from git \n\
    - Setup dotfiles with vcsh and myRepos " 12 60 )
  then
    setup_user_update_set_email
  else
    return 1
  fi
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1
  return 2
}

setup_user_update_loop () {
  local MENU_USER="whiptail --title 'Update ${USER_CHOOSEN}' --menu  'Select what you want to do :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  MENU_USER="${MENU_USER} 'Update GECOS' 'Update GEOCS information such as Fullname, Room...'"
  MENU_USER="${MENU_USER} 'Change password' 'Change the password of the ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Change shell' 'Change the shell of the ${USER_CHOOSEN}'"
  MENU_USER="${MENU_USER} 'Set email' 'Set email and continue with ssh key and dotfiles'"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

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
  NB_USER=$(( ${#USERNAME[@]} - 1 ))

  local MENU_USER="whiptail --title 'Update User' --menu  'Select which user informations you want to update :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx=0 ; idx <= ${NB_USER} ; idx++ ))
  do
    MENU_USER="${MENU_USER} '${USERNAME[${idx}]}' '${FULL_NAME[${idx}]}'"
  done

  bash -c "${MENU_USER} " 2> results_menu.txt
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  USER_CHOOSEN=$( cat results_menu.txt )

  local USER_FOUND=false
  local idxUser=0
  while ! ${USER_FOUND}
  do
    if [[ ${idxUser} -gt ${NB_USER} ]]
    then
      echo "Programmer error : user ${USER_CHOOSEN} not found"
      return 1
    fi
    if [[ "${USER_CHOOSEN}" =~ "${USERNAME[${idxUser}]}" ]]
    then
      USER_CHOOSEN_FULLNAME=${FULL_NAME[${idxUser}]}
      USER_FOUND=true
    fi
    idxUser=$(( ${idxUser} + 1 ))
  done
  return 0
}

###############################################################################
# SETUP USERR CONFIG PART
###############################################################################
setup_user_update () {
  local FULL_NAME
  local USERNAME
  local NB_USER

  if [[ $# -eq 0 ]]
  then
    setup_user_update_select
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  local MENU_USER="whiptail --title 'Update ${USER_CHOOSEN}' --menu  'Select how you want to manage user update :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  MENU_USER="${MENU_USER} 'Go through' 'Let the script go through all actions'"
  MENU_USER="${MENU_USER} 'Choose action' 'Let you choose what you want to update'"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
     "CONTINUE" )
      return 2
     ;;
    "Go through" )
      setup_user_update_go_through
      RET=$?
      [[ ${RET} -eq 1 ]] && setup_user_update_loop
      [[ ${RET} -eq 2 ]] && return 0
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
  return 0
}

setup_user_add () {
  local USERNAME_OK=false
  while ! ${USERNAME_OK}
  do
    local USERNAME="whiptail --title 'Add Users' --inputbox 'Username for the new user (only lowerscript char) ' 8 78 "
    bash -c "${USERNAME}" 2>results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

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
  local PASSWORD1=""

  while ! ${PASSWORD_OK}
  do
    PASSWORD1=$(whiptail --title "Add Users" --passwordbox "Password for the new user  " 8 78   3>&1 1>&2 2>&3)
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

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
      [[ ${RET} -eq 1 ]] && return 1
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
  USER_CHOOSEN=${USERNAME}
  USER_CHOOSEN_FULLNAME="${FIRST_NAME} ${LAST_NAME}"
  return 0
}

setup_user_delete () {
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

  local MENU_USER="whiptail --title 'Delete User' --menu  'Select which user you want to delete :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx=0 ; idx <= ${NB_USER}-1 ; idx++ ))
  do
    MENU_USER="${MENU_USER} '${USERNAME[${idx}]}' '${FULL_NAME[${idx}]}'"
  done

  bash -c "${MENU_USER} " 2> results_menu.txt
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  CHOICE=$( cat results_menu.txt )

  if ( whiptail --title "Update User" --yesno "Do you really want to delete user :  ${CHOICE} \n\
  Its data will be save to /root/user.backup/${CHOICE}" 8 60 )
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
# SETUP INSTALL PACKAGE ASK PART
###############################################################################
setup_pkg_ask_finish () {
  local HEIGHT=3
  local ALL_PKG_CHOOSEN=""
  local ALL_REPO_ADD=""

  MENU_ASK_FINISH="whiptail --title 'Last Check Before Install' --yesno  'This is the list of program this script will install : "
  for (( idxCat=1 ; idxCat <= ${NB_CAT} ; idxCat++ ))
  do
    local CAT_DONE=false
    local NAME=${ALL_CAT[${idxCat}]}
    local LOWER_NAME=`echo "${NAME}" | tr '[:upper:]' '[:lower:]'`
    local UPPER_NAME=`echo "${NAME}" | tr '[:lower:]' '[:upper:]'`

    source 001.Initial_Setup/menu/*${LOWER_NAME}.sh

    local ARR_NAME="APP_${NAME}_NAME[@]"
    local ARR_PKG="APP_${NAME}_PKG[@]"
    local ARR_DESC="APP_${NAME}_DESC[@]"
    local ARR_STAT="APP_${NAME}_STAT[@]"
    local CAT_NAME="APP_${NAME}_CAT"

    local APP_ARR_NAME=("${!ARR_NAME}")
    local APP_ARR_PKG=("${!ARR_PKG}")
    local APP_ARR_DESC=("${!ARR_DESC}")
    local APP_ARR_STAT=("${!ARR_STAT}")
    CAT_NAME=("${!CAT_NAME}")

    local NB_APP=${#APP_ARR_NAME[@]}

    for (( idx=0 ; idx <= ${NB_APP} ; idx++ ))
    do
      if [[ ${APP_ARR_STAT[${idx}]} == "ON" ]]
      then
        if ! ${CAT_DONE}
        then
            MENU_ASK_FINISH="${MENU_ASK_FINISH}  \n ==== Category : ${CAT_NAME} ===="
            CAT_DONE=true
            HEIGHT=$(( HEIGHT + 1 ))
        fi
        MENU_ASK_FINISH="${MENU_ASK_FINISH} \n= ${APP_ARR_NAME[${idx}]} : ${APP_ARR_DESC[${idx}]}"
        HEIGHT=$(( HEIGHT + 1 ))

        if type -t ${APP_ARR_NAME[${idx}]}_routine &>/dev/null
        then
          ${APP_ARR_NAME[${idx}]}_routine
        fi
        ALL_PKG_CHOOSEN+=" ${APP_ARR_PKG[${idx}]}"

      fi
    done
    CAT_DONE=false
    MENU_ASK_FINISH="${MENU_ASK_FINISH} \n "
    HEIGHT=$(( HEIGHT + 2 ))
  done
  MENU_ASK_FINISH="${MENU_ASK_FINISH}' $HEIGHT ${WT_WIDTH} "
  bash -c "${MENU_ASK_FINISH}"
  RET=$?
  if [[ ${RET} -eq 0 ]]
  then
    for i in ${ALL_REPO_ADD}
    do
      add-apt-repository -y $i
    done
    apt-get update && apt-get upgrade -y && apt-get install -y ${ALL_PKG_CHOOSEN}
  elif [[ ${RET} -eq 1 ]]
  then
    return 1
  fi
  return 0
}

setup_pkg_ask_menu_app () {
  local NAME=$1
  local LOWER_NAME=`echo "${NAME}" | tr '[:upper:]' '[:lower:]'`
  local UPPER_NAME=`echo "${NAME}" | tr '[:lower:]' '[:upper:]'`

  source 001.Initial_Setup/menu/*${LOWER_NAME}.sh

  local ARR_NAME="APP_${NAME}_NAME[@]"
  local ARR_PKG="APP_${NAME}_PKG[@]"
  local ARR_DESC="APP_${NAME}_DESC[@]"
  local ARR_STAT="APP_${NAME}_STAT[@]"
  local CAT_NAME="APP_${NAME}_CAT"

  local APP_ARR_NAME=("${!ARR_NAME}")
  local APP_ARR_PKG=("${!ARR_PKG}")
  local APP_ARR_DESC=("${!ARR_DESC}")
  local APP_ARR_STAT=("${!ARR_STAT}")
  CAT_NAME=("${!CAT_NAME}")

  local NB_APP=${#APP_ARR_NAME[@]}

  local MENU_APP="whiptail --title '${CAT_NAME}' --checklist  'Select which ${CAT_NAME} you want to install :' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    MENU_APP="${MENU_APP} '${APP_ARR_NAME[${idx}]}' '${APP_ARR_DESC[${idx}]}' '${APP_ARR_STAT[${idx}]}'"
  done

  bash -c "${MENU_APP}" 2> results_menu.txt
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  CHOICE=$( cat results_menu.txt )

  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    if echo ${CHOICE} | grep -q "\"${APP_ARR_NAME[${idx}]}\""
    then
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"ON\"/g' 001.Initial_Setup/menu/*${LOWER_NAME}.sh"
      eval ${CMD}
    else
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"OFF\"/g' 001.Initial_Setup/menu/*${LOWER_NAME}.sh"
      eval ${CMD}
    fi
  done
  return 0
}

setup_pkg_ask_all_cat () {
  local CAT_NAME
  local CAT_DESC

  local MENU_CAT="whiptail --title 'Category of application' --menu  'Select which category of application you want to install :' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx=1 ; idx <= ${NB_CAT} ; idx++ ))
  do
    CAT_NAME="APP_${ALL_CAT[${idx}]}_CAT"
    CAT_DESC="APP_${ALL_CAT[${idx}]}_EX"
    MENU_CAT="${MENU_CAT} '${!CAT_NAME}' '${!CAT_DESC}'"
  done
  MENU_CAT="${MENU_CAT} 'CONTINUE' 'Continue to the next step'"

  bash -c "${MENU_CAT}" 2> results_menu.txt
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  CHOICE=$( cat results_menu.txt )

  [[ ${CHOICE} == "CONTINUE" ]] && return 2

  for (( idxCat=0 ; idxCat <= ${NB_CAT} ; idxCat++ ))
  do
    CAT_NAME="APP_${ALL_CAT[${idxCat}]}_CAT"
    if [[ ${!CAT_NAME} == ${CHOICE} ]]
    then
        setup_pkg_ask_menu_app ${ALL_CAT[${idxCat}]}
    fi
  done
  return 0
}

setup_pkg_ask_all_cat_loop () {
  while true
  do
    setup_pkg_ask_all_cat
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
    if [[ ${RET} -eq 2 ]]
    then
      setup_pkg_ask_finish
      RET=$?
      [[ ${RET} -eq 0 ]] && return 0
    fi
  done
}

setup_pkg_ask_go_through () {
  for (( idxCat=1 ; idxCat <= ${NB_CAT} ; idxCat++ ))
  do
    setup_pkg_ask_menu_app ${ALL_CAT[${idxCat}]}
    RET=$?
    [[ ${RET} -eq 1 ]] && idxCat==$(( ${NB_CAT} + 1 ))
  done
  if [[ ${RET} -eq 0 ]]
  then
    setup_pkg_ask_finish
  fi
  return ${RET}
}

###############################################################################
# SETUP INSTALL PACKAGE PART
###############################################################################
setup_pkg_fullupdate () {
  whiptail --title "Update Repo and Upgrade" --msgbox "\
  This script will now update and upgrade the system" 20 60
  # TODO : Manage multiple system
  apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
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
  local ALL_APP_CAT=""
  echo '#!/bin/bash  \n\n' > 001.Initial_Setup/menu_categories.sh
  for i in 001.Initial_Setup/menu/*.sh
  do
    BEGIN=$( grep -in "# BEGIN " ${i} | cut -d ':' -f1 )
    END=$( grep -in "# END " ${i} | cut -d ':' -f1 )
    sed -n "${BEGIN},${END}p" ${i} >> 001.Initial_Setup/menu_categories.sh
  done

  source 001.Initial_Setup/menu_categories.sh

  local ALL_CAT
  local NB_CAT
  local CAT_NAME

  IFS=':' read -r -a ALL_CAT <<< "${ALL_APP_CAT}"
  NB_CAT=$(( ${#ALL_CAT[@]} - 1 ))

	PKG_ASK_MENU=$(whiptail --title "Package to setup" --menu "Please choose how \
to manage package installation :" ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} --ok-button Select \
		"1 Go through" "Let the script go through all categories of programm to setup." \
		"2 Choose" "Choose the categorie of programs you want to setup." \
		"3 Direct setup" "Setup my minimalistic apps." \
		3>&1 1>&2 2>&3)
	RET=$?
  [[ $RET -eq 1 ]] && return 1
  case ${PKG_ASK_MENU} in
      1\ *)
        setup_pkg_ask_go_through
        RET=$?
        if [[ ${RET} -eq 1 ]]
        then
          setup_pkg_ask_all_cat_loop
          RET=$?
        fi
        return ${RET}
      ;;
      2\ *)
        setup_pkg_ask_all_cat_loop
        RET=$?
        if [[ ${RET} -eq 0 ]]
        then
          setup_pkg_ask_finish
          RET=$?
        fi
        return ${RET}
      ;;
      3\ *)
        setup_pkg_ask_finish
        RET=$?
        if [[ ${RET} -eq 1 ]]
        then
          setup_pkg_ask_all_cat_loop
          RET=$?
        fi
        return ${RET}
      ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
  esac
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

setup_expand_rootfs () {
  if ${LINUX_IS_RPI}
  then
    if ( whiptail --title 'Expand Rootfs' --yesno 'Are you sure  you are on a RPi and you want to expand rootfs ?
I WILL NOT BE RESPONSIBLE IF DAMAGE OCCURS TO YOUR ROOTFS' ${WT_HEIGHT} ${WT_WIDTH} )
    then
      expand_rootfs
      RET=$?
      [[ ${RET} -eq 1 ]] && return 1
    fi
  else
    whiptail --title 'Expand Rootfs' --yesno 'You said that this linux distribution is not an RPi one. Nothing to do' ${WT_HEIGHT} ${WT_WIDTH}
  fi
  return 0
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
	setup_pkg_fullupdate
	setup_pkg_base
	setup_pkg_ask
}

setup_user () {
  local USER_CHOOSEN
  local USER_CHOOSEN_FULLNAME

  local MENU_USER="whiptail --title 'User modification' --menu  'Select what you want to do :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  MENU_USER="${MENU_USER} 'Update User' 'Update user information such as setting a git/vcsh dotfiles, name, mail etc.'"
  MENU_USER="${MENU_USER} 'Add User' 'Add a new user'"
  MENU_USER="${MENU_USER} 'Delete User' 'Delete an existing user'"
  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to the next step'"

  while true
  do
    bash -c "${MENU_USER} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

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
        [[ ${RET} -eq 0 ]] && setup_user_update true
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
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Update sudoer' --yesno 'Do you want to update sudoer files by adding line "Defaults rootpw" ? ' 10 60 )
  then
    setup_update_sudoer
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Change Locale' --yesno 'Do you want to change the Locale ? ' 10 60 )
  then
    setup_chg_locale
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Change timezone' --yesno 'Do you want to change the timezone ? ' 10 60 )
  then
    setup_chg_timezone
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Change keyboard' --yesno 'Do you want to change the keyboard layout ? ' 10 60 )
  then
    setup_config_keyboard
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Install packages' --yesno 'Do you want to choose a list package to install ? ' 10 60 )
  then
    setup_all_pkg
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Config users' --yesno 'Do you want to manage users ? ' 10 60 )
  then
    setup_user
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1
  fi

  if ! ( whiptail --title 'First setup finish' --yesno 'Does everything went ok ? ' 10 60 )
  then
      return 1
  fi

  return 0
}

first_setup_loop () {
  local SETUP_LOOP="whiptail --title 'First Setup' --menu  'Select how do you whant to manage first setup :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  SETUP_LOOP="${SETUP_LOOP} 'Change root password' 'Change root password'"
  SETUP_LOOP="${SETUP_LOOP} 'Change sudoer file' 'Will change sudoers file to add line Defaults rootpw'"
  SETUP_LOOP="${SETUP_LOOP} 'Expand rootfs' 'Will expand rootfs (NB: Will only work on RPi)'"
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
    [[ ${RET} -eq 1 ]] && return 1

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 0
      ;;
      "Change root password" )
        setup_chg_usr_pwd 'root'
      ;;
      "Change sudoer file" )
        setup_update_sudoer
      ;;
      "Expand rootfs" )
        setup_expand_rootfs
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
  local FIRST_SETUP="whiptail --title 'First Setup' --menu  'Select how do you whant to manage first setup :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  FIRST_SETUP="${FIRST_SETUP} 'Go through' 'Let the script go through all actions'"
  FIRST_SETUP="${FIRST_SETUP} 'Choose actions' 'Let you choose what action you want to do'"
  FIRST_SETUP="${FIRST_SETUP} 'CONTINUE' 'Continue to the next step'"
  while true
  do
    bash -c "${FIRST_SETUP} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "CONTINUE" )
        return 0
      ;;
      "Go through" )
        first_setup_go_through
        RET=$?
        [[ ${RET} -eq 1 ]] && first_setup_loop
        [[ ${RET} -eq 0 ]] && return 0
      ;;
      "Choose actions" )
        first_setup_loop
        [[ ${RET} -eq 0 ]] && return 0
      ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
        return 1
      ;;
   esac
  done
}
