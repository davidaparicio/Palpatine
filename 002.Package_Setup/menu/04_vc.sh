#!/bin/bash

# BEGIN VC INFO
ALL_APP_CAT+=':VC'
APP_VC_CAT="Version Control"
APP_VC_EX="Version Control System (VCS)"
# END WM INFO

idx=0
APP_VC_NAME[idx]="git"
APP_VC_DESC[idx]="Version Control System"
APP_VC_STAT[idx]="ON"
git_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y git
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))

APP_VC_NAME[idx]="vcsh"
APP_VC_DESC[idx]="Version Control System for \$HOME"
APP_VC_STAT[idx]="ON"
vcsh_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y vcsh
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))

APP_VC_NAME[idx]="myRepo"
APP_VC_DESC[idx]="Multiple Repository management tool"
APP_VC_STAT[idx]="ON"
myRepo_routine () {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y mr
    ;;
  *)
    return 1
  esac
  return 0
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
    return 1
  esac
  return 0
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
    return 1
  esac
  return 0
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
    return 1
  esac
  return 0
}
(( idx++ ))
