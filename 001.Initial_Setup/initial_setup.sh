#!/bin/bash

# Functions
###############################################################################
setup_chg_root_pwd () {
  # Change root password
  while true
  do
    whiptail --title 'Inital Setup'\
      --msgbox 'You will now be asked to enter a new password for the user : root.'\
      ${WT_HEIGHT} ${WT_WIDTH}
    passwd root
    if [[ $? -eq 0 ]]
    then
      whiptail --title 'Inital Setup'\
        --msgbox 'Password changed successfully' ${WT_HEIGHT} ${WT_WIDTH}
      return 0
    elif ! ( whiptail --title 'Inital Setup'\
      --yesno 'Failed to change password. Do you wan to retry ?'\
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 1
    fi
  done
}

#setup_expand_rootfs () {
#  # If is raspberry pi, as to expand rootfs using functions from raspi-config.
#  # TODO : Features
#  # Implement regurarly check from raspi-config source.
#  if ( whiptail --title 'Inital Setup' \
#    --yesno 'Are you sure  you are on a RPi and you want to expand rootfs ?
#I WILL NOT BE RESPONSIBLE IF DAMAGE OCCURS TO YOUR ROOTFS' ${WT_HEIGHT} ${WT_WIDTH} )
#  then
#    expand_rootfs && return 0 || return 1
#  fi
#  return 0
#}

setup_chg_locale() {
  # Change locale
  dpkg-reconfigure locales
}

setup_chg_timezone() {
  # Change timezone
  dpkg-reconfigure tzdata
}

setup_config_keyboard() {
  # Change keyboard layout
  # TODO : Support
  # Will need update when adding new supported linux distrib
  dpkg-reconfigure keyboard-configuration &&
  printf "Reloading keymap. This may take a short while\n" &&
  invoke-rc.d keyboard-setup start || return $?
  udevadm trigger --subsystem-match=input --action=change
  return 0
}

setup_hostname() {
  # Change hostname
  local curr_hostname=$( hostname )
  local hostname_ok=false
  local hostname_set=""
  local hostname_regex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"

  whiptail --title 'Initial Setup' \
    --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive), \
the digits '0' through '9', and the hyphen. \
Hostname labels cannot begin or end with a hyphen. \
No other symbols, punctuation characters, or blank spaces are permitted." \
  ${WT_HEIGHT} ${WT_WIDTH}

  while ! ${hostname_ok}
  do
    hostname_set=$( whiptail --title 'Initial Setup' \
      --inputbox 'Please enter the hostname you want for this computer. '\
      ${WT_HEIGHT} ${WT_WIDTH} "${curr_hostname}" 3>&1 1>&2 2>&3 )
    if [[ ${#hostname_set} > 0 ]]
    then
      if [[ ${hostname_set} =~ ${hostname_regex} ]] \
        && ( whiptail --title 'Initial Setup' \
        --yesno "Are you sure you want this hostname : ${hostname_set} ?" \
        ${WT_HEIGHT} ${WT_WIDTH} )
      then
        echo $hostname_set > /etc/hostname
        sed -i "s/127.0.1.1.*$curr_hostname/127.0.1.1\t$hostname_set/g" /etc/hosts
        ASK_TO_REBOOT=true
        return 0
      fi
    elif ! ( whiptail --title 'Initial Setup' \
      --yesno 'Please enter a valid hostname. Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 1
    fi
  done
}

setup_update_sudoer () {
  # Add line 'Defaults rootpw' to sudoers file to ask root password when using
  # sudo command
  if grep -q 'Defaults rootpw' /etc/sudoers
  then
    whiptail --title 'Initial Setup'\
      --msgbox 'The following line is already present in /etc/sudoers.

        "Defaults rootpw"

    Nothing to do. Will continue' ${WT_HEIGHT} ${WT_WIDTH}
    return 0
  elif ( whiptail --title 'Initial Setup'\
    --yesno ' Do you want to add the following line to sudoer ?

  "Defaults rootpw"

This will make OS to ask root password when using sudo instead of user password.'\
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    sudo sed -i.bak -e '$ a\Defaults rootpw' /etc/sudoers
    return 0
  else
    return 1
  fi
}

initial_setup_loop () {
  # Initial setup menu
  local setup_loop="whiptail --title 'Initial Setup' \
    --menu  'Select how do you whant to manage first setup :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
#  if ${LINUX_IS_RPI}
#  then
#    setup_loop="${setup_loop} 'Expand rootfs'       'Will expand rootfs (NB: Will only work on RPi)'"
#  fi
  setup_loop="${setup_loop} 'Change root password' 'Change root password' \
  'Change sudoer file'   'Will change sudoers file to add line Defaults rootpw' \
  'Change locale'        'Change Locale information' \
  'Change timezone'      'Change timezone' \
  'Change keyboard'      'Change keyboard layout' \
  'Change hostname'      'Change hostname' \
  '<-- Back'             'Go to main menu'"
  while true
  do
    bash -c "${setup_loop}" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back' )
        return 1
      ;;
      'Change root password' )
        setup_chg_root_pwd
      ;;
      'Change sudoer file' )
        setup_update_sudoer
      ;;
#      'Expand rootfs' )
#        setup_expand_rootfs
#      ;;
      'Change locale' )
        setup_chg_locale
      ;;
      'Change timezone' )
        setup_chg_timezone
      ;;
      'Change keyboard' )
        setup_config_keyboard
      ;;
      'Change hostname' )
        setup_hostname
      ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
        return 1
      ;;
   esac
  done
}

initial_setup_go_through () {
  # Go through all function
#  if ${LINUX_IS_RPI} && ( whiptail --title 'Inital Setup' \
#    --yesno 'Do you want to expand rootfs ?' ${WT_HEIGHT} ${WT_WIDTH} )
#  then
#    setup_expand_rootfs
#    [[ $? -eq 1 ]] && return 1
#  fi

  if ( whiptail --title 'Inital Setup' \
    --yesno 'Do you want to change root password ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_chg_root_pwd
    [[ $? -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Inital Setup' \
    --yesno 'Do you want to update sudoer files by adding line "Defaults rootpw" ?'\
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_update_sudoer
    [[ $? -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Inital Setup' \
    --yesno 'Do you want to change the Locale ? ' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_chg_locale
    [[ $? -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Inital Setup' \
    --yesno 'Do you want to change the timezone ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_chg_timezone
    [[ $? -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Initial Setup' \
    --yesno 'Do you want to change the keyboard layout ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_config_keyboard
    [[ $? -eq 1 ]] && return 1
  fi

  if ( whiptail --title 'Initial Setup' \
    --yesno 'Do you want to change the hostname ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_hostname
    [[ $? -eq 1 ]] && return 1
  fi

  if ! ( whiptail --title 'Initial Setup'\
    --yesno 'Does everything went ok ? ' ${WT_HEIGHT} ${WT_WIDTH} )
  then
      initial_setup_loop
  fi
  return 0
}


