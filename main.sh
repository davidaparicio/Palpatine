#!/bin/bash

# Get script directory, gonna need sometime to be sure to get back to the right
# directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

# SUPPORTED SYSTEM
################################################################################
# List of OS on which Yunohost can be installed
SUPPORTED_OS[0]='debian'
SUPPORTED_OS[1]='ubuntu'

# BACKUP ENV VARIABLE
################################################################################
# Backup LC_ALL because it will be change by the script to make regex working
LC_ALL_bak=$LC_ALL
LC_ALL=C

# TEST BOOLEAN
################################################################################
# Different boolean init
NEED_UPDATE=false
ASK_TO_REBOOT=false
BASE_PKG_INSTALLED=false
# Preamble boolean init
IS_SSH=false
IS_ROOT=false

# LINUX ENVIRONNEMENT
################################################################################
# Variable about LINUX OS.
LINUX_IS_RPI=false
LINUX_OS='Unknown'
LINUX_VER='Unknown'
LINUX_ARCH='Unknown'
LINUX_PKG_MGR='Unknown'
LINUX_LOCAL_IP='Unknown'

# TOOLS
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
  WT_WIDE_HEIGHT=34
  WT_WIDE_MENU_HEIGHT=$((${WT_WIDE_HEIGHT}-9))
}

################################################################################
# INTERACTIVE MENU
################################################################################
# CHECK ROOT SSH
################################################################################
test_ssh() {
  # Look up the parent of the given PID.
  pid=${1:-$$}
  stat=($(</proc/${pid}/stat))
  ppid=${stat[3]}

  # /sbin/init always has a PID of 1, so if you reach that, the current PID is
  # the top-level parent. Otherwise, keep looking.
  # As the recurse process is here to find if connected through ssh, then it
  # will stop if one of the parent process is ssh
  ps -p $ppid | grep -q ssh && IS_SSH=true && return 0

  ! [[ ${ppid} -eq 1 ]] && test_ssh ${ppid}
}

noroot_nossh () {
  whiptail --title 'ERROR' \
    --msgbox "\
    Please run this script as root, you can either log as root or use sudo.

N.B. : It will work better if run through ssh" ${WT_HEIGHT} ${WT_WIDTH}
    exit 1
}

noroot_ssh() {
  whiptail --title 'ERROR' \
    --msgbox "\
You seems to be connected by SSH, that is goot but you MUST be log as root.

You can either log as root or use sudo" ${WT_HEIGHT} ${WT_WIDTH}
    exit 1
}

root_nossh() {
  whiptail --title 'WARNING' \
    --msgbox "\
You run this script as root but not through SSH.
Process will continue but some part might not be working.

N.B. : This will mainly impact git/vcsh configuration and the copy of your \
ssh-key to your favorite version controle host. If you can open a web browser
because you already install a window manager, everyhting should be alright." \
  ${WT_HEIGHT} ${WT_WIDTH}
  return 0
}

test_rootssh() {
  # Check if user is root, if it's connect through SSH and warn it that I'm not
  # responsible if damage occurs else warn it that nothing will be done
  [[ $( whoami ) == 'root' ]] && IS_ROOT=true
  test_ssh $PPID

  if ! ${IS_ROOT} && ! ${IS_SSH}
  then
    noroot_nossh
  elif ! ${IS_ROOT} && ${IS_SSH}
  then
    noroot_ssh
  elif ${IS_ROOT} && ! ${IS_SSH}
  then
    root_nossh
  fi
}

# PREAMBLE
################################################################################
preamble() {
  whiptail --title 'WARNING' --yesno "
  THERE IS NO WARRANTY FOR THIS PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE \
LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER \
PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY OF ANY KIND, EITHER \
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF \
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE \
QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE \
DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION. \

--- BE CAREFUL ! ---

  Continue ?
  " ${WT_HEIGHT} ${WT_WIDTH} && return 0 || exit 1
}

