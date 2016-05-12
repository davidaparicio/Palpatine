#!/bin/bash
LC_ALL_bak=${LC_ALL}
LC_ALL=C


ASK_TO_REBOOT=false
BASE_PKG_INSTALLED=true
NEED_UPDATE=false
IS_SSH=false
IS_ROOT=false
LINUX_OS='Unknown'
LINUX_VER='Unknown'
LINUX_ARCH='Unknown'
LINUX_PKG_MGR='Unknown'
LINUX_IS_RPI=false

SUPPORTED_ARCH[0]='x86_64'
SUPPORTED_ARCH[1]='arm'

SUPPORTED_OS[0]='ubuntu'
SUPPORTED_UBUNTU_VER[0]='16.04'

SUPPORTED_OS[1]='debian'
SUPPORTED_DEBIAN_VER[0]='8'

SUPPORTED_OS[2]='raspbian'
SUPPORTED_RASPBIAN_VER[0]='8'

SUPPORTED_PKG_MGR[0]='apt-get'
SUPPORTED_PKG_MGR[1]='apt'
SUPPORTED_PKG_MGR[2]='aptitude'

################################################################################
# INSTALL AND UPDATE DEPANDING ON PACKAGE MANAGER
################################################################################
do_fullupdate () {
  whiptail --title 'Update Repo and Upgrade' \
  --msgbox 'This script will now update and upgrade the system' ${WT_HEIGHT} ${WT_WIDTH}
  case ${LINUX_PKG_MGR} in
    apt* )
    ${LINUX_PKG_MGR} update && ${LINUX_PKG_MGR} upgrade -y && ${LINUX_PKG_MGR} dist-upgrade -y
    NEED_UPDATE=false
    ;;
    * )
      echo "Programmer error : Option ${LINUX_PKG_MGR} not supported."
    ;;
  esac
  return 0
}

do_setup_pkg_base () {
  case ${LINUX_PKG_MGR} in
    apt* )
    whiptail --title 'Setup Base Package' \
      --msgbox 'This script will now install the following packages :
      - apt-transport-https
      - software-properties-common
      - python-software-properties ' ${WT_HEIGHT} ${WT_WIDTH}
    ${LINUX_PKG_MGR} install -y \
    apt-transport-https \
    software-properties-common \
    python-software-properties
    ;;
    * )
      echo "Programmer error : Option ${LINUX_PKG_MGR} not supported."
    ;;
  esac
  BASE_PKG_INSTALLED=true
  return 0
}

