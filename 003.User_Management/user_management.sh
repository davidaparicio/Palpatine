#!/bin/bash

# Functions
################################################################################
set_username() {
  # Set username
  menu="whiptail --title 'User Management' \
    --inputbox 'Username for the new user (only lowerscript char)' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  while true
  do
    bash -c "${menu}" 2>results_menu.txt
    [[ $? -eq 1 ]] && return 1 || username=$( cat results_menu.txt )

    if [[ ${#username} == 0 ]]
    then
      ! ( whiptail --title 'User Management' \
        --yesno 'Username must be at least one char long.
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} ) && return 1
    elif ! [[ ${username} =~ ^[a-z]*$ ]]
    then
      ! ( whiptail --title 'User Management' \
        --yesno 'Username must contain only lowerscript char [a-z].
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} ) && return 1
    elif getent passwd ${username}
    then
      ! ( whiptail --title 'User Management' \
        --yesno 'User already exist.
Do you want to retry ?' ${WT_HEIGHT} ${WT_WIDTH} ) && return 1
    fi
  done
}

set_fullname() {
  # Set/Change fullname of the user
  menu="whiptail --title 'User Management' \
    --inputbox 'Fullname of the new user (you can leave it empty).' \
    ${WT_HEIGHT} ${WT_WIDTH} '${user_fullname}'"

  bash -c "${menu}" 2>results_menu.txt
  [[ $? -eq 1 ]] && return 1 || user_fullname=$( cat results_menu.txt )

  getent passwd ${username} && chfn -f "${user_fullname}" ${username}

  return 0
}

set_passwd () {
  # Set/Change user password
  while true
  do
    passwd ${username}
    if [[ $? -eq 0 ]]
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
  # Set/Change user email that will be store in room field in GECOS Fields
  local mail1=''
  local mail2=''
  local mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

  while true
  do
    mail1="whiptail --title 'User Management' \
      --inputbox 'Email adress of the new user' \
      ${WT_HEIGHT} ${WT_WIDTH} ${user_mail}"

    bash -c "$mail1" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || mail1=$( cat results_menu.txt )

    if [[ ! ${mail1} =~ ${mail_regex} ]]
    then
     whiptail --title 'User Management' \
       --msgbox 'This is not an email adress. Please enter one of the form : \n
     email@domain.com.' ${WT_HEIGHT} ${WT_WIDTH}
    else
      mail2="whiptail --title 'User Management' \
        --inputbox 'Please enter email adress again' ${WT_HEIGHT} ${WT_WIDTH}"

      bash -c "$mail2" 2> results_menu.txt
      [[ $? -eq 1 ]] && return 1 || mail2=$( cat results_menu.txt )

      [[ ! ${mail1} == ${mail2} ]] && ! ( whiptail \
        --title 'User Management' \
        --yesno 'Emails do not match. Do you want to retry ?' \
        ${WT_HEIGHT} ${WT_WIDTH} ) && return 1

      if [[ ${mail1} == ${mail2} ]]
      then
        user_mail=${mail2}
        chfn -r ${user_mail} ${username}
        [[ $? -eq 1 ]] && return 1 || return 0
      fi
    fi
  done
}

set_shell() {
  # Set/Change user shell
  local idx=0
  type -t sh &> /dev/null && shell[idx]="'sh' ''"  && (( idx++ ))
  type -t bash &> /dev/null && shell[idx]="'bash' ''" && (( idx++ ))
  type -t zsh &> /dev/null && shell[idx]="'zsh' ''" && (( idx++ ))
  type -t ash &> /dev/null && shell[idx]="'ash' ''" && (( idx++ ))
  type -t dash &> /dev/null && shell[idx]="'dash' ''" && (( idx++ ))
  type -t mksh &> /dev/null && shell[idx]="'mksh' ''" && (( idx++ ))

  menu="whiptail --title 'User Management' \
    --menu 'Which shell do you want to set for this user :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx < ${#shell[@]} ; idx++ ))
  do
    menu="${menu} ${shell[idx]}"
  done

  bash -c "${menu}" 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1 || CHOICE=$( cat results_menu.txt )

  case ${CHOICE} in
    sh)
      user_shell='/bin/sh'
      ;;
    bash)
      user_shell='/bin/bash'
      ;;
    zsh)
      user_shell='/bin/zsh'
      ;;
    ash)
      user_shell='/bin/ash'
      ;;
    dash)
      user_shell='/bin/dash'
      ;;
    mksh)
      user_shell='/bin/mksh'
      ;;
    *)
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      ;;
  esac
  chsh -s ${user_shell} ${username}
}

