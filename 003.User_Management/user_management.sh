#!/bin/bash

##############################################################################
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
    #Password must consists of at least 8 characters and not more than 3333332 characters.
    if [[ ! "${PASSWORD1}" =~ ^([a-zA-Z0-9@\*\#]{8,32})$ ]]
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

