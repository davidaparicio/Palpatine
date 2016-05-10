#!/bin/bash

# BEGIN GRAPH INFO
ALL_APP_CAT+=':GRAPH'
APP_GRAPH_CAT="Graphics"
APP_GRAPH_EX="Graphics editing tools"
# END GRAPH INFO

idx=0

APP_GRAPH_NAME[idx]="GIMP"
APP_GRAPH_DESC[idx]="Create images and edit photographs"
APP_GRAPH_STAT[idx]="OFF"
GIMP_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y gimp
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))
