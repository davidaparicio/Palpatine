#!/bin/bash

# BEGIN DM INFO
ALL_APP_CAT+=":DM"
APP_DM_CAT="Desktop Manager"
APP_DM_EX="A set of desktop manager"
# END DM INFO

idx=0
APP_DM_NAME[idx]="LightDM"
APP_DM_DESC[idx]="A light and very customable DM"
APP_DM_STAT[idx]="OFF"
LightDM_routine () {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y lightdm
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))

APP_DM_NAME[idx]="GnomeDM"
APP_DM_DESC[idx]="A light and very customable DM"
APP_DM_STAT[idx]="ON"
GnomeDM_routine() {
  case ${LINUX_OS} in
  ubuntu|debian)
    ${LINUX_PKG_MGR} install -y gdm
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))
