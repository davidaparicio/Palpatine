#!/bin/bash

# FROM RASPI-CONFIG
is_pione() {
   if grep -q "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
   then
      return 0
   elif  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo
   then
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
   if is_pione
   then
      echo 1
   elif is_pitwo
   then
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
  whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" 20 60 2
}

###############################################################################
setup_chg_root_pwd () {
  while true
  do
    whiptail --title '001.Inital Setup : Root Password'\
      --msgbox 'You will now be asked to enter a new password for the user : root.'\
      ${WT_HEIGHT} ${WT_WIDTH}
    passwd root
    RET=$? ; if [[ ${RET} -eq 0 ]]
    then
      whiptail --title '001.Inital Setup : Root Password'\
      ---msgbox 'Password changed successfully' ${WT_HEIGHT} ${WT_WIDTH}
      return 0
    elif ! ( whiptail --title '001.Inital Setup : Root Password'\
      --yesno 'Failed to change password. Do you wan to retry ?'\
      ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 1
    fi
  done
}

setup_expand_rootfs () {
  if ( whiptail --title '001.Inital Setup : Expand Rootfs' \
    --yesno 'Are you sure  you are on a RPi and you want to expand rootfs ?
I WILL NOT BE RESPONSIBLE IF DAMAGE OCCURS TO YOUR ROOTFS' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    expand_rootfs && return 0 || return 1
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

setup_hostname() {
  local curr_hostname=`cat /etc/hostname | tr -d " \t\n\r"`
  local hostname_ok=false
  local hostname_set=""
  local hostname_regex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"

  whiptail --title '001.Initial Setup : Change hostname' \
    --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive), \
the digits '0' through '9', and the hyphen. \
Hostname labels cannot begin or end with a hyphen. \
No other symbols, punctuation characters, or blank spaces are permitted." \
  ${WT_HEIGHT} ${WT_WIDTH}

  while ! ${hostname_ok}
  do
    hostname_set=$( whiptail --title '001.Initial Setup : Change hostname' \
      --inputbox 'Please enter the hostname you want for this computer. '\
      ${WT_HEIGHT} ${WT_WIDTH} "${curr_hostname}" 3>&1 1>&2 2>&3 )
    if [[ ${#hostname_set} > 0 ]]
    then
      if [[ ${hostname_set} =~ ${hostname_regex} ]] && ( whiptail \
        --title '001.Initial Setup : Change hostname' \
        --yesno "Are you sure you want this hostname : ${hostname_set} ?" \
        ${WT_HEIGHT} ${WT_WIDTH} )
      then
        echo $hostname_set > /etc/hostname
        sed -i "s/127.0.1.1.*$curr_hostname/127.0.1.1\t$hostname_set/g" /etc/hosts
        ASK_TO_REBOOT=1
        return 0
      fi
    else
      whiptail --title '001.Initial Setup : Change hostname' \
        --msgbox 'Please enter valid hostname' ${WT_HEIGHT} ${WT_WIDTH}
    fi
    if ! (whiptail --title '001.Initial Setup : Change hostname' \
      --yesno 'Do you want to retry ? ' ${WT_HEIGHT} ${WT_WIDTH} )
    then
      return 1
    fi
  done
}

setup_update_sudoer () {
  if grep -q 'Defaults rootpw' /etc/sudoers
  then
    whiptail --title '001.Initial Setup : Update sudoer file'\
      --msgbox 'The following line is already present in /etc/sudoers.\n\n
        "Defaults rootpw" \n\n
    Nothing to do. Will continue' ${WT_HEIGHT} ${WT_WIDTH}
    return 0
  elif ( whiptail --title '001.Initial Setup : Update sudoer file'\
    --yesno ' Do you want to add the following line to sudoer ? \n\n
  "Defaults rootpw" \n\n
This will make OS to ask root password when using sudo instead of user password.'\
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    sudo sed -i.bak -e '$ a\Defaults rootpw' /etc/sudoers
    return 0
  else
    return 1
  fi
}

initial_setup_go_through () {
  if ${LINUX_IS_RPI} && ( whiptail --title '001.Inital Setup : Expand rootfs' \
    --yesno 'Do you want to expand rootfs ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_expand_rootfs
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title '001.Inital Setup : Change root password' \
    --yesno 'Do you want to change root password ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_chg_usr_pwd 'root'
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title '001.Inital Setup : Update sudoer' \
    --yesno 'Do you want to update sudoer files by adding line "Defaults rootpw" ?'\
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_update_sudoer
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title '001.Inital Setup : Change Locale' \
    --yesno 'Do you want to change the Locale ? ' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_chg_locale
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title '001.Inital Setup : Change timezone' \
    --yesno 'Do you want to change the timezone ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_chg_timezone
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title '001.Initial Setup : Change keyboard' \
    --yesno 'Do you want to change the keyboard layout ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_config_keyboard
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ( whiptail --title '001.Initial Setup : Change hostname' \
    --yesno 'Do you want to change the hostname ?' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    setup_hostname
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  fi

  if ! ( whiptail --title '001.Initial Setup : FINISH'\
    --yesno 'Does everything went ok ? ' ${WT_HEIGHT} ${WT_WIDTH} )
  then
      return 1
  fi
  return 0
}

initial_setup_loop () {
  local setup_loop="whiptail --title '001.Initial Setup' \
    --menu  'Select how do you whant to manage first setup :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  if ${LINUX_IS_RPI}
  then
    setup_loop="${setup_loop} 'Expand rootfs'       'Will expand rootfs (NB: Will only work on RPi)'"
  fi
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
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )
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
      'Expand rootfs' )
        setup_expand_rootfs
      ;;
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

initial_setup () {
  local initial_setup="whiptail --title '001.Initial Setup' \
    --menu  'Select how do you whant to manage first setup :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Go through'     'Let the script go through all actions' \
    'Choose actions' 'Let you choose what action you want to do' \
    '<-- Back'       'Return to main menu'"

  bash -c "${initial_setup}" 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  case ${CHOICE} in
    '<-- Back' )
      return 0
    ;;
    'Go through' )
      initial_setup_go_through
      RET=$? ; [[ ${RET} -eq 0 ]] && return 0
      initial_setup_loop
      RET=$? ; [[ ${RET} -eq 0 ]] && return 0 || return 1
    ;;
    'Choose actions' )
      initial_setup_loop
      RET=$? ; [[ ${RET} -eq 0 ]] && return 0 || return 1
    ;;
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      return 1
    ;;
 esac
}
