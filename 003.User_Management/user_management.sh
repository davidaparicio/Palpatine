#!/bin/bash

set_username() {
  local username_menu
  while true
  do
    username_menu="whiptail --title 'User Management' \
      --inputbox 'Username for the new user (only lowerscript char)' \
      ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${username_menu}" 2>results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    USERNAME=$( cat results_menu.txt )
    if [[ ${#USERNAME} == 0 ]]
    then
      if ! ( whiptail --title 'User Management' \
        --yesno 'Username must be at least one char long. \n\n
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    elif ! [[ ${USERNAME} =~ ^[a-z]*$ ]]
    then
      if ! ( whiptail --title 'User Management' \
        --yesno 'Username must contain only lowerscript char [a-z]. \n\n
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    elif getent passwd ${USERNAME}
    then
      if ! ( whiptail --title 'User Management' \
        --yesno 'User already exist. \n\n
Do you want to retry ?' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    else
      return 0
    fi
  done
}

set_fullname() {
  local fullname_menu
  fullname_menu="whiptail --title 'User Management' \
    --inputbox 'Fullname of the new user (you can leave it empty).' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${fullname_menu}" 2>results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  USER_FULLNAME=$( cat results_menu.txt )
  return 0
}

set_passwd () {
  while true
  do
    passwd ${USERNAME}
    RET=$?
    if [[ ${RET} -eq 0 ]]
    then
      whiptail --title 'User Management' \
        --msgbox 'Password changed successfully' ${WT_HEIGHT} ${WT_WIDTH}
      return 0
    elif ! ( whiptail --title 'User Management' \
      --yesno 'Failed to change password. Do you want to retry ?' \
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 1
    fi
  done
}

set_mail() {
  local mail1=''
  local mail2=''
  local mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

  while true
  do
    mail1="whiptail --title 'User Management' \
      --inputbox 'Email adress of the new user' \
      ${WT_HEIGHT} ${WT_WIDTH} ${USER_MAIL}"

    bash -c "$mail1" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    mail1=$( cat results_menu.txt )

    if [[ ! ${mail1} =~ ${mail_regex} ]]
    then
     whiptail --title 'User Management' \
       --msgbox 'This is not an email adress. Please enter one of the form : \n
     email@domain.com.' ${WT_HEIGHT} ${WT_WIDTH}
    else
      mail2="whiptail --title 'User Management : Add User' \
        --inputbox 'Please enter email adress again' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "$mail2" 2> results_menu.txt
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      mail2=$( cat results_menu.txt )
      if [[ ! ${mail1} == ${mail2} ]] && ! ( whiptail \
        --title 'User Management : Add User' \
        --yesno 'Emails do not match. Do you want to retry ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
     then
       return 1
     else
       USER_MAIL=${mail1}
       return 0
     fi
    fi
  done
}

set_shell() {
  local shell_menu

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

  shell_menu="whiptail --title 'User Management' \
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
      USER_SHELL='/bin/sh'
      ;;
    bash)
      USER_SHELL='/bin/bash'
      ;;
    zsh)
      USER_SHELL='/bin/zsh'
      ;;
    ash)
      USER_SHELL='/bin/ash'
      ;;
    dash)
      USER_SHELL='/bin/dash'
      ;;
    mksh)
      USER_SHELL='/bin/mksh'
      ;;
    *)
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      ;;
  esac

  chsh -s ${USER_SHELL} ${USERNAME}
}

set_git_config() {
  if ( whiptail --title 'User Management'
    --yesno "Script will now running following command for user ${USERNAME}: \n\
      - 'git config --global user.name '${USER_FULLNAME}' \n\
      - 'git config --global user.email '${USER_MAIL}'  \n\
      - 'git config --global push.default matching \n\n\
      You will now be ask password for user ${USERNAME}" \
      ${WT_HEIGHT} ${WT_WIDTH})
  then
    su ${USERNAME} -c \
      "git config --global user.name '${USER_FULLNAME}';\
       git config --global user.email '${USER_MAIL}'; \
       git config --global push.default matching;"
  else
    return 1
  fi
  return 0
}

set_ssh_key() {
  echo
}

set_dotfiles() {
  echo
}

choose_user() {
  local username[0]=$( grep "^root:" /etc/passwd | cut -d: -f1 )
  local fullname[0]=$( grep "^root:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
  local mail[0]=$( grep "^root:" /etc/passwd | cut -d: -f5 | cut -d, -f2 )
  local _l='/etc/login.defs'
  local _p='/etc/passwd'

  local l=$(grep "^UID_MIN" $_l)
  local l1=$(grep "^UID_MAX" $_l)
  awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" \
    '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' \
    "$_p" > results_menu.txt
  idx=1
  while read line
  do
    username[idx]=$( echo ${line} | cut -d: -f1 )
    fullname[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f1 )
    mail[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f2 )
    (( idx++ ))
  done < results_menu.txt
  local nb_usr=${#username[@]}

  local update_user="whiptail --title 'User management' \
    --menu  'select which user you want to update :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx <= ${nb_usr}-1 ; idx++ ))
  do
    update_user="${update_user} '${username[idx]}' '${fullname[idx]} ${mail[idx]}'"
  done

  bash -c "${update_user} " 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  USER_CHOOSEN=$( cat results_menu.txt )
  USER_FULLNAME=$( grep "^$USER_CHOOSEN:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
  USER_MAIL=$( grep "^$USER_CHOOSEN:" /etc/passwd | cut -d: -f5 | cut -d, -f2 )
  return 0
}

user_update() {
  local USER_CHOOSEN
  local USER_FULLNAME
  local USER_MAIL
  local update_menu

  choose_user

  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  if [[ ${#USER_MAIL} -eq 0 ]] && ( whiptail \
    --title 'User Management : Update User' \
    --yesno "User does not seem to have an email adress set. Do you want to \
set it now ?
If not, you won't be propose to update/make ssh key, set/update git config, \
clone dotfiles etc. You still can set it later in the main 'Update User' menu." )
  then
    set_email
  fi

  update_menu="whiptail --title 'User Management : Update User' \
    --menu 'Choose action you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}
    'Change fullname' 'Update fullname of the user'
    'Change password' 'Change password of the user'
    'Change email'    'Change email of the user'
    'Change shell'    'Change shell of the user'
    'Git config'      'Set git config variables'"
  while true
  do
    if ! [[ ${#USER_MAIL} -eq 0 ]]
    then
      update_menu="${update_menu} \
        'Set SSH Key'    'Generate or overwrite SSH Key of the user' \
        'Clone dotfiles' 'Clone versioned dotiles'"
    fi
    update_menu="${update_menu} '<-- Back' 'Back to User Management menu'"

    bash -c ${update_menu} 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    ${CHOICE}=$( cat results_menu.txt )

    case ${CHOICE} in
      'Change fullname')
        set_fullname
        ;;
      'Change password')
        set_passwd
        ;;
      'Change email')
        set_email
        ;;
      'Change shell')
        set_shell
        ;;
      'Git config')
        set_git_config
        ;;
      'Set SSH Key')
        set_ssh_key
        ;;
      'Clone dotfiles')
        set_dotfiles
        ;;
      '<-- Back')
        return 0
    esac
  done
}

user_add () {
  local USER_FULLNAME=''
  local USER_SHELL=''
  local USER_MAIL=''
  local USERNAME=''

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

  set_username

  set_fullname

  while ! ${passwd_ok}
  do
    passwd1="whiptail --title 'User Management' \
    --passwordbox 'Password for the new user' ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${passwd1}" 2>results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    passwd1=$( cat results_menu.txt )

    if ! [[ ${passwd1} =~ ${passwd_regex} ]]
    then
      whiptail --title 'User Management' \
        --msgbox 'Password must be at least eight char long and contains only \
alphanumeric char either lowercase or uppercase and the following predefined \
characters  : @ * # - _ = ! ? % &.' ${WT_HEIGHT} ${WT_WIDTH}
    else
      local passwd2="whiptail --title 'User Management : Add User' \
        --passwordbox 'Please enter the password again.' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "${passwd2}" 2> results_menu.txt
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      passwd2=$( cat results_menu.txt )
      if [[ ! ${passwd1} == ${passwd2} ]]
      then
        whiptail --title 'User Management' \
          --msgbox 'Passwords do not match. Please retry.' ${WT_HEIGHT} ${WT_WIDTH}
      else
        passwd_ok=true
      fi
    fi
  done

  set_email

  set_shell

  if ( whiptail --title 'User Management' \
    --yesno 'Does this user will have sudo abilities ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    sudo=true
  else
    sudo=false
  fi

  if ( whiptail --title 'User Management : Add User' \
    --yesno "Do you confirm following informations about new user : \n\
Username       : ${USERNAME} \n\
User Fullname  : ${USER_FULLNAME} \n\
User Email     : ${USER_MAIL} \n\
User Shell     : ${USER_SHELL} \n\
Password       : The one you set
" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    old_gecos_info="${USER_FULLENAME},,,"
    new_gecos_info="${USER_FULLENAME},${USER_MAIL},,"
    if ${sudo}
    then
      useradd -c "${old_gecos_info}" -s ${USER_SHELL} -G 'sudo' -p "'${passwd1}'"  ${USERNAME}
    else
      useradd -c "${old_gecos_info}" -s ${USER_SHELL} -p "'${passwd1}'" ${USERNAME}
    fi
    mkdir -p /home/${USERNAME}
  else
    return 1
  fi

  old_line=$( grep "^${USERNAME}:" /etc/passwd  )
  old_line=$( echo ${old_line} | sed -e "s/\//\\\\\//g" )
  new_line=$( echo ${old_line} | sed "s/:${old_gecos_info}:/:${new_gecos_info}:/g" )
  sed -i "s/${old_line}/${new_line}/g" /etc/passwd
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  if type -t git &> /dev/null
  then
    if ( whiptail --title 'User Management' \
      --yesno 'Do you want to apply git configuration for this user ?' )
    then
      set_git_config
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    fi
  fi

  if ( whiptail --title 'User Management' \
    --yesno "User successfully created.
Do you want to generate a SSH for user ${username} ?

WARNING : If you don't do it know, you won't be propose to clone ssh dotfiles \
for this user BUT you can do it later by choosing 'Update User' in 'User \
Management' main menu." )
  then
    set_ssk_key
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    set_dotfiles
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  return 0
}

user_delete() {
  local USERNAME

  while true
  do
    choose_user

    if [[ ${USERNAME} == 'root' ]] && ( whitpail --title 'User Management' \
      --yesno "You cannot delete user 'root'. Do you want to delete another user ?" \
        ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 0
    fi

    if ( whiptail --title 'User Management' \
      --yesno "Do you really want to delete user :  ${USERNAME}" \
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      if ( whiptail --title 'User Management' \
      --yesno "Do you want to backup its data to /root/deleted_user.backup/${USERNAME}" \
      ${WT_HEIGHT} ${WT_WIDTH} )
      then
        mkdir -p /root/user.backup/${USERNAME}
        mv /home/${USERNAME} /root/deleted_users.backup/${USERNAME}/home
        mv /var/spool/mail/${USERNAME} /root/deleted_user.backup/${USERNAME}/mail
      fi
      userdel ${USERNAME}
    fi

    if ( whitpail --title 'User Management' \
      --yesno 'Do you want to delete another user ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 0
    fi
  done
}

user_management() {
  local menu_user="whiptail --title 'User Management' \
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
