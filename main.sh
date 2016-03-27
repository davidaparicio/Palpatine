#!/bin/bash

# FROM RASPI-CONFIG
INTERACTIVE=True
ASK_TO_REBOOT=0
BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
CONFIG=/boot/config.txt

###############################################################################
# FUNCTION
###############################################################################
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

###############################################################################
# ALL SOURCE
###############################################################################
source 001.Initial_Setup/first_setup.sh

main_menu () {
  calc_wt_size
  local MAIN_MENU="whiptail --title 'Main Menu' --menu  'Select what you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MAIN_MENU="${MAIN_MENU} 'First setup' 'Let the script go through all actions'"
  MAIN_MENU="${MAIN_MENU} 'FINISH' 'Exit the script'"
  while true
  do
    bash -c "${MAIN_MENU} " 2> results_menu.txt
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    fi

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "FINISH" )
      if [[ ${ASK_TO_REBOOT} -eq 1 ]] && (whiptail --title 'Reboot needed' --yesno 'A reboot is needed. Do you want to reboot now ? '  10 80 )
      then
        reboot
      fi
      return 0
      ;;
     "First setup" )
      first_setup
     ;;
     * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      return 1
   esac
  done
}

main_menu
