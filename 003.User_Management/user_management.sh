#!/bin/bash

###############################################################################
## SETUP USER UPDATE MAIL PART
################################################################################
#user_update_mail_ssh_key () {
#  whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "You will now be ask some informations to create your ssh key." 8 60
#
#  local PASSWORD_OK=false
#  local PASSWORD1=""
#
#  while ! ${PASSWORD_OK}
#  do
#    PASSWORD1=$(whiptail --title "SSH Key ${USER_CHOOSEN}" --passwordbox "First enter the password you want for the ssh key for ${USER_CHOOSEN} " 8 78   3>&1 1>&2 2>&3)
#    RET=$?
#    [[ ${RET} -eq 1 ]] && return 1
#
#    # REGEX PASSWORD
#    #^([a-zA-Z0-9@*#_]{8,15})$
#    #Description
#    #Password matching expression.
#    #Match all alphanumeric character and predefined wild characters.
#    #Password must consists of at least 8 characters and not more than 3333332 characters.
#    if [[ ! "${PASSWORD1}" =~ ^([a-zA-Z0-9@\*\#]{8,32})$ ]]
#    then
#      whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "Password must be at least eight char long and contains alphanumeric char and predefined wild characters " 8 78   3>&1 1>&2 2>&3
#    else
#      local PASSWORD2=$(whiptail --title "SSH Key ${USER_CHOOSEN}" --passwordbox "Please enter the password again  " 8 78   3>&1 1>&2 2>&3)
#      RET=$?
#      [[ ${RET} -eq 1 ]] && return 1
#      if [[ ! ${PASSWORD1} == ${PASSWORD2} ]]
#      then
#        whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "Passwords do not match" 8 78   3>&1 1>&2 2>&3
#      else
#        PASSWORD_OK=true
#      fi
#    fi
#  done
#  local PATH_RSA
#  if [[ ${USER_CHOOSEN} == "root" ]]
#  then
#    PATH_RSA=$( whiptail --title "SSH Key ${USER_CHOOSEN}" --inputbox "Where do you want to store ssh key for ${USER_CHOOSEN}" 8 78 "/${USER_CHOOSEN}/.ssh/id_rsa" 3>&1 1>&2 2>&3)
#  else
#    PATH_RSA=$( whiptail --title "SSH Key ${USER_CHOOSEN}" --inputbox "Where do you want to store ssh key for ${USER_CHOOSEN}" 8 78 "/home/${USER_CHOOSEN}/.ssh/id_rsa" 3>&1 1>&2 2>&3)
#  fi
#  RET=$?
#  [[ ${RET} -eq 1 ]] && return 1
#
#  whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "Will now generate ssh key file for user ${USER_CHOOSEN}." 8 60
#  su ${USER_CHOOSEN} -c "ssh-keygen -t rsa -b 4096 -N '${PASSWORD1}' -f '${PATH_RSA}' -C '${EMAIL1}'"
#  whiptail --title "SSH Key ${USER_CHOOSEN}" --msgbox "You will now be ask to enter ssh key password" 8 60
#  su ${USER_CHOOSEN} -c "eval '$(ssh-agent -s)'; ssh-add ${PATH_RSA}"
#
#  clear
#  echo 'Here is the content of your ssh key'
#  echo '========================================================================'
#  [[ ${USER_CHOOSEN} == "root" ]] && cat /root/.ssh/id_rsa.pub || cat /home/${USER_CHOOSEN}/.ssh/id_rsa.pub
#  echo '========================================================================'
#  echo 'Please copy it and past it into your version control system (github, bitbucket, gitlab...) \n\n\
#  BE WARNED THAT IF YOU DO NOT DO IT, FOLLOWING STEP MIGHT NOT BE WORKING'
#  read
#  return 2
#}
#
#user_update_mail_git_config() {
#  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Script will now running following command for user ${USER_CHOOSEN}: \n\
#      - 'git config --global user.name '${USER_CHOOSEN_FULLNAME}' \n\
#      - 'git config --global user.email '${EMAIL1}'  \n\
#      - 'git config --global push.default matching \n\n\
#      You will now be ask password for user ${USER_CHOOSEN}" 10 80)
#  then
#    su ${USER_CHOOSEN} -c "git config --global user.name '${USER_CHOOSEN_FULLNAME}';\
#              git config --global user.email '${EMAIL1}'; \
#              git config --global push.default matching;"
#  else
#    return 1
#  fi
#  return 0
#}
#
#user_update_mail_vcsh_dotfiles () {
#  local VCSH_MR_REPO_OK=false
#  local VCSH_MR_REPO=""
#  while ! ${VCSH_MR_REPO_OK}
#  do
#    VCSH_MR_REPO=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter myRepos address to clone via vcsh" 8 60  3>&1 1>&2 2>&3)
#    RET=$?
#    [[ ${RET} -eq 1 ]] && return 1
#
#    if ! [[ ${#VCSH_MR_REPO}  > 0 ]]
#    then
#      whiptail --title "Update ${USER_CHOOSEN}" --msgbox "Please enter something " 8 60  3>&1 1>&2 2>&3
#    elif ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Are you sure this is the right adress ? \n ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
#    then
#      su ${USER_CHOOSEN} -c "vcsh clone ${VCSH_MR_REPO}; cd ~/; mr up"
#      read
#      if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Does everything work ? " 8 78   3>&1 1>&2 2>&3 )
#      then
#        VCSH_MR_REPO_OK=true
#      fi
#    elif ! ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to retry ? " 8 78   3>&1 1>&2 2>&3 )
#    then
#      VCSH_MR_REPO_OK=true
#    fi
#  done
#}
#
#user_update_mail_cmd_dotfiles () {
#  local CMD_OK=""
#  while ! ${CMD_OK}
#  do
#    CMD=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter command in one line format if you can. \n\
#If you can't, you can create a script in your git repo or accessible with wget and run a command like : \n\n\
#'wget -O - http://link.to/your_script.sh | bash' " 10 80  3>&1 1>&2 2>&3)
#    if [[ ${#CMD}  > 0 ]] && ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Are you sure this is the right adress ? \n\
#    ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
#    then
#      ${CMD}
#      if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Does everything work ? ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
#      then
#        CMD_OK=true
#      fi
#    fi
#
#    if ! ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to retry ? ${VCSH_MR_REPO} " 8 78   3>&1 1>&2 2>&3 )
#    then
#      CMD_OK=true
#    fi
#  done
#}
#
#user_update_mail_ask () {
# local MAIL_OK=false
# local EMAIL_REGEX="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
#
#  while ! ${MAIL_OK}
#  do
#    EMAIL1=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Email adress of the user ${USER_CHOOSEN}" 8 78   3>&1 1>&2 2>&3)
#    RET=$?
#    [[ ${RET} -eq 1 ]] && return 1
#
#    if [[ ! ${EMAIL1} =~ ${EMAIL_REGEX} ]]
#    then
#     whiptail --title "Update ${CHOICE}" --msgbox "This is not an email adresse. Please enter one of the form : \n\
#     email@domain.com " 8 78
#    else
#     local EMAIL2=$(whiptail --title "Update ${USER_CHOOSEN}" --inputbox "Please enter the email adress again" 8 78 3>&1 1>&2 2>&3)
#     RET=$?
#     [[ ${RET} -eq 1 ]] && return 1
#
#     if [[ ! ${EMAIL1} == ${EMAIL2} ]] && ! ( whiptail --title "Update  ${USER_CHOOSEN}" --yesno "Emails do not match. Do you want to retry ?" 8 78 3>&1 1>&2 2>&3)
#     then
#       return 1
#     else
#      whiptail --title "Update ${USER_CHOOSEN}" --msgbox "Email successfully set" 8 78
#      return 0
#     fi
#    fi
#  done
#}
#
################################################################################
## SETUP USERR UPDATE PART
################################################################################
#user_update_gecos () {
#    chfn ${USER_CHOOSEN}
#}
#
#user_update_chg_passwd () {
#  while true
#  do
#    passwd ${USER_CHOOSEN}
#    RET=$?
#    if [[ ${RET} -eq 0 ]]
#    then
#      whiptail --msgbox "Password changed successfully" 20 60 1
#      return 0
#    elif ! ( whiptail --yesno "Failed to change password. Do you want to retry ? " 20 60 1 )
#    then
#      return 1
#    fi
#  done
#}
#
#user_update_chg_shell () {
#    chsh ${USER_CHOOSEN}
#}
#
#user_update_set_email () {
#  local EMAIL1="empty"
#
#  user_update_mail_ask
#  RET=$?
#  [[ ${RET} -eq 1 ]] && return 1
#
#  local MENU_USER="whiptail --title 'Update ${USER_CHOOSEN}' --menu  'Select action :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
#  MENU_USER="${MENU_USER} 'SSH Key' 'Generate or update ssh key of the user ${USER_CHOOSEN}'"
#  MENU_USER="${MENU_USER} 'Git information' 'Update git information of the user ${USER_CHOOSEN}'"
#  MENU_USER="${MENU_USER} 'Vcsh and mr dotfiles' 'Get myRepos config via vcsh from a git repo'"
#  MENU_USER="${MENU_USER} 'Command dotfiles' 'Get dotfiles from a one line command '"
#  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
#  while true
#  do
#    bash -c "${MENU_USER} " 2> results_menu.txt
#    RET=$?
#    [[ ${RET} -eq 1 ]] && return 1
#
#    CHOICE=$( cat results_menu.txt )
#
#    case ${CHOICE} in
#      "CONTINUE" )
#        return 2
#      ;;
#      "SSH Key" )
#        user_update_mail_ssh_key ${USER_CHOOSEN} ${EMAIL1}
#      ;;
#      "Git information" )
#        user_update_mail_git_config ${EMAIL1}
#      ;;
#      "Vcsh and mr dotfiles" )
#        user_update_mail_vcsh_dotfiles
#      ;;
#      "Command dotfiles" )
#        user_update_mail_cmd_dotfiles
#      ;;
#    esac
#  done
#}
#
#user_update_go_through () {
#  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to change GECOS informations of user :  ${USER_CHOOSEN}" 8 60 )
#  then
#    user_update_gecos
#  fi
#
#  if ( whiptail --title "Update ${USER_CHOOSEN}r" --yesno "Do you want to change password user :  ${USER_CHOOSEN}" 8 60 )
#  then
#    user_update_chg_passwd
#    RET=$?
#    [[ ${RET} -eq 1 ]] && return 1
#  fi
#
#  if ( whiptail --title "Update ${USER_CHOOSEN}r" --yesno "Do you want to change shell for user :  ${USER_CHOOSEN}" 8 60 )
#  then
#    user_update_chg_shell
#  fi
#
#  if ( whiptail --title "Update ${USER_CHOOSEN}" --yesno "Do you want to enter the email adress for user :  ${USER_CHOOSEN} \n \
#  If no, Following step will not be launch \n\
#    - Generating SSH Key \n\
#    - Setup git user information \n\
#    - Setup dotfiles repos from git \n\
#    - Setup dotfiles with vcsh and myRepos " 12 60 )
#  then
#    user_update_set_email
#  else
#    return 1
#  fi
#  RET=$?
#  [[ ${RET} -eq 1 ]] && return 1
#  return 2
#}
#
#user_update_loop () {
#  local MENU_USER="whiptail --title 'Update ${USER_CHOOSEN}' --menu  'Select what you want to do :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
#  MENU_USER="${MENU_USER} 'Update GECOS' 'Update GEOCS information such as Fullname, Room...'"
#  MENU_USER="${MENU_USER} 'Change password' 'Change the password of the ${USER_CHOOSEN}'"
#  MENU_USER="${MENU_USER} 'Change shell' 'Change the shell of the ${USER_CHOOSEN}'"
#  MENU_USER="${MENU_USER} 'Set email' 'Set email and continue with ssh key and dotfiles'"
#  MENU_USER="${MENU_USER} 'CONTINUE' 'Continue to next step'"
#  while true
#  do
#    bash -c "${MENU_USER} " 2> results_menu.txt
#    RET=$?
#    [[ ${RET} -eq 1 ]] && return 1
#
#    CHOICE=$( cat results_menu.txt )
#
#    case ${CHOICE} in
#      "CONTINUE" )
#        return 2
#      ;;
#      "Update GECOS" )
#        user_update_gecos
#      ;;
#      "Change password" )
#        user_update_chg_passwd
#      ;;
#      "Change shell" )
#        user_update_chg_shell
#      ;;
#      "Set email" )
#        user_update_set_email
#      ;;
#    esac
#  done
#}
#
user_update() {

  if [[ ${#USER_CHOOSEN} -eq 0 ]]
  then
    local fullname[0]=$( grep "^root:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
    local username[0]=$( grep "^root:" /etc/passwd | cut -d: -f1 )
    _l="/etc/login.defs"
    _p="/etc/passwd"

    l=$(grep "^UID_MIN" $_l)
    l1=$(grep "^UID_MAX" $_l)
    awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" \
      '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' \
      "$_p" > results_menu.txt
    idx=1
    while read line
    do
      fullname[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f1 )
      username[idx]=$( echo ${line} | cut -d: -f1 )
      idx=$(( $idx + 1 ))
    done < results_menu.txt
    local nb_usr=${#username[@]}

    local update_user="whiptail --title '003.User management : Update user' \
    --menu  'select which user you want to update :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
    for (( idx = 0 ; idx <= ${nb_usr}-1 ; idx++ ))
    do
      update_user="${update_user} '${username[idx]}' '${fullname[idx]}'"
    done

    bash -c "${update_user} " 2> results_menu.txt
    RET=$? ;  [[ ${RET} -eq 1 ]] && return 1
    USER_CHOOSEN=$( cat results_menu.txt )
  fi
  USER_CHOOSEN_FULLNAME=$( grep "^${USER_CHOOSEN}:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
  USER_CHOOSEN_MAIL=$( grep "^${USER_CHOOSEN}:" /etc/passwd | cut -d: -f5 | cut -d, -f2 )
${FULL_NAME[${idxUser}]}
  return 0
}

user_add () {
  local username_ok=false
  local username=""
  local firstname=""
  local lastname=""
  local passwd_ok=false
  local passwd_regex='[a-zA-Z0-9@*#\-_=!?%&]{8,}'
  # REGEX PASSWORD
  #^([a-zA-Z0-9@*#_]{8,15})$
  #Description
  #Password matching expression.
  #Match all alphanumeric character and predefined wild characters.
  #Password must consists of at least 8 characters and not more than 15 characters.
  local passwd1=""
  local passwd2=""
  local mail_ok=false
  local mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
  local gecos_info
  local shell

  while ! ${username_ok}
  do
    username="whiptail --title '003.User Management : Add User' \
      --inputbox 'Username for the new user (only lowerscript char)' \
      ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${username}" 2>results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    username=$( cat results_menu.txt )
    if [[ ${#username} == 0 ]]
    then
      if ! ( whiptail --title '003.User Management : Add Users' \
        --yesno 'Username must be at least one char long. \n\n
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    elif ! [[ ${username} =~ ^[a-z]*$ ]]
    then
      if ! ( whiptail --title '003.User Management : Add Users' \
        --yesno 'Username must contain only lowerscript char [a-z]. \n\n
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    elif getent passwd ${username}
    then
      if ! ( whiptail \
        --title '003.User Management : Add User' \
        --yesno 'User already exist. \n\nDo you want to retry ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    else
      username_ok=true
    fi
  done

  firstname="whiptail --title '003.User Management : Add User' \
    --inputbox 'First name of the new user (you can leave it empty).' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${firstname}" 2>results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  firstname=$( cat results_menu.txt )

  lastname="whiptail --title '003.User Management : Add User' \
    --inputbox 'Last name of the new user (you can leave it empty).' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${lastname}" 2>results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  lastname=$( cat results_menu.txt )

  while ! ${passwd_ok}
  do
    passwd1="whiptail --title '003.User Management : Add User' \
    --passwordbox 'Password for the new user' ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${passwd1}" 2>results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    passwd1=$( cat results_menu.txt )

    if ! [[ ${passwd1} =~ ${passwd_regex} ]]
    then
      whiptail --title '003.User Management : Add Users' \
        --msgbox "Password must be at least eight char long and contains only \
alphanumeric char either lowercase or uppercase and the following predefined \
characters  : @ * # - _ = ! ? % &." ${WT_HEIGHT} ${WT_WIDTH}
    else
      local passwd2="whiptail --title '003.User Management : Add User' \
        --passwordbox 'Please enter the password again.' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "${passwd2}" 2> results_menu.txt
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      passwd2=$( cat results_menu.txt )
      if [[ ! ${passwd1} == ${passwd2} ]]
      then
        whiptail --title '003.User Management : Add User' \
          --msgbox 'Passwords do not match. Please retry.' ${WT_HEIGHT} ${WT_WIDTH}
      else
        passwd_ok=true
      fi
    fi
  done

  while ! ${mail_ok}
  do
    mail1="whiptail --title '003.User Management : Add User' \
      --inputbox 'Email adress of the new user' ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "$mail1" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    mail1=$( cat results_menu.txt )
    if [[ ! ${mail1} =~ ${mail_regex} ]]
    then
     whiptail --title '003. User Manage : Add User' \
       --msgbox 'This is not an email adress. Please enter one of the form : \n\
     email@domain.com.' ${WT_HEIGHT} ${WT_WIDTH}
    else
      mail2="whiptail --title '003.User Management : Add User' \
        --inputbox 'Please enter email adress again' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "$mail2" 2> results_menu.txt
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      mail2=$( cat results_menu.txt )
      if [[ ! ${mail1} == ${mail2} ]] && ! ( whiptail \
        --title '003.User Management : Add User' \
        --yesno 'Emails do not match. Do you want to retry ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
     then
       return 1
     else
       mail_ok=true
     fi
    fi
  done

  idx=0
  if type -t sh &> /dev/null
  then
    shell[idx]="'sh' ''"
    (( idx++ ))
  fi
  if type -t bash &> /dev/null
  then
    shell[idx]="'bash' ''"
    (( idx++ ))
  fi
  if type -t zsh &> /dev/null
  then
    shell[idx]="'zsh' ''"
    (( idx++ ))
  fi
  if type -t ash &> /dev/null
  then
    shell[idx]="'ash' ''"
    (( idx++ ))
  fi
  if type -t dash &> /dev/null
  then
    shell[idx]="'dash' ''"
    (( idx++ ))
  fi
  if type -t mksh &> /dev/null
  then
    shell[idx]="'mksh' ''"
    (( idx++ ))
  fi

  shell_menu="whiptail --title '003.User Management : Add User' \
    --menu 'Which shell do you want to set for this user :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx < ${#shell[@]} ; idx++ ))
  do
    shell_menu="${shell_menu} ${shell[idx]}"
  done
  bash -c "${shell_menu}" 2> results_menu
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu )

  case ${CHOICE} in
    sh)
      usr_shell='/bin/sh'
      ;;
    bash)
      usr_shell='/bin/bash'
      ;;
    zsh)
      usr_shell='/bin/zsh'
      ;;
    ash)
      usr_shell='/bin/ash'
      ;;
    dash)
      usr_shell='/bin/dash'
      ;;
    mksh)
      usr_shell='/bin/mksh'
      ;;
    *)
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      ;;
  esac

  if ( whiptail --title '003.User Management : Add User' \
    --yesno 'Does this user will have sudo abilities ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    sudo=true
  else
    sudo=false
  fi

  if ( whiptail --title '003.User Management : Add User' \
    --yesno "Do you confirm following informations about new user : \n\
Username       : ${username} \n\
User Fullname  : ${firstname} ${lastname}  \n\
User Email     : ${mail1} \n\
User Shell     : ${usr_shell} \n\
Password       : The one you set
" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    old_gecos_info="${firstname} ${lastname},,,"
    new_gecos_info="${firstname} ${lastname},${mail2},,"
    if ${sudo}
    then
      useradd -c "${old_gecos_info}" -s ${usr_shell} -G 'sudo' -p "'${passwd1}'"  ${username}
    else
      useradd -c "${old_gecos_info}" -s ${usr_shell} -p "'${passwd1}'" ${username}
    fi
    mkdir -p /home/${username}
  else
    return 1
  fi

  old_line=$( grep "^${username}:" /etc/passwd  )
  old_line=$( echo ${old_line} | sed -e "s/\//\\\\\//g" )
  new_line=$( echo ${old_line} | sed "s/:${old_gecos_info}:/:${new_gecos_info}:/g" )
  echo "sed -i \"s/${old_line}/${new_line}/g\" /etc/passwd"

  USER_CHOOSEN=${username}
  USER_CHOOSEN_FULLNAME="${firstname} ${lastname}"
  USER_CHOOSEN_EMAIL="${email1}"
  return 0
}

user_delete() {
  local fullname
  local username
  _l="/etc/login.defs"
  _p="/etc/passwd"

  l=$(grep "^UID_MIN" $_l)
  l1=$(grep "^UID_MAX" $_l)
  awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" \
    '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' \
    "$_p" > results_menu.txt
  idx=0
  while read line
  do
    fullname[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f1 )
    username[idx]=$( echo ${line} | cut -d: -f1 )
    idx=$(( $idx + 1 ))
  done < results_menu.txt
  local nb_usr=${#username[@]}

  local delete_user="whiptail --title '003.user management : delete user' \
    --menu  'select which user you want to delete :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx=0 ; idx <= ${nb_usr}-1 ; idx++ ))
  do
    delete_user="${delete_user} '${username[idx]}' '${fullname[idx]}'"
  done

  bash -c "${delete_user} " 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )

  if ( whiptail --title '003.User Management : Delete User' \
    --yesno "Do you really want to delete user :  ${CHOICE}" 8 60 )
  then
    if ( whiptail --title '003.User Management : Delete User' \
    --yesno "Do you want to backup its data to /root/deleted_user.backup/${CHOICE}" \
    ${WT_HEIGHT} ${WT_WIDTH} )
    then
      mkdir -p /root/user.backup/${CHOICE}
      mv /home/${CHOICE} /root/deleted_users.backup/${CHOICE}/home
      mv /var/spool/mail/${CHOICE} /root/deleted_user.backup/${CHOICE}/mail
    fi
    userdel ${CHOICE}
    return 0
  else
    return 1
  fi
}

user_management() {
  local user_choosen
  local user_choosen_fullname

  local menu_user="whiptail --title '003.User Management' \
    --menu  'Select what you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Update User' 'Update user information (git/vcsh dotfiles, name, mail etc.)' \
    'Add User'    'Add a new user' \
    'Delete User' 'Delete an existing user' \
    '<-- Back'    'Back to main menu'"

  while (true)
  do
    bash -c "${menu_user} " 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 1
        ;;
      'Update User')
        user_update
        ;;
      'Add User')
        user_add
        RET=$? ; [[ ${RET} -eq 0 ]] && user_update
        ;;
      'Delete User' )
        user_delete
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}