################################################################################
# NOT INTERACTIVE MENU JUST ASK PACKAGE MANAGER TO USE TO INSTAL WHIPTAIL
################################################################################
install_whiptail () {
  local sep_line=$( printf "%-${WT_WIDTH}s" "=")
  sep_line=${sep_line// /=}

  local nb_pkg_mgr=${#SUPPORTED_PKG_MGR[@]}
  local exist_pkg_mgr=false
  local pkg_mgr_menu="
${sep_line}
| Pre-Init : Choose package manager
${sep_line}
|
|  WARNING : whiptail does not seems to be install. Which package manager use
|  to install whiptail ?
|  To do so, enter the number in front of the name of you package manager.
|"
  local no_pkg_mgr_menu="
${sep_line}
|                    Pre-Init : No supported package manager                   |
${sep_line}
|
|  WARNING : whiptail does not seems to be install and you do not seem to have
|  a supported package manager.
|  Here is a list of supported package manager
|"

  for (( idx=0; idx < ${nb_pkg_mgr}; idx++ ))
  do
    if type -t ${SUPPORTED_PKG_MGR[idx]} &>/dev/null
    then
      exist_pkg_mgr=true
    fi
    pkg_mgr_menu="${pkg_mgr_menu}
|  ${idx} - ${SUPPORTED_PKG_MGR[idx]} "
    no_pkg_mgr_menu="${no_pkg_mgr_menu}
|  ${idx} - ${SUPPORTED_PKG_MGR[idx]} "
  done

  pkg_mgr_menu="${pkg_mgr_menu}
|
${sep_line}"
  no_pkg_mgr_menu="${pkg_mgr_menu}
|
${sep_line}"
  if ! ${EXIST_PKG_MGR}
  then
      echo ${no_pkg_mgr_menu}
      return 1
  fi

  while true
  do
    clear
    echo "${pkg_mgr_menu}" ; read CHOICE
    if [[ ${CHOICE} == [0-9] ]] && [[ ${CHOICE} -lt ${#SUPPORTED_PKG_MGR[@]} ]]
    then
      LINUX_PKG_MGR=${SUPPORTED_PKG_MGR[CHOICE]}
      $LINUX_PKG_MGR install whiptail
      return 0
    else
      echo "${sep_line}
Please enter a valid number
Do you want to retry ? [Y/n]" ; read CHOICE
      if ! [[ ${#CHOICE} -eq 0 ]] || ! [[ "YyYesyes" =~ ${CHOICE} ]]
      then
        clear
        echo "${sep_line}
Setup aborted !" ; read ; exit 1
      fi
    fi
  done
}

###############################################################################
# FUNCTION
###############################################################################
top_level_parent_pid () {
  # Look up the parent of the given PID.
  pid=${1:-$$}
  stat=($(</proc/${pid}/stat))
  ppid=${stat[3]}

  # /sbin/init always has a PID of 1, so if you reach that, the current PID is
  # the top-level parent. Otherwise, keep looking.
  # As the recurse process is here to find if connected through ssh, then it
  # will stop if one of the parent process is ssh
  if ps -p $ppid | grep -q ssh
  then
    IS_SSH=true
    return 0
  fi

  if ! [[ ${ppid} -eq 1 ]]
  then
    top_level_parent_pid ${ppid}
  fi
}

preamble() {
  [[ $( whoami ) == "root" ]] && IS_ROOT=true
  top_level_parent_pid $PPID

  if ! ${IS_ROOT} && ! ${IS_SSH}
  then
    whiptail --title "ERROR" \
      --msgbox "Please run this script as root, you can either log as root or use sudo. \n
N.B. : It will work better if run through ssh" ${WT_HEIGHT} ${WT_WIDTH}
    exit 1
  elif ! ${IS_ROOT} && ${IS_SSH}
  then
    whiptail --title "ERROR" \
      --msgbox "You seems to be connected by SSH, that is goot but you MUST be log as root.\n
You can either log as root or use sudo" ${WT_HEIGHT} ${WT_WIDTH}
    exit 1
  elif ${IS_ROOT} && ! ${IS_SSH}
  then
    whiptail --title "WARNING" --msgbox "You run this script as root but not through SSH.
Process will continue but some part might not be working.\n
N.B. : This will mainly impact git/vcsh configuration and the copy of your ssh-key to your favorite version controle host." \
${WT_HEIGHT} ${WT_WIDTH}
  fi
  if ( whiptail --title "WARNING" --yesno "
  THERE IS NO WARRANTY FOR THIS PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE \
LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER \
PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY OF ANY KIND, EITHER \
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF \
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE \
QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE \
DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION. \
                                --- BE CAREFUL!---

  Continue ?
  " ${WT_HEIGHT} ${WT_WIDTH} )
  then
    return 0
  else
    exit 1
  fi
}

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
  WT_WIDE_HEIGHT=34
  WT_WIDE_MENU_HEIGHT=$((${WT_WIDE_HEIGHT}-9))
}

################################################################################
# INTERACTIVE MENU
################################################################################
# Package manager selection
linux_init_pkg_mgr () {
  local nb_pkg_mgr=${#SUPPORTED_PKG_MGR[@]}
  local exist_pkg_mgr=false
  local pkg_mgr_menu="whiptail --title 'Linux Init : Package Manager' \
    --menu 'Please choose the package manager you want to use : ' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  local no_pkg_mgr_menu="whiptail --title 'Linux Init : Package Manager' \
    --msgbox 'Sorry but you do not to have one of the package manager supported installed.
Here is the list of supported package manager :
    "

  for (( idx=0; idx < ${nb_pkg_mgr}; idx++ ))
  do
    if type -t ${SUPPORTED_PKG_MGR[idx]} &>/dev/null
    then
      exist_pkg_mgr=true
    fi
    pkg_mgr_menu="${pkg_mgr_menu} '${SUPPORTED_PKG_MGR[idx]}' ''"
    no_pkg_mgr_menu="${no_pkg_mgr_menu}    - ${SUPPORTED_PKG_MGR[idx]} \n
    "
  done
  pkg_mgr_menu="${pkg_mgr_menu} 'NONE OF THEM' ''"
  no_pkg_mgr_menu="${no_pkg_mgr_menu} ' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  if ! ${EXIST_PKG_MGR}
  then
      bash -c "${no_pkg_mgr_menu} "
      return 1
  fi

  bash -c "${pkg_mgr_menu} " 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )

  case ${CHOICE} in
  "NONE OF THEM")
    return 1
    ;;
  *)
    LINUX_PKG_MGR=${CHOICE}
    return 0
    ;;
  esac
  return 0
}

# Function to choose OS/VER/ARCH
choose_linux_var () {
  local linux_var=$1
  local arr_supported_var
  if [[ "${linux_var}" == "OS" ]]
  then
    # Get supported OS and validate it
    arr_supported_var="SUPPORTED_OS[@]"
    arr_supported_var=("${!arr_supported_var}")
  elif [[ "${linux_var}" == "VER" ]]
  then
    # Get supported version for validated OS
    arr_supported_var="SUPPORTED_${LINUX_OS^^}_VER[@]"
    arr_supported_var=("${!arr_supported_var}")
  elif [[ "${linux_var}" == "ARCH" ]]
  then
    # Get supported architecture
    arr_supported_var="SUPPORTED_ARCH[@]"
    arr_supported_var=("${!arr_supported_var}")
  fi

  local menu="whiptail --title 'Linux Init' \
  --menu 'You can choose to specify linux $linux_var that is like your. \n
This will run the rest of the script assuming it is the version you will choose. \n
(N.B.: This is to manage source, repo, etc.) \n
If you choose \"NONE OF THEM\", the program will exit) ? ' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  for (( idx=0 ; idx < ${#arr_supported_var[@]} ; idx++ ))
  do
    menu="${menu} ${arr_supported_var[idx]} ''"
  done
  menu="${menu} 'NONE OF THEM' ''"

  bash -c "${menu} " 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  CHOICE=$( cat results_menu.txt )

  if [[ "${CHOICE}" == "NONE OF THEM" ]]
  then
    return 1
  else
    if [[ "${linux_var}" == "OS" ]]
    then
      # Set supported OS
      os_valid_true=true
      LINUX_OS=${CHOICE}
    elif [[ "${linux_var}" == "VER" ]]
    then
      # Set supported version
      ver_valid=true
      LINUX_VER=${CHOICE}
    elif [[ "${linux_var}" == "ARCH" ]]
    then
      # Set supported arch
      arch_valid=true
      LINUX_ARCH=${CHOICE}
    fi
    return 0
  fi
}

# Ask user if arch is arm if it's a raspberry
ask_rpi () {
  if [[ ${TMP_ARCH} =~ 'arm' ]]
  then
    if ( whiptail --title 'Linux Init : Archictecture' --yesno "\
It seems you are on an arm machine. \n \
Is it a raspberry ? " ${WT_HEIGHT} ${WT_WIDTH} )
    then
      LINUX_IS_RPI=true
    fi
  fi
  return 0
}

linux_init_os () {
  local arr_supported_ver
  local linux_user_set=false
  local linux_valid=false
  local arch_valid=false
  local ver_valid=false
  local os_valid=false
  local tmp_arch
  local tmp_ver
  local tmp_ver_name
  local tmp_os
  local tmp_os_name

  tmp_arch=$( arch )
  tmp_ver=$( cat /etc/os-release | grep ^VERSION_ID | cut -d '"' -f 2 )
  tmp_ver_name=$( cat /etc/os-release | grep ^VERSION= | cut -d '"' -f 2 )
  tmp_os=$( cat /etc/os-release | grep ^ID | cut -d '=' -f2 )
  tmp_os_name=$( cat /etc/os-release | grep ^NAME | cut -d '"' -f2 )

  if ( whiptail \
    --title 'Linux Init : Validation of your OS' \
    --yesno "You seems to be running on : \n\n ${tmp_os_name} - ${tmp_ver_name} - ${tmp_arch} \n\nIs it right ? " ${WT_HEIGHT} ${WT_WIDTH} )
  then
    # Validate OS
    if [[ ${SUPPORTED_OS[@]} =~ ${tmp_os} ]]
    then
      os_valid=true
      LINUX_OS=${tmp_os}
    fi
    # Get supported version for validated OS and validate it
    arr_supported_ver="SUPPORTED_${LINUX_OS^^}_VER"
    arr_supported_ver=("${!arr_supported_ver}")
    if [[ ${arr_supported_ver[@]} =~ ${tmp_ver} ]]
    then
      ver_valid=true
      LINUX_VER=${tmp_ver}
    fi
    # Validate arch
    if [[ ${SUPPORTED_ARCH[@]} =~ ${tmp_arch} ]]
    then
      arch_valid=true
      LINUX_ARCH=${tmp_arch}
    fi

    if ${os_valid} && ${ver_valid} && ${arch_valid}
    then
      return 0
    else
      if ! ${os_valid} || ! ${ver_valid}
      then
        whiptail --title 'Linux Init' \
        --msgbox 'Your OS is not supported, you will be ask if you want to \
choose amoung supported OS and version'
        choose_linux_var 'OS'
        RET=$? ; [[ ${RET} -eq 1 ]] && return 1
        choose_linux_var 'VER'
        RET=$? ; [[ ${RET} -eq 1 ]] && return 1
        linux_user_set=true
      fi
      if ! ${arch_valid}
      then
        whiptail --title 'Linux Init' \
        --msgbox 'Your archictecture does not seem to be supported, you will be \
ask if you want to choose amoung supported one.'
        choose_linux_var 'ARCH'
        RET=$? ; [[ ${RET} -eq 1 ]] && return 1
        linux_user_set=true
      fi
      if $linux_user_set && ( whiptail --title 'Linux Init' \
        --yesno "Do you want to continue with the followin option for you linux ?

      --> ${LINUX_OS} - ${LINUX_VER} - ${LINUX_ARCH}

      YES : The script will continue assuming your linux is like you set, BUT some part might not be working.
      NO  : The script will exit." ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 0
      else
        return 1
      fi
    fi
    return 0
  else
    choose_linux_var 'OS'
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    choose_linux_var 'VER'
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    choose_linux_var 'ARCH'
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    return 0
  fi
}

linux_init () {
  linux_init_os
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  linux_init_pkg_mgr
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  return 0
}

###############################################################################
# MAIN MENU
###############################################################################
main_menu () {
  local main_menu

  whiptail \
    --title 'Linux Config' \
    --msgbox  'Before continuing to main menu, you need to set some information about your linux distribution' \
    ${WT_HEIGHT} ${WT_WIDTH}
  linux_init
  RET=$? ; [[ ${RET} -eq 1 ]] && whiptail --title 'ERROR' \
    --msgbox 'An error occured during initialisation.\n
Some part of your linux distribution are not supported yet.\n
The program will exit' ${WT_HEIGHT} ${WT_WIDTH} && return 1

  main_menu="whiptail --title 'Main Menu' --menu  'Select what you want to do :' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
  'Initial setup'    'Access to initial config such as timezone, hostname...' \
  'Package setup'    'Select package to install' \
  'User Management'  'Manage user (add, update, delete)' \
  'FINISH'           'Exit the script'"

  while true
  do
    bash -c "${main_menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    # Sourcing file to that it's possible do modify file while script is running
    case ${CHOICE} in
    'FINISH' )
      return 0
      ;;
    'Initial setup' )
      source 001.Initial_Setup/initial_setup.sh
      initial_setup
      ;;
    'Package setup' )
      [[ ${NEED_UPDATE} == true ]] && do_fullupdate
      [[ ${BASE_PKG_INSTALLED} == false ]] && do_setup_pkg_base
      source 002.Package_Setup/package_setup.sh
      package_setup
      ;;
    'User Management')
      source 003.User_Management/user_management.sh
      user_management
      ;;
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
      return 1
      ;;
   esac
  done
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR}

calc_wt_size
preamble

if ! type -t whiptail &>/dev/null
then
  install_whiptail
fi

main_menu
RET=$? ; [[ ${RET} -eq 1 ]] && exit 1

#if [[ ${ASK_TO_REBOOT} ]] \
#  && ( whiptail --title 'REBOOT NEEDED' \
#    --yesno 'A reboot is needed. Do you want to reboot now ? ' \
#    ${WT_HEIGHT} ${WT_WIDTH} )
#then
#  reboot
#fi

LC_ALL=${LC_ALL_bak}
locale
