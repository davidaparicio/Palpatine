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
    ${WT_HEIGHT} ${WT_WIDTH} '${USER_FULLNAME}'"
  bash -c "${fullname_menu}" 2>results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  USER_FULLNAME=$( cat results_menu.txt )
  chfn -f "${USER_FULLNAME}" ${USERNAME}
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

set_email() {
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
      mail2="whiptail --title 'User Management' \
        --inputbox 'Please enter email adress again' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "$mail2" 2> results_menu.txt
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      mail2=$( cat results_menu.txt )
      if [[ ! ${mail1} == ${mail2} ]] && ! ( whiptail \
        --title 'User Management' \
        --yesno 'Emails do not match. Do you want to retry ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
     then
       return 1
     fi
     if [[ ${mail1} == ${mail2} ]]
     then
       USER_MAIL=${mail2}
       chfn -r ${USER_MAIL} ${USERNAME}
       RET=$? ; [[ ${RET} -eq 1 ]] && return 1
       return 0
     fi
    fi
  done
}

set_shell() {
  local shell_menu
  local idx=0
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
  bash -c "${shell_menu}" 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )

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
  if ( whiptail --title 'User Management' \
    --yesno "Script will now running following command for user ${USERNAME}: \n\
      - 'git config --global user.name '${USER_FULLNAME}' \n\
      - 'git config --global user.email '${USER_MAIL}'  \n\
      - 'git config --global push.default matching \n\n\
      You will now be ask password for user ${USERNAME}" \
      ${WT_HEIGHT} ${WT_WIDTH})
  then
    sudo -H -u ${USERNAME} git config --global user.name ${USER_FULLNAME}
    sudo -H -u ${USERNAME} git config --global user.email ${USER_MAIL}
    sudo -H -u ${USERNAME} git config --global push.default matching
  else
    return 1
  fi
  return 0
}

