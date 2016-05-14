#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=":WM"
APP_WM_CAT="Window Manager"
APP_WM_EX="A set of window manager"
# END WM INFO

idx=0

APP_WM_NAME[idx]="Awesome_3.4"
APP_WM_DESC[idx]="A light and very customable WM v3.4"
APP_WM_STAT[idx]="ON"
Awesome_3.4_routine () {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y awesome awesome-extra
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))

APP_WM_NAME[idx]="Awesome_3.5"
APP_WM_DESC[idx]="A light and very customable WM v3.5"
APP_WM_STAT[idx]="ON"
Awesome_3.5_routine() {
  case ${LINUX_OS} in
  ubuntu)
    add-apt-repository -y ppa:klaus-vormweg/awesome
    ${LINUX_PKG_MGR} update && ${LINUX_PKG_MGR} install -y awesome awesome-extra
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))

APP_WM_NAME[idx]="KDE"
APP_WM_DESC[idx]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[idx]="ON"
KDE_routine() {
  case ${LINUX_OS} in
  ubuntu)
    ${LINUX_PKG_MGR} install -y kde-full
  ;;
  *)
    return 1
  ;;
  esac
  return 0
}
(( idx++ ))

APP_WM_NAME[idx]="Gnome"
APP_WM_DESC[idx]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[idx]="ON"
Gnome_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
    ${LINUX_PKG_MGR} install -y ubuntu-gnome-desktop
  ;;
  *)
    return 1
  ;;
  esac
  return 0
}
(( idx++ ))

APP_WM_NAME[idx]="XFCE_4"
APP_WM_DESC[idx]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[idx]="ON"
XFCE_4_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
    ${LINUX_PKG_MGR} install -y xfce4
  ;;
  *)
    return 1
  ;;
  esac
  return 0
}
(( idx++ ))

