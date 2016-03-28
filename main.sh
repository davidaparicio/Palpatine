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

SUPPORTED_UBU_VER[0]='14.04'

SUPPORTED_DEB_VER[0]='jessy'

SUPPORTED_PKG_MGR[0]='apt-get'

###############################################################################
# FUNCTION
###############################################################################
calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error
  # output from tput. However in this case, tput detects neither stdout or
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$( tput cols )

  if [ -z "${WT_WIDTH}" ] || [ "${WT_WIDTH}" -lt 60 ]
  then
    WT_WIDTH=80
  fi
  if [ "${WT_WIDTH}" -gt 178 ]
  then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$((${WT_HEIGHT}-9))
}

linux_init_pkg_mgr () {
  local NB_PKG_MGR=${#SUPPORTED_PKG_MGR[@]}
  local EXIST_PKG_MGR=false
  local PKG_MGR_MENU="whiptail --title 'Linux Init : Package Manager' \
    --menu 'Please choose the package manager you want to use : ' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  local NO_PKG_MGR_MENU="whiptail --title 'Linux Init : Package Manager' \
    --msgbox 'Sorry but you do not to have one of the package manager supported installed.
    Here is the list of supported package manager :
    "

  for (( idxMgr=0; idxMgr < ${NB_PKG_MGR}; idxMgr++ ))
  do
    if type -t ${SUPPORTED_PKG_MGR[${idx}]} &>/dev/null
    then
      EXIST_PKG_MGR=true
    fi
    PKG_MGR_MENU="${PKG_MGR_MENU} '${SUPPORTED_PKG_MGR[${idx}]}' ''"
    NO_PKG_MGR_MENU="${NO_PKG_MGR_MENU}    - ${SUPPORTED_PKG_MGR[${idx}]} \n
    "
  done
  PKG_MGR_MENU="${PKG_MGR_MENU} 'NONE OF THEM' ''"
  NO_PKG_MGR_MENU="${NO_PKG_MGR_MENU} ' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  if ! ${EXIST_PKG_MGR}
  then
      bash -c "${NO_PKG_MGR_MENU} "
      return 1
  fi

  bash -c "${PKG_MGR_MENU} " 2> results_menu.txt
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  CHOICE=$( cat results_menu.txt )

  case ${CHOICE} in
    "NONE OF THEM" )
      whiptail --title 'Linux Init : OS' \
      --msgbox 'Sorry to heard that your pakage manager is not supported. \n
Feel free to send a mail to give us your OS name. \n
Program will now exit' ${WT_HEIGHT} ${WT_WIDTH}
      return 1
    ;;
  esac

  LINUX_PKG_MGR=${CHOICE}
  return 0
}

linux_init_os_ubu_version () {
  local TMP_VER=$( lsb_release -sr )

  if ( whiptail \
    --title 'Linux Init : OS' \
    --yesno "Ubuntu version seems to be : \n\n ${TMP_VER} \n\nIs it right ? " ${WT_HEIGHT} ${WT_WIDTH} )
  then
    if [[ ! ${TMP_VER} =~ ${SUPPORTED_UBU_VER[@]} ]]
    then
      LINUX_VER=${TMP_VER}
      return 0
    fi
  elif ( whiptail \
  --title 'Linux Init : OS' \
  --yesno 'Do you want to enter the version (if no, the program will exit) ? ' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    while true
    do
      TMP_VER=$( whiptail --title 'Linux Init : OS'  --inputbox  'Please enter a version for ubuntu of the for 14.04/15.04' ${WT_HEIGHT} ${WT_WIDTH} 14.04 3>&1 1>&2 2>&3)
      RET=$?
      [[ ${RET} -eq 1 ]] && return 1

      if ! [[ ${TMP_VER} =~ ^([0-9]{2}.[0-9]{2})$ ]] \
        && ! ( whiptail --title 'Linux Init : OS' \
          --msgbox 'The value you enter does not respect Ubuntu version format. Do you want to retry, if no, the script will exit ? ' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} )
      then
        return 1
      elif [[ ${TMP_VER} =~ ^([0-9]{2}.[0-9]{2})$ ]] \
        && [[ ! ${TMP_VER} =~ ${SUPPORTED_UBU_VER[@]} ]]
      then
        whiptail --title 'Linux Init : OS' \
        --msgbox 'The version of your OS is not supported. The script will now exit.' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}
        return 1
      elif [[ ${TMP_VER} =~ ^([0-9]{2}.[0-9]{2})$ ]] \
        && [[ ${TMP_VER} =~ ${SUPPORTED_UBU_VER[@]} ]]
      then
        LINUX_VER=TMP_VER
        return 0
      else
        return 1
      fi
    done
  else
    return 1
  fi
}

