#!/bin/bash

# BEGIN OFFICE INFO
ALL_APP_CAT+=':OFFICE'
APP_OFFICE_CAT="Office"
APP_OFFICE_EX="Office Application"
# END OFFICE INFO

idx=0

APP_OFFICE_NAME[idx]="LibreOffice"
APP_OFFICE_DESC[idx]="Open source Office suite"
APP_OFFICE_STAT[idx]="OFF"
LibreOffice_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y LibreOffice
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))

APP_OFFICE_NAME[idx]="TexLive_Full"
APP_OFFICE_DESC[idx]="The complete suite of LaTex"
APP_OFFICE_STAT[idx]="OFF"
TexLive_Full_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y texlive-full
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))

