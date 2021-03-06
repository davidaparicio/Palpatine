#!/bin/bash

# BEGIN FM INFO
ALL_APP_CAT+=':FM'
APP_FM_CAT="File Manager"
APP_FM_EX="File Manager"
# END FM INFO

idx=0

APP_FM_NAME[idx]="PcmanFM"
APP_FM_DESC[idx]="Lightweight and fast file manager"
APP_FM_STAT[idx]="ON"
PcmanFM_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y pcmanfm
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))