linux_init_os () {
  local TMP_OS=$(lsb_release -si )
  local USER_SET_OS=false

  if [[ ${#TMP_OS} -eq 0 ]]
  then
    TMP_OS=$( cat /etc/os-relase | grep NAME | cut -d '"' -f2 )
  fi
  echo ${TMP_OS}
  read

  if ( whiptail \
    --title 'Linux Init : OS' \
    --yesno "OS Seems to be : \n\n ${TMP_OS} \n\nIs it right ? " ${WT_HEIGHT} ${WT_WIDTH} )
  then
    LINUX_OS=${TMP_OS}
  elif ( whiptail \
    --title 'Linux Init : OS' \
    --yesno 'Do you want to choose the OS name (if no, the program will exit) ? ' ${WT_HEIGHT} ${WT_WIDTH} )
  then
    local LINUX_OS_MENU="whiptail --title 'Linux Init : OS' \
      --menu  'Select your linux OS amoung the following one :' \
      ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

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
Program will now exit'  ${WT_HEIGHT} ${WT_WIDTH}
        return 1
      ;;
    esac
    LINUX_OS=${CHOICE}
  else
    return 1
  fi

  case ${LINUX_OS} in
    *[Uu]buntu )
      linux_init_os_ubu_version
    ;;
    # TODO : Check version Ubuntu > 14.04, debian > jessy
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      return 1
    ;;
  esac
}

linux_init_arch () {
  local TMP_ARCH=$( arch )
  if [[ ${TMP_} =~ 'arm' ]]
  then
  	if ( whiptail --title 'Linux Init : Archictecture' --yesno "\
  	It seems you are on an arm machine. \n \
  	Is it a raspberry ? " ${WT_HEIGHT} ${WT_WIDTH} )
  	then
  		LINUX_IS_RPI=true
      LINUX_ARCH=${TMP_ARCH}
  	else
      whiptail --title 'Linux Init : Architecture' \
      --msgbox 'Sorry but for the moment, only raspberry is supported. \
      The script will now exit' ${WT_HEIGHT} ${WT_WIDTH}
      return 1
  	fi
  elif [[ ${TMP_ARCH} == 'x86_64' ]]
  then
  	if ( whiptail --title 'Linux Init : Archictecture' --yesno "\
  	It seems you are on an ${TMP_ARCH} machine. \n\
  	Is it alright ? "  ${WT_HEIGHT} ${WT_WIDTH} )
  	then
  		LINUX_ARCH=${TMP_ARCH}
  	else
      whiptail --title 'Linux Init : Architecture' \
      --msgbox 'An error occur during initialisation of the architecture. \
      The script will now exit' ${WT_HEIGHT} ${WT_WIDTH}
      return 1
  	fi
  else
    whiptail --title 'Linux Init : Architecture' \
    --msgbox 'Sorry but for the moment, your architecure ${TMP_ARCH} is not supported. \
    The script will now exit' ${WT_HEIGHT} ${WT_WIDTH}
    return 1
  fi
  return 0
}

linux_init () {
  linux_init_os
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  linux_init_arch
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1

  linux_init_pkg_mgr
  RET=$?
  [[ ${RET} -eq 1 ]] && return 1
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
  --msgbox  'Before continuing to main menu, you need to set some information about your linux distribution' ${WT_HEIGHT} ${WT_WIDTH}
  linux_init
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    whiptail --title 'ERROR' --msgbox 'An error occured during initialisation.\n
Some part of your linux distribution are not supported yet.\n
The program will exit' ${WT_HEIGHT} ${WT_WIDTH}
    return 1
  fi

  MAIN_MENU="whiptail --title 'Main Menu' --menu  'Select what you want to do :' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
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
