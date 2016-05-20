#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=":SHELL"
APP_SHELL_CAT="Shell"
APP_SHELL_EX="A set of Bourne Shell"
# END WM INFO

idx=0

APP_SHELL_NAME[idx]="ash"
APP_SHELL_DESC[idx]="Written as a BSD-licensed replacement for the Bourne Shell"
APP_SHELL_STAT[idx]="OFF"
ash_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y ash
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))

APP_SHELL_NAME[idx]="dash"
APP_SHELL_DESC[idx]="A modern replacement for ash in Debian and Ubuntu"
APP_SHELL_STAT[idx]="OFF"
dash_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y dash
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))

APP_SHELL_NAME[idx]="mksh"
APP_SHELL_DESC[idx]="A descendant of the OpenBSD /bin/ksh and pdksh, developed as part of MirOS BSD"
APP_SHELL_STAT[idx]="OFF"
mksh_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y mksh
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))

APP_SHELL_NAME[idx]="zsh"
APP_SHELL_DESC[idx]="A relatively modern shell that is backward compatible with bash"
APP_SHELL_STAT[idx]="ON"
zsh_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y zsh
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))
