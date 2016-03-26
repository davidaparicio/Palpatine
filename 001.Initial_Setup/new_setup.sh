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


# FROM RASPI-CONFIG
config_keyboard() {
  dpkg-reconfigure keyboard-configuration &&
  printf "Reloading keymap. This may take a short while\n" &&
  invoke-rc.d keyboard-setup start || return $?
  udevadm trigger --subsystem-match=input --action=change
  return 0
}

# FROM RASPI-CONFIG
chg_locale() {
  dpkg-reconfigure locales
}

# FROM RASPI-CONFIG
chg_timezone() {
  dpkg-reconfigure tzdata
}

# PART FROM RASPI-CONFIG
chg_usr_pwd () {
	# Usage : chg_usr_pwd <USER>
    # Input  : 
    #   $1-<USER>       : User account name 
    # Output : None
    # Brief  : Change password for <USER>
	if [ "$#" -ne 1 ]
    then
        echo "[WARNING] - Calling ${FUNCNAME} without the right number of argument"
    else
    	local USR=$1
		whiptail --msgbox "You will now be asked to enter a new password for the user : ${USR} " 20 60 1
  		passwd ${USR} &&
  			whiptail --msgbox "Password changed successfully" 20 60 1 : 
  			whiptail --msgbox "Failed to change password" 20 60 1 
  	fi
}

update_sudoer () {
	# Usage  : update_sudoer
    # Input  : None
    # Output : None
    # Brief  : 
    #   Ask if change sudoer to ask root passwd instead of first user and make a backup
    #   of old sudoers file.
    if ( whiptail --title "Update sudoer file" --yesno "\
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

ask_arch () {
	# Usage  : ask_arch
    # Input  : None
    # Output : None
    # Brief  : 
    #   Ask if arch is the right one, and if arch is RPi, ask if user want to expand rootfs
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


fullupdate () {
	# Usage  : setup_base
    # Input  : None
    # Output : None
    # Brief  : 
    #   Do a fullupdate of the system. 
    whiptail --title "Update Repo and Upgrade" --msgbox "\
    This script will now update and upgrade the system" 20 60
    # TODO : Manage multiple system
    apt-get update && apt-get upgrade && apt-get dist-upgrade
}

setup_base_pkg () {
	# Usage  : setup_all_pkg
    # Input  : None
    # Output : None
    # Brief  : 
    # 	Install multiple utility for later 
    whiptail --title "Setup Base Package" --msgbox "\
    This script will now install the following packages : \n\
    	- apt-transport-https \n\
    	- software-properties-common \n\
    	- python-software-properties \n" 20 60
    # TODO : Manage multiple system
    apt-get install -y apt-transport-https software-properties-common python-software-properties
}

setup_ask_pkg () {
	# Usage  : setup_all_pkg
  # Input  : None
  # Output : None
  # Brief  : 
  # 	Menu to ssk user which package he wants to install 
  calc_wt_size
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
  	exit 1
    	table_of_content # TODO : Code this function
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) setup_ask_go_through ;; # TODO : Code this function
      2\ *) setup_ask_categories ;; # TODO : Code this function
      3\ *) setup_direct_finish ;; # TODO : Code this function
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
}

setup_all_pkg() {
	# Usage  : setup_all_pkg
    # Input  : None
    # Output : None
    # Brief  : 
    # 	Call function multiple function that update

#	fullupdate 
#	setup_base_pkg
	setup_ask_pkg
}

#chg_usr_pwd "root"
#ask_arch
#chg_locale
#chg_timezone
#config_keyboard
setup_all_pkg
