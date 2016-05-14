#!/bin/bash

# BEGIN WWW INFO
ALL_APP_CAT+=':WWW'
APP_WWW_CAT="Internet"
APP_WWW_EX="Set of internet related apps"
# END WWW INFO

idx=0

APP_WWW_NAME[idx]="Firefox"
APP_WWW_DESC[idx]="Well known internet browers"
APP_WWW_STAT[idx]="ON"
Firefox_routine() {
  case ${LINUX_OS} in
    debian)
      ${LINUX_PKG_MGR} install -y iceweasel
      ;;
    ubuntu)
      ${LINUX_PKG_MGR} install -y firefox
      ;;
    *)
      return 1;
  esac
  return 0
}
(( idx++ ))

APP_WWW_PKG[idx]="Deluge"
APP_WWW_DESC[idx]="BitTorrent client"
APP_WWW_STAT[idx]="ON"
Deluge_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y deluge
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))

APP_WWW_PKG[idx]="Tunderbird"
APP_WWW_DESC[idx]="GUI mail client"
APP_WWW_STAT[idx]="ON"
Thunderbird_routine() {
  case ${LINUX_OS} in
    debian)
      ${LINUX_PKG_MGR} install -y icedove
      ;;
    ubuntu)
      ${LINUX_PKG_MGR} install -y thunderbird
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))
