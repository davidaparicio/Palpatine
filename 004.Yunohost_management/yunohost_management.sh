#!/bin/bash

ynh_install_off_app() {
  # Install official Yunohost app
  [[ ${update_app} == true ]] && ynh_get_apps
  update_app=false
  local idx
  local install_menu="whiptail --title 'Yunohost Management' \
    --checklist 'Choose application you want to install' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx < ${#APP_ID[@]} ; idx++ ))
  do
    if [[ ${APP_INSTALL[idx]} == ' False' ]]
    then
      install_menu="${install_menu} \
        \"${APP_NAME[idx]}\" \"${APP_DESC[idx]}\" OFF"
    fi
  done

  bash -c "${install_menu}" 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  if ! [[ ${#CHOICE} -eq 0 ]]
  then
    for (( idx = 0 ; idx < ${#APP_ID[@]} ; idx ++ ))
    do
      if [[ ${CHOICE} =~ ${APP_NAME[idx]} ]]
      then
        yunohost app install ${APP_ID[idx]}
        [[ $? -eq 1 ]] && whiptail --title 'Yunohost Management' \
          --msgbox "Sorry but an error occured during installation of \
${APP_NAME[idx]}. Try to install it through the web interface" \
          ${WT_HEIGHT} ${WT_WIDTH} || update_app=true
      fi
    done
  fi
  echo =================================================================
  echo You can take a look at log above
  echo Press Enter to continue
  echo =================================================================
  read
}

ynh_install_unoff_app() {
  # Install unofficial Yunohost app from github url
  local unoff_app_menu="whiptail --title 'Yunohost Management' \
    --inputbox 'Pleaser enter the github url of the Yunohost app' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  while true
  do
    bash -c "${unoff_app_menu}" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )
    yunohost app install ${CHOICE}
    [[ $? -eq 1 ]] && whiptail --title 'Yunohost Management' \
      --msgbox "Sorry but an error occured during installation of \
${APP_NAME[idx]}. Try to install it through the web interface" \
      ${WT_HEIGHT} ${WT_WIDTH} || update_app=true
    if ! ( whiptail --title 'Yunohost Management' \
       --yesno 'Do you want to install another unofficial Yunohost app ?' \
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 0
    fi
  done
  echo =================================================================
  echo You can take a look at log above
  echo Press Enter to continue
  echo =================================================================
  read
}

ynh_remove_app() {
  # Ask which Yunohost app to remove
  [[ ${update_app} == true ]] && ynh_get_apps
  update_app=false
  local idx
  local remove_menu="whiptail --title 'Yunohost Management' \
    --checklist 'Choose application you want to uninstall' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx < ${#APP_ID[@]} ; idx++ ))
  do
    if [[ ${APP_INSTALL[idx]} == ' True' ]]
    then
      remove_menu="${remove_menu} \
        \"${APP_NAME[idx]}\" \"${APP_DESC[idx]}\" OFF"
    fi
  done

  bash -c "${remove_menu}" 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  if ! [[ ${#CHOICE} -eq 0 ]]
  then
    for (( idx = 0 ; idx < ${#APP_ID[@]} ; idx ++ ))
    do
      if [[ ${CHOICE} =~ ${APP_NAME[idx]} ]]
      then
        yunohost app remove ${APP_ID[idx]}
        [[ $? -eq 1 ]] && whiptail --title 'Yunohost Management' \
          --msgbox "Sorry but an error occured during uninstallation of \
${APP_NAME[idx]}. Try to install it through the web interface" \
          ${WT_HEIGHT} ${WT_WIDTH} || update_app=true
      fi
    done
  fi
  echo =================================================================
  echo You can take a look at log above
  echo Press Enter to continue
  echo =================================================================
  read
}

ynh_get_apps() {
  # Parse Yunohost official and installed app informations
  clear
  echo 'Please wait while updating apps informations'
  idx=0
  while read line
  do
    while read app_line
    do
      if grep -q 'description' <<< ${app_line}
      then
        APP_DESC[idx]=$( echo ${app_line} | cut -d: -f2 )
      fi
      if grep -q 'installed' <<< ${app_line}
      then
        APP_INSTALL[idx]=$( echo ${app_line} | cut -d: -f2 )
      fi
      if grep -q 'id' <<< ${app_line}
      then
        APP_ID[idx]=$( echo ${app_line} | cut -d: -f2 )
      fi
      if grep -q 'name' <<< ${app_line}
      then
        APP_NAME[idx]=$( echo ${app_line} | cut -d: -f2 )
      fi
    done <<< "$( sudo yunohost app list | grep -A 5 "^  $line" )"
    (( idx++ ))
  done <<<  "$( sudo yunohost app list | grep '^  [0-9]*: ')"
}

ynh_app() {
  # Main menu to manage Yunohost app
  local APP_DESC=''
  local APP_INSTALL=''
  local APP_ID=''
  local APP_NAME=''
  local update_app=true

  local ynh_user_menu="whiptail --title 'Yunohost Management' \
    --menu  'Select what you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Install Official Apps'    'Install official yunohost apps' \
    'Install Unofficial Apps'  'Install unofficial yunohost apps from github' \
    'Remove Apps'              'Remove already install apps' \
    '<-- Back'                 'Back to main menu'"

  while true
  do
    bash -c "${ynh_user_menu} " 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Install Official Apps')
        ynh_install_off_app
        ;;
      'Install Unofficial Apps')
        ynh_install_unoff_app
        ;;
      'Remove Apps')
        ynh_remove_app
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}

ynh_set_username() {
  # Set Yunohost username
  local tmp_username=''
  local ynh_username="whiptail --title 'Yunohost Management' \
    --inputbox 'Username for the new user (only lowerscript char)' \
    ${WT_HEIGHT} ${WT_WIDTH} ${ynh_username}"
  while true
  do
    bash -c "${ynh_username}" 2>results_menu.txt
    [[ $? -eq 1 ]] && return 1
    tmp_username=$( cat results_menu.txt )
    if [[ ${#tmp_username} == 0 ]]
    then
      if ! ( whiptail --title 'Yunohost Management' \
        --yesno 'Username must be at least one char long. \n\n
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    elif ! [[ ${tmp_username} =~ ^[a-z]*$ ]]
    then
      if ! ( whiptail --title 'Yunohost Management' \
        --yesno 'Username must contain only lowerscript char [a-z]. \n\n
Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    elif ! yunohost user info ${tmp_username} | grep -q 'Unknown user'
    then
      if ! ( whiptail --title 'Yunohost Management' \
        --yesno 'User already exist. \n\n
Do you want to retry ?' ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    else
      ynh_username=${tmp_username}
      return 0
    fi
  done
}

ynh_set_fullname() {
  # Set yunohost fullname
  local name_menu
  name_menu="whiptail --title 'Yunohost Management' \
    --inputbox 'Firstname of the new user (you can leave it empty).' \
    ${WT_HEIGHT} ${WT_WIDTH} '${ynh_firstname}'"
  bash -c "${name_menu}" 2>results_menu.txt
  [[ $? -eq 1 ]] && return 1
  ynh_firstname=$( cat results_menu.txt )
  name_menu="whiptail --title 'Yunohost Management' \
    --inputbox 'Lastname of the new user (you can leave it empty).' \
    ${WT_HEIGHT} ${WT_WIDTH} '${ynh_lastname}'"
  bash -c "${name_menu}" 2>results_menu.txt
  [[ $? -eq 1 ]] && return 1
  ynh_lastname=$( cat results_menu.txt )
  return 0
}

ynh_set_passwd () {
  # Set Yunohost user password
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

  while true
  do
    passwd1="whiptail --title 'Yunohost Management' \
      --passwordbox 'Password for Yunohost user ${ynh_username}' \
      ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${passwd1}" 2>results_menu.txt
    [[ $? -eq 1 ]] && return 1
    passwd1=$( cat results_menu.txt )
    if ! [[ ${passwd1} =~ ${passwd_regex} ]]
    then
      if ! ( whiptail --title 'Yunohost Management' \
        --yesno "Password must be at least eight char long and contains only \
alphanumeric char either lowercase or uppercase and the following predefined \
characters  : @ * # - _ = ! ? % &.

Do you want to retry ?" ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    else
      local passwd2="whiptail --title 'Yunohost Management' \
        --passwordbox 'Please enter the password again.' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "${passwd2}" 2> results_menu.txt
      [[ $? -eq 1 ]] && return 1
      passwd2=$( cat results_menu.txt )
      if [[ ! ${passwd1} == ${passwd2} ]]
      then
        if ! ( whiptail --title 'Yunohost Management' \
          --yesno "Passwords do not match.

Do you want to retry ?" ${WT_HEIGHT} ${WT_WIDTH} )
        then
          return 1
        fi
      else
        ynh_passwd=${passwd1}
        return 0
      fi
    fi
  done
}

ynh_set_email() {
  # Set Yunohost user email
  local mail1=''
  local mail2=''
  local mail_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

  while true
  do
    mail1="whiptail --title 'Yunohost Management' \
      --inputbox 'Email adress of the new user' \
      ${WT_HEIGHT} ${WT_WIDTH} ${ynh_mail}"

    bash -c "$mail1" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    mail1=$( cat results_menu.txt )

    if [[ ! ${mail1} =~ ${mail_regex} ]]
    then
      if ! ( whiptail --title 'Yunohost Management' \
       --yesno "This is not an email adress. Please enter one of the form :

     email@domain.com.

Do you want to retry ? " ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    else
      mail2="whiptail --title 'Yunohost Management' \
        --inputbox 'Please enter email adress again' ${WT_HEIGHT} ${WT_WIDTH}"
      bash -c "$mail2" 2> results_menu.txt
      [[ $? -eq 1 ]] && return 1
      mail2=$( cat results_menu.txt )
      if [[ ! ${mail1} == ${mail2} ]] && ! ( whiptail \
        --title 'Yunohost Management' \
        --yesno 'Emails do not match. Do you want to retry ?' \
        ${WT_HEIGHT} ${WT_WIDTH} )
     then
       return 1
     fi
     if [[ ${mail1} == ${mail2} ]]
     then
       ynh_mail=${mail1}
       return 0
     fi
    fi
  done
}

ynh_set_mailquota() {
  # Set mail quota of Yunohost user
  mail_quota="whiptail --title 'Yunohost Management' \
    --inputbox 'Enter the mail quota for this user like :
- 100k
- 500M
- 1G...

Mailbox quota must be a size with b/k/M/G/T suffix or 0 to disable the quota.

WARNING : No verification will be done on your input, thus following step might \
not work.' \
    ${WT_HEIGHT} ${WT_WIDTH} ${ynh_mail_quota}"

  bash -c "$mail_quota" 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1
  ynh_mail_quota=$( cat results_menu.txt )
  return 0
}

ynh_choose_user() {
  # Menu that parse yunohost user and let choose one
  local ynh_username=''
  local ynh_firstname=''
  local ynh_lastname=''
  local ynh_mail=''
  local ynh_passwd=''
  local ynh_mail_quota=''

  local YNH_USER_ID=''

  local idx=0
  local choose_menu=''
  local nb_user=$( yunohost user list | grep username | wc -l )

  clear
  echo "Please wait while getting user informations"

  for i in $( yunohost user list | grep username | cut -d: -f2 )
  do
    while read line
    do
      if echo $line | grep -q username
      then
        YNH_USER_ID[idx]=$( echo $line | grep username | cut -d: -f2 )
      fi
      if echo $line | grep -q firstname
      then
        ynh_firstname[idx]=$( echo $line | grep firstname | cut -d: -f2 )
      fi
      if echo $line | grep -q lastname
      then
        ynh_lastname[idx]=$( echo $line | grep lastname | cut -d: -f2 )
      fi
      if echo $line | grep -q 'No quota'
      then
        ynh_mail_quota[idx]=0
      fi
      if echo $line | grep -q limit
      then
        ynh_mail_quota[idx]=$( echo $line | grep limit | cut -d: -f2 )
      fi
      if echo $line | grep -q mail
      then
        ynh_mail[idx]=$( echo $line | grep mail | cut -d: -f2 )
      fi
    done <<< "$( yunohost user info $i )"
    (( idx++ ))
  done

  choose_menu="whiptail --title 'Yunohost Management' \
    --menu 'Select the Yunohost user you want to update' \
      ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx = 0 ; idx < ${#YNH_USER_ID[@]} ; idx++ ))
  do
    choose_menu="${choose_menu} \
      '${YNH_USER_ID[idx]}' \
      '${ynh_firstname[idx]} ${ynh_lastname[idx]} <${ynh_mail[idx]}>'"
  done

  bash -c "${choose_menu}" 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )

  clear
  echo "Please wait while getting user informations"

  while read line
  do
    echo $line | grep -q username \
       && ynh_username=$( echo $line | grep username | cut -d: -f2 )
    echo $line | grep -q firstname \
      && ynh_firstname=$( echo $line | grep firstname | cut -d: -f2 )
    echo $line | grep -q lastname \
      && ynh_lastname=$( echo $line | grep lastname | cut -d: -f2 )
    echo $line | grep -q 'No quota' \
      && ynh_mail_quota=0
    echo $line | grep -q limit \
      && ynh_mail_quota=$( echo $line | grep limit | cut -d: -f2 )
    echo $line | grep -q mail \
      && ynh_mail=$( echo $line | grep mail | cut -d: -f2 )
  done <<< "$( yunohost user info ${CHOICE} )"
  return 0
}

ynh_add_user() {
  # Add user go through
  ynh_username='johndoe'
  ynh_firstname='John'
  ynh_lastname='Doe'
  ynh_mail='john.doe@localhost'
  ynh_passwd=''
  ynh_mail_quota='500M'

  while true
  do
    ynh_set_username
    [[ $? -eq 1 ]] && return 1
    ynh_set_fullname
    [[ $? -eq 1 ]] && return 1
    ynh_set_email
    [[ $? -eq 1 ]] && return 1
    ynh_set_mailquota
    [[ $? -eq 1 ]] && return 1
    ynh_set_passwd
    [[ $? -eq 1 ]] && return 1

    if ( whiptail --title 'Yunohost Management' \
      --yesno "Here are the information about the new Yunohost user :
- Username    : ${ynh_username}
- First name  : ${ynh_firstname}
- Last name   : ${ynh_lastname}
- Password    : The one you set
- Email       : ${ynh_mail}
- Email quota : ${ynh_mail_quota}
- Fullname    : ${ynh_firstname} ${ynh_lastname}

Is everything right ?" ${WT_HEIGHT} ${WT_WIDTH} )
    then
      yunohost user create -f ${ynh_firstname} -m ${ynh_mail} \
        -l ${ynh_lastname} -q ${ynh_mail_quota} -p ${ynh_passwd} ${ynh_username}
      [[ $? -eq 1 ]] && return 1
    fi
    if ! ( whiptail --title 'Yunohost Management' \
      --yesno 'Do you want to add another Yunohost user ?' ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 0
    fi
  done
}

ynh_update_user() {
  # Update user menu
  menu="whiptail --title 'Yunohost Management' \
    --menu 'What do you want to update for this Yunohst user ${ynh_username} :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Full name'   'Change full name' \
    'Mail adress' 'Update mail adress' \
    'Mail quota'  'Update mail quota' \
    'Password'    'Change password' \
    '<-- Back'    'Back to Yunohost user management menu'"
  while true
  do
    bash -c "${menu} " 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Full name')
        ynh_set_fullname
        [[ $? -eq 0 ]] && yunohost user update \
          -f ${ynh_firstname} -l ${ynh_lastname} ${ynh_username}
        ;;
      'Mail adress')
        ynh_set_email
        [[ $? -eq 0 ]] && yunohost user update \
          -m ${ynh_mail} ${ynh_username}
        ;;
      'Mail quota')
        ynh_set_mailquota
        [[ $? -eq 0 ]] && yunohost user update \
          -q ${ynh_mail_quota} ${ynh_username}
        ;;
      'Password')
        ynh_set_passwd
        [[ $? -eq 0 ]] && yunohost user update \
          -p ${ynh_passwd} ${ynh_username}
        ynh_passwd=''
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
  read
}

ynh_delete_user() {
  # Choose and delete Yunohost user

  while true
  do
    if ( whiptail --title 'Yunohost Management' \
      --yesno "Are you sure you want to delete the user with the following \
informations :
 - Username    : ${ynh_username}
 - First name  : ${ynh_firstname}
 - Last name   : ${ynh_lastname}
 - Password    : The one you set
 - Email       : ${ynh_mail}
 - Email quota : ${ynh_mail_quota}
 - Fullname    : ${ynh_firstname} ${ynh_lastname}" ${WT_HEIGHT} ${WT_WIDTH} )
   then
     if ( whiptail --title 'Yunohost Management' \
       --yesno "Do you also want to purge it (i.e. delete all data that belong \
to this user) ?" ${WT_HEIGHT} ${WT_WIDTH} )
     then
       yunohost user delete --purge ${ynh_username}
     else
       yunohost user delete ${ynh_username}
     fi
   fi

   if ! ( whiptail --title 'Yunohost Management' \
     --yesno "Do you want to delete another Yunohost user ?" \
     ${WT_HEIGHT} ${WT_WIDTH} )
   then
     return 0
   fi
 done

}

ynh_user() {
  # Menu management user
  local ynh_username=''
  local ynh_firstname=''
  local ynh_lastname=''
  local ynh_mail=''
  local ynh_passwd=''
  local ynh_mail_quota=''

  menu="whiptail --title 'Yunohost Management' \
    --menu  'Select what you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Add User'     'Add a Yunohost user' \
    'Update User'  'Update an existing Yunohost user' \
    'Delete User'  'Delete a Yunohost user' \
    '<-- Back'        'Back to main menu'"

  while true
  do
    bash -c "${menu} " 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Add User')
        ynh_add_user
        ;;
      'Update User')
        ynh_choose_user
        [[ $? -eq 0 ]] && ynh_update_user
        ;;
      'Delete User')
        ynh_choose_user
        [[ $? -eq 0 ]] && ynh_delete_user
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}

ynh_tools() {
  # Yunohost tools menu
  menu="whiptail --title 'Yunohost Management' \
    --menu  'Select what you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Post Install'    'Run Yunohost post install' \
    'Admin Password'  'Change admin password' \
    'Upgrade Apps'    'Upgrade apps if possible' \
    'Update Yunohost' 'Upgrade apps if possible' \
    '<-- Back'        'Back to main menu'"

  while true
  do
    bash -c "${menu} " 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Post Install')
        if ( whiptail --title 'Yunohost Management' \
          --yesno "This will run Yunohost post install wheither it was already \
ran or not.

Are you sure you want to continue ?" ${WT_HEIGHT} ${WT_WIDTH} )
        then
          yunohost tools postinstall
        fi
        ;;
      'Admin Password')
        if ( whiptail --title 'Yunohost Management' \
          --yesno "This will ask you the new password you want to set for \
the administration of Yunohost.

Are you sure you want to continue ?" ${WT_HEIGHT} ${WT_WIDTH} )
        then
          yunohost tools adminpw
        fi
        ;;
      'Upgrade Apps')
        if ( whiptail --title 'Yunohost Management' \
          --yesno "This will try to upgrade your system and apps already \
installed. Some of them, mainly your custom app, might not be upgrade.

Are you sure you want to continue ?" ${WT_HEIGHT} ${WT_WIDTH} )
        then
          yunohost tools upgrade
        fi
        ;;
      'Update Yunohost')
        if ( whiptail --title 'Yunohost Management' \
          --yesno "This will update your Yunohost installation.

Are you sure you want to continue ?" ${WT_HEIGHT} ${WT_WIDTH} )
        then
          yunohost tools update
        fi
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}

ynh_install() {
  # Install Yunohost
  if ( whiptail --title 'Yunohost Management' \
      --yesno "Yunohost does not seem to be install.

Do you want to install yunohost ?

  WARNING : This may break your setup and overwrite some of your files, \
mainly your postfix, devcot, nginx, mysql and metronome config." \
  ${WT_HEIGHT} ${WT_WIDTH} )
  then
    ! type -t git > /dev/null && ${LINUX_PKG_MGR} install git
    git clone https://github.com/YunoHost/install_script /tmp/install_script

    if ! ( whiptail --title 'Yunohost Management' \
      --yesno "Yunohost require you to set/change root password.

Have you already done it during installation of your debian or with this script \
via 'Initial Setup' option in main menu ?

WARNING : If you did not set a root password, following process might no work \
and might have error !" ${WT_HEIGHT} ${WT_WIDTH} )
    then
      passwd
    fi
    cd /tmp/install_script && ./install_yunohost
    cd $DIR

    if ( whiptail --title 'Install Yunohost' \
      --yesno "Yunohost successfully installed.

Do you want to run post install script of yunohost (in order to set main domain, \
admin password, etc.).

If you prefer, you can manage it through a web interface. Open your favorite \
 web browser and enter one of this IP adress in the url field :
${LINUX_LOCAL_IP}" ${WT_HEIGHT} ${WT_WIDTH} )
    then
      yunohost tools postinstall
    fi
  fi
}

ynh_management() {
  # Main menu that install Yunohost if not install, else propose to continue
  # using CLI but warn user that it's better/easier to use webUI
  if ! type -t yunohost &>/dev/null
  then
    ynh_install
    [[ $? -eq 1 ]] && return 1
  elif ! ( whiptail --title 'Yunohost Management' \
      --yesno "Yunohost seem to be already installed on this computer.
At this step you should be able to connect yoursel to the web interface, just \
open your favorite web browser and connect to one of the following IP :
${LINUX_LOCAL_IP}

Do you want to continue to the yunohost management menu ?

WARNING : It's better/easier to use the web interface than the command line \
interface provided by yunohost and on which this script is based on.
Continue only if no know what you are doing." ${WT_HEIGHT} ${WT_WIDTH} )
  then
    return 1
  fi

  menu="whiptail --title 'Yunohost Management' \
    --menu  'Select what you want to do :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Yunohost tools' 'Acces to yunohost tools (postinstall, adminpw,...)' \
    'Manage User'    'Manage user (add, update, delete,...)' \
    'Manage App'     'Manage apps in Yunohost (install, remove)' \
    '<-- Back'       'Back to main menu'"

  while true
  do
    bash -c "${menu} " 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back')
        return 0
        ;;
      'Yunohost tools')
        ynh_tools
        ;;
      'Manage User')
        ynh_user
        ;;
      'Manage App')
        ynh_app
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}

