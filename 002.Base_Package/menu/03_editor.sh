#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=':EDITOR'
APP_EDITOR_CAT="Text Editor"
APP_EDITOR_EX="A set of text editor"
# END WM INFO

idx=0

APP_EDITOR_NAME[idx]="vim"
APP_EDITOR_DESC[idx]="vi iMproved is a screen-oriented text editor originally"
APP_EDITOR_STAT[idx]="OFF"
vim_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y vim
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))

APP_EDITOR_NAME[idx]="emacs"
APP_EDITOR_DESC[idx]="A screen-based editor with an embedded computer language"
APP_EDITOR_STAT[idx]="OFF"
emacs_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y emacs
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))

APP_EDITOR_NAME[idx]="nano"
APP_EDITOR_DESC[idx]="A screen-based editor"
APP_EDITOR_STAT[idx]="OFF"
nano_routine() {
  case ${LINUX_OS} in
    debian|ubuntu)
      ${LINUX_PKG_MGR} install -y nano
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))

APP_EDITOR_NAME[idx]="TexMaker"
APP_EDITOR_DESC[idx]="LaTeX editor."
APP_EDITOR_STAT[idx]="OFF"
TexMaker_routine() {
  case ${LINUX_OS} in
    ubuntu)
      ${LINUX_PKG_MGR} install -y texmaker
      ;;
    *)
      return 1
      ;;
    esac
  return 0
}
(( idx++ ))