# SET LINUX DISTRIB AND PKG INFO
################################################################################
linux_init_pkg_mgr () {
  # Package manager selection
  local exist_pkg_mgr=false
  menu="whiptail --title 'Linux Init : Package Manager' \
    --menu 'Please choose the package manager you want to use : ' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  local no_menu="whiptail --title 'Linux Init : Package Manager' \
    --msgbox 'Sorry but you do not to have one of the package manager supported installed.
Here is the list of supported package manager :
    "

  for (( idx=0 ; idx < ${#PKG_MGR[@]} ; idx++ ))
  do
    if type -t ${PKG_MGR[idx]} &>/dev/null
    then
      exist_pkg_mgr=true
    fi
    menu="${pkg_mgr_menu} '${PKG_MGR[idx]}' ''"
    no_menu="${no_pkg_mgr_menu}    - ${PKG_MGR[idx]} \n
    "
  done
  menu="${no_menu} 'NONE OF THEM' ''"
  no_menu="${no_menu} ' ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  ! ${EXIST_PKG_MGR} && bash -c "${no_menu} " && return 1

  bash -c "${menu} " 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1 ||  CHOICE=$( cat results_menu.txt )

  [[ ${CHOICE} == "NONE OF THEM" ]] && return 1 || LINUX_PKG_MGR=${CHOICE}
  return 0
}

choose_linux_arch() {
  menu="whiptail --title 'Linux Init' \
  --menu 'You can choose to specify linux architecture that is like your.
This will run the rest of the script assuming it is the version you will choose.
(N.B.: This is to manage source, repo, etc.)
If you choose \"NONE OF THEM\", the program will exit) ? ' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  for (( idx=0 ; idx < ${#ARCH[@]} ; idx++ ))
  do
    menu="${menu} ${ARCH[idx]} ''"
  done
  menu="${menu} 'NONE OF THEM' ''"

  bash -c "${menu} " 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1 ||  CHOICE=$( cat results_menu.txt )

  [[ "${CHOICE}" == "NONE OF THEM" ]] && return 1 || LINUX_ARCH=${CHOICE}
  return 0
}

choose_linux_ver() {
  menu="whiptail --title 'Linux Init' \
  --menu 'You can choose to specify linux version that is like your.
This will run the rest of the script assuming it is the version you will choose.
(N.B.: This is to manage source, repo, etc.)
If you choose \"NONE OF THEM\", the program will exit) ? ' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  for (( idx=0 ; idx < ${#VER[@]} ; idx++ ))
  do
    menu="${menu} ${VER[idx]} ''"
  done
  menu="${menu} 'NONE OF THEM' ''"

  bash -c "${menu} " 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1 ||  CHOICE=$( cat results_menu.txt )

  [[ "${CHOICE}" == "NONE OF THEM" ]] && return 1 || LINUX_VER=${CHOICE}
  return 0
}

choose_linux_os() {
  menu="whiptail --title 'Linux Init' \
  --menu 'You can choose to specify linux OS that is like your.
This will run the rest of the script assuming it is the version you will choose.
(N.B.: This is to manage source, repo, etc.)
If you choose \"NONE OF THEM\", the program will exit) ?' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"

  for (( idx=0 ; idx < ${#SUPPORTED_OS[@]} ; idx++ ))
  do
    menu="${menu} ${SUPPORTED_OS[idx]} ''"
  done
  menu="${menu} 'NONE OF THEM' ''"

  bash -c "${menu} " 2> results_menu.txt
  [[ $? -eq 1 ]] && return 1 ||  CHOICE=$( cat results_menu.txt )

  [[ "${CHOICE}" == "NONE OF THEM" ]] && return 1 || LINUX_OS=${CHOICE}
  return 0
}

validate_arch() {
  # Validate arch
  if ! [[ ${#tmp_arch} -eq 0 ]] && [[ ${ARCH[@]} =~ ${tmp_arch} ]]
  then
    LINUX_ARCH=${tmp_arch}
  else
    whiptail --title 'Linux Init' \
    --msgbox 'Your archictecture does not seem to be supported, you will be \
ask if you want to choose amoung supported one.' ${WT_HEIGHT} ${WT_WIDTH}
    choose_linux_arch
    [[ $? -eq 1 ]] && return 1
  fi
  return 0
}

validate_ver() {
  if ! [[ ${#tmp_ver} -eq 0 ]] && [[ ${VER[@]} =~ ${tmp_ver} ]]
  then
    LINUX_VER=${tmp_ver}
  else
    choose_linux_ver
    [[ $? -eq 1 ]] && return 1
  fi
  return 0
}

validate_os() {
  # Validate OS
  if ! [[ ${#tmp_os} -eq 0 ]] && [[ ${SUPPORTED_OS[@]} =~ ${tmp_os} ]]
  then
    LINUX_OS=${tmp_os}
  else
    choose_linux_os
    [[ $? -eq 1 ]] && return 1
  fi
}

validate() {
  validate_os
  if [[ $? -eq 1 ]]
  then
    choose_linux_os
    [[ $? -eq 1 ]] && return 1
  fi

  source 000.Distrib_Init/${LINUX_OS,,}.sh

  validate_ver
  if [[ $? -eq 1 ]]
  then
    choose_linux_ver
    [[ $? -eq 1 ]] && return 1
  fi

  validate_arch
  if [[ $? -eq 1 ]]
  then
    choose_linux_arch
    [[ $? -eq 1 ]] && return 1
  fi
  return 0
}

choose() {
  choose_linux_os
  [[ $? -eq 1 ]] && return 1
  source 000.Distrib_Init/${LINUX_OS,,}.sh
  choose_linux_ver
  [[ $? -eq 1 ]] && return 1
  choose_linux_arch
  [[ $? -eq 1 ]] && return 1
  return 0
}


linux_init_os () {
  # Check linux distrib to know if it's supported
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
  tmp_ver=$( cat /etc/os-release | grep "^VERSION_ID=" | cut -d '"' -f 2 )
  tmp_ver_name=$( cat /etc/os-release | grep "^VERSION=" | cut -d '"' -f 2 )
  tmp_os=$( cat /etc/os-release | grep "^ID=" | cut -d '=' -f2 )
  tmp_os_name=$( cat /etc/os-release | grep "^NAME=" | cut -d '"' -f2 )

  if ( whiptail \
    --title 'Linux Init' \
    --yesno "You seems to be running on :

  ${tmp_os_name} - ${tmp_ver_name} - ${tmp_arch}

  Is it right ?" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    validate
    [[ $? -eq 1 ]] && return 1
  else
    choose
    [[ $? -eq 1 ]] && return 1
  fi
  whiptail --title 'Linux Init' \
    --yesno "Do you want to continue with the following option for you linux ?
    --> ${LINUX_OS} - ${LINUX_VER} - ${LINUX_ARCH}

    YES : The script will continue assuming your linux is like you set, BUT some part might not be working.
    NO  : The script will exit." ${WT_HEIGHT} ${WT_WIDTH} && return 0 || return 1
}

linux_not_supported() {
  whiptail --title 'ERROR' \
    --msgbox 'An error occured during initialisation.\n
Some part of your linux distribution are not supported yet.\n
The program will exit' ${WT_HEIGHT} ${WT_WIDTH}
  exit 1
}

linux_init () {
  # Run validation of linux distrib and package manager
  whiptail \
    --title 'Linux Config' \
    --msgbox  "Before continuing to main menu, you need to set some information \
about your linux distribution" ${WT_HEIGHT} ${WT_WIDTH}

  linux_init_os
  [[ $? -eq 1 ]] && linux_not_supported

  linux_init_pkg_mgr
  [[ $? -eq 1 ]] && linux_not_supported

  return 0
}

###############################################################################
# MAIN MENU
###############################################################################
main_menu() {
  source 000.Distrib_Init/${LINUX_OS,,}.sh
  local menu="whiptail --title 'Main Menu' --menu  'Select what you want to do :' \
  ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
  'Initial setup'    'Access to initial config such as timezone, hostname...' \
  'Package setup'    'Select package to install' \
  'User Management'  'Manage user (add, update, delete)'"

  ${YUNOHOST} && main_menu="${main_menu} \
      'Yunohost Management' 'Basic Yunohst management (installation, user, app)'"

#  ${DOCKER} && main_menu="${main_menu} \
#      'Docker Management' 'Basic Docker management'"

  main_menu="${main_menu} \
  'OpenVPN'         'Configure OpenVPN' \
  'FINISH'          'Exit the script'"

  while true
  do
    bash -c "${main_menu}" 2> results_menu.txt
    [[ $? -eq 1 ]] && return 1 || CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
    'FINISH' )
      return 0
      ;;
    'Initial setup' )
      source 001.Initial_Setup/initial_setup.sh
      initial_setup_go_through
      ;;
    'Package setup' )
      source 002.Package_Setup/package_setup.sh
      [[ ${NEED_UPDATE} == true ]] && do_fullupdate
      [[ ${BASE_PKG_INSTALLED} == false ]] && do_setup_pkg_base
      package_setup
      ;;
    'User Management')
      source 003.User_Management/user_management.sh
      user_management
      ;;
    'Yunohost Management')
      source 004.Yunohost_management/yunohost_management.sh
      ynh_management
      ;;
#    'Docker Management')
#      source 005.Docker_management/docker_management.sh
#      docker_management
#      ;;
    'OpenVPN')
      source 006.OpenVPN/openvpn_config.sh
      openvpn_config
      ;;
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
      return 1
      ;;
   esac
  done
}

################################################################################
################################################################################
#                                                                              #
#                       MAIN CALLING FUNCTION                                  #
#                                                                              #
################################################################################
################################################################################
# Compute terminal size
calc_wt_size
# Install whiptail if needed
if ! type -t whiptail &>/dev/null
then
  echo =========================================================================
  echo ERROR
  echo "Sorry but for the moment, we assume you have whiptail installed but it
does not seem to be installed yet.

Please install it first."
  echo Script will now quit
  echo =========================================================================
  read
  exit 1
fi
# Test if root and ssh
test_rootssh
# Warn the user
preamble
# Initialisation of linux distrib
linux_init
[[ $? -eq 1 ]] && rm -f cmd.sh results_menu.txt && exit 1
# Source distrib preinit function and variable
source 000.Distrib_Init/${LINUX_OS,,}.sh
init_distrib
# Now run the script
main_menu
[[ $? -eq 1 ]] && rm -f cmd.sh results_menu.txt && exit 1
# Reboot if needed
${ASK_TO_REBOOT} && ( whiptail --title 'REBOOT NEEDED' \
    --yesno 'A reboot is needed. Do you want to reboot now ? ' \
    ${WT_HEIGHT} ${WT_WIDTH} ) && reboot

