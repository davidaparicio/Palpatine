#!/bin/bash

# BEGIN MEDIA INFO
ALL_APP_CAT+=':MEDIA'
APP_MEDIA_CAT="Media Application"
APP_MEDIA_EX="Media Application"
# END MEDIA INFO

idx=0

APP_MEDIA_NAME[idx]="VLC"
APP_MEDIA_DESC[idx]="Media Player"
APP_MEDIA_STAT[idx]="ON"
VLC_routine() {
  case ${LINUX_OS} in
    debian|ubunt)
      ${LINUX_PKG_MGR} install -y vlc
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))
