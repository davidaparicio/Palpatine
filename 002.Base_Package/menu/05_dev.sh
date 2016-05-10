#!/bin/bash

# BEGIN DEV INFO
ALL_APP_CAT+=':DEV'
APP_DEV_CAT="Developpement tools"
APP_DEV_EX="Developpement tools"
# END DEV INFO

idx=0

APP_DEV_NAME[idx]="QtCreator"
APP_DEV_DESC[idx]="Qt Creator is a cross-platform C++, JavaScript and QML IDE"
APP_DEV_STAT[idx]="OFF"
QtCreator_routine() {
  case ${LINUX_OS} in
    ubuntu)
      ${LINUX_PKG_MGR} install -y qtcreator
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))
