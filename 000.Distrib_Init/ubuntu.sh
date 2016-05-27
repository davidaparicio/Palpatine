#!/bin/bash

VER=('16.04')

YUNOHOST=true
DOCKER=true
DOCKER_MAJOR_KERNEL=3
DOCKER_MINOR_KERNEL=10

# List of arch, OS and version supported
ARCH=('x86_64')

# List of supported package manager
PKG_MGR=('apt-get' 'apt' 'aptitude')

do_fullupdate () {
  # Update repo database, upgrade app and upgrade distrib if available
  whiptail --title 'Update Repo and Upgrade' \
  --msgbox 'This script will now update and upgrade the system' \
  ${WT_HEIGHT} ${WT_WIDTH}

  ${LINUX_PKG_MGR} update
  ${LINUX_PKG_MGR} upgrade -y
  ${LINUX_PKG_MGR} dist-upgrade -y
  NEED_UPDATE=false

  return 0
}

do_setup_pkg_base () {
  # Install packages that will be required later if they are not installed
  local do_base_setup=false
  if ! dpkg -s apt-transport-https | grep installed | grep -q ok
  then
    do_base_setup=true
  fi
  if ! dpkg -s software-properties-common | grep installed | grep -q ok
  then
    do_base_setup=true
  fi
  if ! dpkg -s python-software-properties | grep installed | grep -q ok
  then
    do_base_setup=true
  fi
  if [[ ${do_base_setup} == true ]]
  then
    whiptail --title 'Setup Base Package' \
      --msgbox 'This script will now install the following packages :
      - apt-transport-https
      - software-properties-common
      - python-software-properties ' ${WT_HEIGHT} ${WT_WIDTH}

    ${LINUX_PKG_MGR} install -y \
      apt-transport-https \
      software-properties-common \
      python-software-properties
  fi
  BASE_PKG_INSTALLED=true
  return 0
}

init_distrib() {
  do_setup_pkg_base
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  return 0
}

