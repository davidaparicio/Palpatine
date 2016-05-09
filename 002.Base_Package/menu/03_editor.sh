#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=':EDITOR'
APP_EDITOR_CAT="Text Editor"
APP_EDITOR_EX="A set of text editor"
# END WM INFO

idx=0

APP_EDITOR_NAME[idx]="vim"
APP_EDITOR_PKG[idx]="vim"
APP_EDITOR_DESC[idx]="vi iMproved is a screen-oriented text editor originally"
APP_EDITOR_STAT[idx]="OFF"
vim_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y vim
      ;;
    *)
      echo "This script does not support installation of vim on your OS"
      ;;
    esac
}
(( idx++ ))

APP_EDITOR_NAME[idx]="emacs"
APP_EDITOR_PKG[idx]="emacs"
APP_EDITOR_DESC[idx]="A screen-based editor with an embedded computer language"
APP_EDITOR_STAT[idx]="OFF"
emacs_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y emacs
      ;;
    *)
      echo "This script does not support installation of emacs on your OS"
      ;;
    esac
}
(( idx++ ))

APP_EDITOR_NAME[idx]="nano"
APP_EDITOR_PKG[idx]="nano"
APP_EDITOR_DESC[idx]="A screen-based editor"
APP_EDITOR_STAT[idx]="OFF"
nano_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y nano
      ;;
    *)
      echo "This script does not support installation of nano on your OS"
      ;;
    esac
}
(( idx++ ))

APP_EDITOR_NAME[idx]="KWrite"
APP_EDITOR_PKG[idx]="kwrite"
APP_EDITOR_DESC[idx]="KWrite is a simple text editor built on the KDE Platform."
APP_EDITOR_STAT[idx]="OFF"
KWrite_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y nano
      ;;
    *)
      echo "This script does not support installation of KWrite on your OS"
      ;;
    esac
}
(( idx++ ))

APP_EDITOR_NAME[idx]="Leafpad"
APP_EDITOR_PKG[idx]="leafpad"
APP_EDITOR_DESC[idx]="Leafpad is a simple text editor."
APP_EDITOR_STAT[idx]="OFF"
KWrite_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y leafpad
      ;;
    *)
      echo "This script does not support installation of KWrite on your OS"
      ;;
    esac
}
(( idx++ ))

APP_EDITOR_NAME[idx]="Kate"
APP_EDITOR_PKG[idx]="kate"
APP_EDITOR_DESC[idx]="Kate is a text editor built for the KDE Platform."
APP_EDITOR_STAT[idx]="OFF"
(( idx++ ))

APP_EDITOR_NAME[idx]="geany"
APP_EDITOR_PKG[idx]="geany"
APP_EDITOR_DESC[idx]="Geany is a light text editor."
APP_EDITOR_STAT[idx]="OFF"
(( idx++ ))

APP_EDITOR_NAME[idx]="TexMaker"
APP_EDITOR_PKG[idx]="texmaker"
APP_EDITOR_DESC[idx]="LaTeX editor."
APP_EDITOR_STAT[idx]="OFF"
(( idx++ ))
