#!/bin/bash

# BEGIN VC INFO
ALL_APP_CAT+=':VC'
APP_VC_CAT="Version Control"
APP_VC_EX="Version Control System (VCS)"
# END WM INFO

idx=0
APP_TOOLS_NAME[idx]="git"
APP_TOOLS_DESC[idx]="Version Control System"
APP_TOOLS_STAT[idx]="ON"
git_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y git
    ;;
  *)
    echo "This script does not support installation of git on your OS"
  esac
}
(( idx++ ))

APP_TOOLS_NAME[idx]="vcsh"
APP_TOOLS_DESC[idx]="Version Control System for \$HOME"
APP_TOOLS_STAT[idx]="ON"
vcsh_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y vcsh
    ;;
  *)
    echo "This script does not support installation of vcsh on your OS"
  esac
}
(( idx++ ))

APP_TOOLS_NAME[idx]="myRepo"
APP_TOOLS_DESC[idx]="Multiple Repository management tool"
APP_TOOLS_STAT[idx]="ON"
myRepo_routine () {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y mr
    ;;
  *)
    echo "This script does not support installation of myRepo on your OS"
  esac
}
(( idx++ ))


APP_VC_NAME[idx]="CVS"
APP_VC_DESC[idx]="Concurrent Versions System (CVS)"
APP_VC_STAT[idx]="OFF"
CVS_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y cvs
    ;;
  *)
    echo "This script does not support installation of CVS on your OS"
  esac
}
(( idx++ ))

APP_VC_NAME[idx]="Mercurial"
APP_VC_DESC[idx]="VCS that aims to be fast, lightweight, portable and easy to use"
APP_VC_STAT[idx]="OFF"
Mercurial_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y mercurial
    ;;
  *)
    echo "This script does not support installation of mercurial on your OS"
  esac
}
(( idx++ ))

APP_VC_NAME[idx]="Subversion"
APP_VC_DESC[idx]="VCS inspired by CSV"
APP_VC_STAT[idx]="OFF"
Subversion_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y subversion
    ;;
  *)
    echo "This script does not support installation of subversion on your OS"
  esac
}
(( idx++ ))