set_git_config() {
  # Set global git configuration to avoid doing it later
  if ( whiptail --title 'User Management' \
    --yesno "Script will now running following command for user ${username}: \n\
      - 'git config --global user.name '${user_fullname}' \n\
      - 'git config --global user.email '${user_mail}'  \n\
      - 'git config --global push.default matching \n\n\
      You will now be ask password for user ${username}" \
      ${WT_HEIGHT} ${WT_WIDTH})
  then
    sudo -H -u ${username} git config --global user.name "${user_fullname}"
    sudo -H -u ${username} git config --global user.email ${user_mail}
    sudo -H -u ${username} git config --global push.default matching
  else
    return 1
  fi
  return 0
}

set_ssh_key() {
  # Generate SSH key for user, based on its email adress
  local id_rsa_file
  local content_rsa
  [[ ${username} == "root" ]] \
    && id_rsa_file="/root/.ssh/id_rsa" \
    || id_rsa_file="/home/${username}/.ssh/id_rsa"

  if ( whiptail --title 'User Management' --yesno "Script will now create an ssh key \
for user ${username} with this email : ${user_mail}.

Do you want to continue ?" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    menu="whiptail --title 'User Management' \
      --inputbox 'Where do you want to save your SSH Key :' \
      ${WT_HEIGHT} ${WT_WIDTH} '${id_rsa_file}'"

    bash -c "${menu}" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || id_rsa_file=$( cat results_menu.txt )

    sudo -H -u ${username} ssh-keygen -t rsa -b 4096 -C ${user_mail} -f ${id_rsa_file}

    whiptail --title 'User Management' --msgbox "Next screen will be the \
content of your public key ${id_rsa_file}.pub. You can copy it and paste it to \
you favorite version control system/website :

NOTE : If you are not connected through SSH this can be complicated for you. \
Unfortunately, there is nothing the script can do for you, but you can do it \
manually by searching 'add SSH Key github' in your favorite web searcher." \
    ${WT_HEIGHT} ${WT_WIDTH}

    clear
    echo "======================================="
    sudo -H -u ${username} cat ${id_rsa_file}.pub
    echo "======================================="
    echo "Press Enter to continue"
    read
  fi
}

set_dotfiles() {
  # Propose to clone dotfiles in one command
  local dotfile_cmd='vcsh clone git@bitbucket.com:vcsh/mr.git; cd ${HOME} && mr up'
  menu="whiptail --title 'User Management' \
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
${WT_HEIGHT} ${WT_WIDTH}"

  while true
  do
    menu="${menu} '${dotfile_cmd}'"

    bash -c "${menu}" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || dotfile_cmd=$( cat results_menu.txt )

    if ( whiptail --title 'User Management' \
      --yesno "Are your sure that this is the command you want to run for user \
${username} :

  ${dotfile_cmd}" ${WT_HEIGHT} ${WT_WIDTH} )
    then
      echo "#/!bin/bash"    > cmd.sh
      echo "${dotfile_cmd}" > cmd.sh
      chmod 777 cmd.sh
      sudo -H -u ${username} ./cmd.sh

      echo =================================================================
      echo You can take a look at installation log above
      echo Press Enter to continue
      echo =================================================================
      read

      cd $DIR
      whiptail --title 'User Management' \
        --yesno 'Does everything went ok ?' ${WT_HEIGHT} ${WT_WIDTH} && return 0
    fi

    ! ( whiptail --title 'User Management' \
      --yesno 'Do you want to retry ?' ${WT_HEIGHT} ${WT_WIDTH} ) && return 0
  done
}

set_sudo() {
  whiptail --title 'User Management' \
    --yesno 'Does this user will have sudo abilities ?' ${WT_HEIGHT} ${WT_WIDTH} \
    && sudo=true || sudo=false
}

choose_user() {
  # Menu that parse users and propose a list with user to choose
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
  [[ ! ${mail[0]} =~ ${mail_regex} ]] && mail[0]=''

  while read line
  do
    username[idx]=$( echo ${line} | cut -d: -f1 )
    fullname[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f1 )
    mail[idx]=$( echo ${line} | cut -d: -f5 | cut -d, -f2 )
    [[ ! ${mail[idx]} =~ ${mail_regex} ]] && mail[idx]=''
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
  [[ $? -eq 1 ]] && return 1

  username=$( cat results_menu.txt )
  user_fullname=$( grep "^$username:" /etc/passwd | cut -d: -f5 | cut -d, -f1 )
  user_mail=$( grep "^$username:" /etc/passwd | cut -d: -f5 | cut -d, -f2 )
  user_shell=$( grep "^$username:" /etc/passwd | cut -d: -f6 | cut -d, -f1 )
  [[ ! ${user_mail} =~ ${mail_regex} ]] && user_mail=''

  return 0
}

user_update() {
  # Updating user, choose one and access to functions menu
  if [[ ${#user_mail} -eq 0 ]] && ( whiptail \
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
    'Change shell'    'Change shell of the user'"

    ! [[ ${#user_mail} -eq 0 ]] \
      && update_menu="${update_menu} \
    'Set SSH Key'    'Generate or overwrite SSH Key of the user' \
    'Git config'     'Set git config variables' \
    'Clone dotfiles' 'Clone versioned dotiles'"

    update_menu="${update_menu} \
    '<-- Back' 'Back to User Management menu'"

    bash -c "${update_menu}" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || CHOICE=$( cat results_menu.txt )

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
  # Adding user, go through all function. If fail, go back
  set_username
  [[ $? -eq 1 ]] && return 1

  set_fullname
  [[ $? -eq 1 ]] && return 1

  set_sudo
  [[ $? -eq 1 ]] && return 1

  if ( whiptail --title 'User Management' \
    --yesno "Do you confirm following informations about new user :
Username       : ${username}
User Fullname  : ${user_fullname}" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    ${sudo} \
      && useradd -m -c "${user_fullname}" -G 'sudo'  ${username} \
      || useradd -m -c "${user_fullname}" ${username}
    [[ $? -eq 1 ]] && return 1
    mkdir -p /home/${username}
  else
    return 1
  fi
  whiptail --title 'User Management' --msgbox "User successfully created.

Please provide a password for the new user.

WARNING : If you abort password setup, user ${username} will exist with no \
password, meaning that anyone will be alowed to connect this. This can be \
dangerous, especially if this user have sudo abilities !!." \
  ${WT_HEIGHT} ${WT_WIDTH}

  set_passwd
  [[ $? -eq 1 ]] && return 1

  set_shell
  [[ $? -eq 1 ]] && return 1

  set_email
  [[ $? -eq 1 ]] && return 1

  set_ssh_key
  [[ $? -eq 1 ]] && return 1

  if type -t git &> /dev/null
  then
    set_git_config
    [[ $? -eq 1 ]] && return 1
  fi

  set_dotfiles
  [[ $? -eq 1 ]] && return 1

  return 0
}

user_delete() {
  # Deleting choosen user and propose to make backup into root dir
  local date=$( date '+%Y-%m-%d' )
  while true
  do
    if [[ ${username} == 'root' ]]
    then
      whitpail --title 'User Management' \
      --msgbox "You cannot delete user 'root'." ${WT_HEIGHT} ${WT_WIDTH}
    elif ( whiptail --title 'User Management' \
      --yesno "Do you really want to delete user :  ${username}" \
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      if ( whiptail --title 'User Management' \
      --yesno "Do you want to backup its data to /root/deleted_user.backup/${username}.${date}" \
      ${WT_HEIGHT} ${WT_WIDTH} )
      then
        mkdir -p /root/deleted_users.backup/${username}.${date}
        mv /home/${username} /root/deleted_users.backup/${username}.${date}/home
        mv /var/spool/mail/${username} /root/deleted_user.backup/${username}${date}/mail
      fi
      userdel -r ${username} 2>&1 > /dev/null
    fi

    ! ( whiptail --title 'User Management' \
      --yesno 'Do you want to delete another user ?' \
        ${WT_HEIGHT} ${WT_WIDTH} ) && return 0
  done
}

user_management() {
  # Main menu about user management
  menu="whiptail --title 'User Management' \
    --menu  'Select what you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Update User' 'Update user information (git/vcsh dotfiles, name, mail etc.)' \
    'Add User'    'Add a new user' \
    'Delete User' 'Delete an existing user' \
    '<-- Back'    'Back to main menu'"

  while true
  do
    bash -c "${menu} " 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Update User')
        choose_user
        [[ $? -eq 0 ]] && user_update
        ;;
      'Add User')
        username=''
        user_add
        ! [[ ${username} == '' ]] && user_update \
          || whiptail --title 'User Management' \
            --msgbox 'An error occured when adding a new user. User not created' \
            ${WT_HEIGHT} ${WT_WIDTH}
        ;;
      'Delete User' )
        choose_user
        [[ $? -eq 0 ]] && user_delete
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}
