#!/bin/bash

ASK_TO_REBOOT=0
LINUX_OS='Unknown'
LINUX_VER='Unknown'
LINUX_PKG_MGR='Unknown'
LINUX_ARCH='Unknown'
LINUX_IS_RPI=false

SUPPORTED_OS[0]='Ubuntu'
SUPPORTED_OS[1]='Kubuntu'
SUPPORTED_OS[2]='Xubuntu'
SUPPORTED_OS[3]='Lubuntu'
SUPPORTED_OS[4]='Debian'
SUPPORTED_OS[5]='ArchLinux'
SUPPORTED_OS[6]='Raspbian'

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

OS=$(lsb_release -si)
VER=$(lsb_release -sr)
echo $OS $ARCH $VER

linux_init_os () {
  local TMP_OS=$(lsb_release -si)
  local USER_SET_OS=false
  if ( whiptail \
    --title 'Linux Init : OS' \
    --yesno "OS Seems to be : \n\n ${TMP_OS} \n\nIs it right ? " $WT_HEIGHT $WT_WIDTH )
  then
    LINUX_OS=${TMP_OS}
    return 0
  elif ( whiptail \
    --title 'Linux Init : OS' \
    --yesno 'Do you want to enter the OS name (if no, the program will exit) ? ' $WT_HEIGHT $WT_WIDTH )
  then
    local LINUX_OS_MENU="whiptail --title 'Linux Init : OS' --menu  'Select your linux OS amoung the following one :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
    for (( idxOS=0; idxOS < ${#SUPPORTED_OS[@]}; idxOS++ ))
    do
      LINUX_OS_MENU="${LINUX_OS_MENU} '${SUPPORTED_OS[${idxOS}]}' ''"
    done
    LINUX_OS_MENU="${LINUX_OS_MENU} 'NONE OF THEM' ''"

    bash -c "${LINUX_OS_MENU} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      "NONE OF THEM" )
        whiptail --title 'Linux Init : OS' --msgbox 'Sorry to heard that your OS is not supported. \n
Feel free to send a mail to give us your OS name. \n
Program will now exit'  $WT_HEIGHT $WT_WIDTH
        return 1
      ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
        return 1
      ;;
    esac
    LINUX_OS=${CHOICE}
    USER_SET_OS=true
  else
    return 1
  fi

  # TODO : Check version Ubuntu > 14.04, debian > jessy
}

linux_init () {
  local LINUX_INIT_OK=true
  linux_init_os
  if [[ ${ARCH} =~ 'arm' ]]
  then
  	if ( whiptail --title 'Linux Init' --yesno "\
  	It seems you are on an arm machine. \n \
  	Is it a raspberry ? " 20 60 )
  	then
  		LINUX_IS_RPI=true
  	else
  		LINUX_INIT_OK=false
  	fi
  elif [[ ${ARCH} == 'x86_64' ]]
  then
  	if ( whiptail --title 'Linux Init' --yesno "\
  	It seems you are on an ${ARCH} machine. \n\
  	Is it alright ? "  $WT_HEIGHT $WT_WIDTH )
  	then
  		ARCH="x86_64"
  	else
  		LINUX_INIT_OK=false
  	fi
  else
    LINUX_INIT_OK=false
  fi
  if ! ${LINUX_INIT_OK}
  then
    whiptail \
    --title 'Linux Init ERROR' \
    --msgbox 'Error architecture not supported. \n\nProgram will now exit !' \
    $WT_HEIGHT $WT_WIDTH
    exit 1
  fi
  return 0
}

###############################################################################
# ALL SOURCE
###############################################################################
source 001.Initial_Setup/first_setup.sh

main_menu () {
  local MAIN_MENU
  calc_wt_size

  whiptail \
  --title 'Linux Config' \
  --msgbox  'Before continuing to main menu, you need to set some information about your linux distribution' $WT_HEIGHT $WT_WIDTH
  linux_init
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    whiptail --title "ERROR" --msgbox "An error occured during initialisation.\n\
The program will exit" $WT_HEIGHT $WT_WIDTH
    return 1
  fi

  MAIN_MENU="whiptail --title 'Main Menu' --menu  'Select what you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  MAIN_MENU="${MAIN_MENU} 'First setup' 'Let the script go through all actions'"
  MAIN_MENU="${MAIN_MENU} 'FINISH' 'Exit the script'"
  while true
  do
    bash -c "${MAIN_MENU} " 2> results_menu.txt
    RET=$?
    [[ ${RET} -eq 1 ]] && return 1

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

# TODO : Check user root and through SSH
main_menu