set_ssh_key() {
  local id_rsa_file
  local content_rsa
  if [[ ${USERNAME} == "root" ]]
  then
    id_rsa_file="/root/.ssh/id_rsa"
  else
    id_rsa_file="/home/${USERNAME}/.ssh/id_rsa"
  fi
  if ( whiptail --title 'User Management' --yesno "Script will now create an ssh key \
for user ${USERNAME} with this email : ${USER_MAIL}.

Do you want to continue ?" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    rsa_file_menu="whiptail --title 'User Management' \
      --inputbox 'Where do you want to save your SSH Key :' \
      ${WT_HEIGHT} ${WT_WIDTH} '${id_rsa_file}'"
    bash -c "${rsa_file_menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    id_rsa_file=$( cat results_menu.txt )

    sudo -H -u ${USERNAME} ssh-keygen -t rsa -b 4096 -C ${USER_MAIL} -f ${id_rsa_file}


    whiptail --title 'User Management' --msgbox "Next screen will be the \
content of your public key ${id_rsa_file}.pub. You can copy it and paste it to \
you favorite version control system/website :

NOTE : If you are not connected through SSH this can be complicated for you. \
Unfortunately, there is nothing the script can do for you, but you can do it \
manually by searching 'add SSH Key github' in your favorite web searcher." \
    ${WT_HEIGHT} ${WT_WIDTH}

    clear
    echo "======================================="
    sudo -H -u ${USERNAME} cat ${id_rsa_file}.pub
    echo "======================================="
    echo "Press Enter to continue"
    read
  fi
}

set_dotfiles() {
  local dotfile_cmd='vcsh clone git@github.com:user/myRepo.git; cd ~/; mr up'
  local dotfile_menu="whiptail --title 'User Management' \
    --inputbox 'Please enter the command line that will allow you to clone your \
dotfiles such that :
  - vcsh clone git@github.com:user/repo.git repo ; cd ~/; mr up
  - git clone git@github.com:user/repo.git ~/repo; ~/repo/do_symlink
  - wget https://domain.com/path/to/script/install.sh -O -
  - curl -fsSL https://domain.com/path/to/script/sh
  - etc.

NOTE : No verification will be done, you will just be prompt if everything went \
ok, and if not you can retry.
Moreover, if you clone via SSH but do not have set SSH Key neither uplooad it to \
your favorite version control website/system, some part might not run well.' \
${WT_HEIGHT} ${WT_WIDTH} 'vcsh clone git@github.com:user/repo.git repo ; cd ~/ ; mr up'"

  while true
  do
    bash -c "${dotfile_menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    dotfile_cmd=$( cat results_menu.txt )

    if ( whiptail --title 'User Management' \
      --yesno "Are your sure that this is the command you want to run for user \
${USERNAME} :

  ${dotfile_cmd}" ${WT_HEIGHT} ${WT_WIDTH} )
    then
      echo "#/!bin/bash"    > cmd.sh
      echo "${dotfile_cmd}" > cmd.sh
      chmod 777 cmd.sh
      sudo -H -u ${USERNAME} ./cmd.sh
      cd $DIR
      if ( whiptail --title 'User Management' \
        --yesno 'Does everything went ok ?' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 0
      elif ! ( whiptail --title 'User Management' \
        --yesno 'Do you want to retry ?' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    fi
    if ! ( whiptail --title 'User Management' \
      --yesno 'Do you want to retry ?' ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 0
    fi
  done
}

choose_user() {
  local mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
  local username[0]=$( grep "^root:" /etc/passwd | cut -d: -f1 )
  local fullname[0]=$( grep "^root:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
  local mail[0]=$( grep "^root:" /etc/passwd | cut -d: -f5 | cut -d, -f2 )
  local nb_usr
  local update_user
  local _l='/etc/login.defs'
  local _p='/etc/passwd'

  local l=$(grep "^UID_MIN" $_l)
  local l1=$(grep "^UID_MAX" $_l)
  awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" \
    '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' \
    "$_p" > results_menu.txt

  idx=1
  if [[ ! ${mail[0]} =~ ${mail_regex} ]]
  then
    mail[0]=''
  fi
  while read line
  do
    username[idx]=$( echo ${line} | cut -d: -f1 )
    fullname[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f1 )
    mail[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f2 )
    if [[ ! ${mail[idx]} =~ ${mail_regex} ]]
    then
      mail[idx]=''
    fi
    (( idx++ ))
  done < results_menu.txt
  nb_usr=${#username[@]}

  update_user="whiptail --title 'User management' \
    --menu  'select which user you want to update :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx < ${nb_usr} ; idx++ ))
  do
    update_user="${update_user} '${username[idx]}' '${fullname[idx]} <${mail[idx]}>'"
  done

  bash -c "${update_user} " 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  USERNAME=$( cat results_menu.txt )
  USER_FULLNAME=$( grep "^$USERNAME:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
  USER_MAIL=$( grep "^$USERNAME:" /etc/passwd | cut -d: -f5 | cut -d, -f2 )
  USER_SHELL=$( grep "^$USERNAME:" /etc/passwd | cut -d: -f6 | cut -d, -f1 )
  if [[ ! ${USER_MAIL} =~ ${mail_regex} ]]
  then
    USER_MAIL=''
  fi
  return 0
}

user_update() {
  local USERNAME=''
  local USER_FULLNAME=''
  local USER_MAIL=''
  local USER_SHELL=''
  local update_menu

  choose_user
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  if [[ ${#USER_MAIL} -eq 0 ]] && ( whiptail \
    --title 'User Management : Update User' \
    --yesno "User does not seem to have an email adress set. Do you want to \
set it now ?
If not, you won't be propose to update/make ssh key, set/update git config, \
clone dotfiles etc. You still can set it later in the main 'Update User' menu." \
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    set_email
  fi

 while true
  do
    update_menu="whiptail --title 'User Management' \
    --menu 'Choose action you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Change fullname' 'Update fullname of the user' \
    'Change password' 'Change password of the user' \
    'Change email'    'Change email of the user' \
    'Change shell'    'Change shell of the user' \
    'Git config'      'Set git config variables'"
    if ! [[ ${#USER_MAIL} -eq 0 ]]
    then
      update_menu="${update_menu} \
        'Set SSH Key'    'Generate or overwrite SSH Key of the user' \
        'Clone dotfiles' 'Clone versioned dotiles'"
    fi
    update_menu="${update_menu} '<-- Back' 'Back to User Management menu'"

    bash -c "${update_menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
       '<-- Back')
        return 0
        ;;
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
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}

user_add () {
  local USER_FULLNAME=''
  local USER_SHELL=''
  local USER_MAIL=''
  local USERNAME=''

  local passwd_regex='[a-zA-Z0-9@*#\-_=!?%&]{8,}'
  # REGEX PASSWORD
  #^([a-zA-Z0-9@*#_]{8,15})$
  #Description
  #Password matching expression.
  #Match all alphanumeric character and predefined wild characters.
  #Password must consists of at least 8 characters and not more than 15 characters.
  local passwd1=''
  local passwd2=''

  set_username
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  set_fullname
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

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
" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    if ${sudo}
    then
      useradd -m -c "${USER_FULLNAME}" -G 'sudo'  ${USERNAME}
    else
      useradd -m -c "${USER_FULLNAME}" ${USERNAME}
    fi
    mkdir -p /home/${USERNAME}
  else
    return 1
  fi

  whiptail --title 'User Management' --msgbox "User successfully created.

Please provide a password for the new user.

WARNING : If you abort process, user ${USERNAME} will exist with no password, \
meaning that anyone will be alowed to connect this. This can be dangerous, \
especially if this user have sudo abilities !!." ${WT_HEIGHT} ${WT_WIDTH}
  set_passwd
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  set_shell
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  if ( whiptail --title 'User Management' \
    --yesno "Do you want to set an email adress for this user ?
If no, script will not ask you to set git configuration, neither to set SSH \
Key, nor to set clone your dotfiles" \
  ${WT_HEIGHT} ${WT_WIDTH} )
  then
    set_email
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    if type -t git &> /dev/null
    then
      if ( whiptail --title 'User Management' \
        --yesno 'Do you want to apply git configuration for this user ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
      then
        set_git_config
        RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      fi
    fi

    if ( whiptail --title 'User Management' \
      --yesno "Do you want to generate a SSH Key for user ${username} ?

WARNING : If you don't do it know, you won't be propose to clone ssh dotfiles \
for this user BUT you can do it later by choosing 'Update User' in 'User \
Management' main menu." ${WT_HEIGHT} ${WT_WIDTH} )
    then
      set_ssh_key
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
      set_dotfiles
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    fi
  fi

  return 0
}

user_delete() {
  local USERNAME=''
  local date

  while true
  do
    choose_user
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1

    if [[ ${USERNAME} == 'root' ]]
    then
      if ! ( whitpail --title 'User Management' \
      --yesno "You cannot delete user 'root'. Do you want to delete another user ?" \
        ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 0
      fi
    elif ( whiptail --title 'User Management' \
      --yesno "Do you really want to delete user :  ${USERNAME}" \
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      date=$( date '+%Y-%m-%d' )
      if ( whiptail --title 'User Management' \
      --yesno "Do you want to backup its data to /root/deleted_user.backup/${USERNAME}.${date}" \
      ${WT_HEIGHT} ${WT_WIDTH} )
      then
        mkdir -p /root/deleted_users.backup/${USERNAME}.${date}
        mv /home/${USERNAME} /root/deleted_users.backup/${USERNAME}.${date}/home
        mv /var/spool/mail/${USERNAME} /root/deleted_user.backup/${USERNAME}${date}/mail
      fi
      userdel -r ${USERNAME} 2>&1 > /dev/null
    fi

    if ! ( whiptail --title 'User Management' \
      --yesno 'Do you want to delete another user ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
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

  while true
  do
    bash -c "${menu_user} " 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Update User')
        user_update
        ;;
      'Add User')
        user_add
        RET=$? ; [[ ${RET} -eq 1 ]] && whiptail --title 'User Management' \
          --msgbox 'An error occured when adding a new user.
Process Aborted' ${WT_HEIGHT} ${WT_WIDTH}
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
