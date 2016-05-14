#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=':TOOLS'
APP_TOOLS_CAT="Utility and Accessories"
APP_TOOLS_EX="Some usefull tools, utility and accessories."
# END WM INFO

idx=0
APP_TOOLS_NAME[idx]="htop"
APP_TOOLS_DESC[idx]="An interactive process viewer for Unix systems"
APP_TOOLS_STAT[idx]="OFF"
htop_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y htop
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))

APP_TOOLS_NAME[idx]="gparted"
APP_TOOLS_DESC[idx]="A free partition editor for graphically managing your disk partitions"
APP_TOOLS_STAT[idx]="OFF"
gparted_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y gparted
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))

APP_TOOLS_NAME[idx]="xclip"
APP_TOOLS_DESC[idx]="Command line clipboard"
APP_TOOLS_STAT[idx]="OFF"
xclip_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y xclip
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}
(( idx++ ))
