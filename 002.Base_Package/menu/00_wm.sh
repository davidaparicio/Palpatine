#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=":WM"
APP_WM_CAT="Window Manager"
APP_WM_EX="A set of window manager"
# END WM INFO

idx=0

APP_WM_NAME[idx]="Awesome_3.4"
APP_WM_DESC[idx]="A light and very customable WM v3.4"
APP_WM_STAT[idx]="OFF"
Awesome_3.4_routine () {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y awesome awesome-extra
    ;;
  *)
    echo "This script does not support installation of Awesome 3.4 on your OS"
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="Awesome_3.5"
APP_WM_PKG[idx]=""
APP_WM_DESC[idx]="A light and very customable WM v3.5"
APP_WM_STAT[idx]="ON"
Awesome_3.5_routine () {
  case ${LINUX_OS} in
  debian)
    install --no-install-recommends -y \
      lua5.1 xmlto luadoc libxcb-randr0-dev libxcb-xtest0-dev \
      libxcb-xinerama0-dev  libxcb-shape0-dev libxcb-keysyms1-dev \
      libxcb-icccm4-dev libx11-xcb-dev lua-lgi-dev libstartup-notification0-dev \
      libxdg-basedir-dev libxcb-image0-dev libxcb-util0-dev libgdk-pixbuf2.0-dev \
      build-essential cmake graphicsmagick-imagemagick-compat libxcb-cursor0 \
      cairo-clock gtk2-engines* libxcb-xkb1 libcairo2-dev libxcb-cursor-dev \
      libxcb-cursor-dev libxkbcommon-dev libxcb-xkb-dev liblua5.1-0 \
      liblua5.1-0-dbg lua5.1 liblua5.1-0-dev curl graphicsmagick cmake curl \
      xorg libasound2 alsa-utils alsa-oss alsa-tools-gui curl thunar wicd \
      wicd-curses terminator iceweasel xfonts-terminus
    MACHINE_TYPE=`uname -m`

    if [ "$MACHINE_TYPE" == "x86_64" ]
    then
      curl -O http://ftp.fr.debian.org/debian/pool/main/a/awesome/awesome_3.5.1-1_amd64.deb
      sudo dpkg -i awesome_*_amd64.deb
      apt-get -f install
    else
      curl -O http://lmde-mirror.gwendallebihan.net/latest/pool/main/a/awesome/awesome_3.5.1-1_i386.deb
      sudo dpkg -i awesome_3.5.1-1_i386.deb

      apt-get -f install

    fi
    ;;
  ubuntu)
    add-apt-repository -y ppa:klaus-vormweg/awesome
    ${LINUX_PKG_MGR} update && ${LINUX_PKG_MGR} install -y awesome awesome-extra
    ;;
  *)
    echo "This script does not support installation of Awesome 3.5 on your OS"
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="KDE"
APP_WM_DESC[idx]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[idx]="OFF"
KDE_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
    ${LINUX_PKG_MGR} install -y kde-full
  ;;
  *)
    echo "This script does not support installation of KDE on your OS"
  ;;
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="LXQt"
APP_WM_DESC[idx]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[idx]="OFF"
LXQt_routine () {
  case ${LINUX_OS} in
  debian)
    #TODO
    ;;
  ubuntu)
    add-apt-repository -y ppa:lubuntu-dev/lubuntu-daily
    ${LINUX_PKG_MGR} update && ${LINUX_PKG_MGR} install -y lxqt-metapackage lxqt-panel
    ;;
  *)
    echo "This script does not support installation of LXQt on your OS"
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="Gnome"
APP_WM_PKG[idx]="ubuntu-gnome-desktop"
APP_WM_DESC[idx]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[idx]="OFF"
Gnome_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
    ${LINUX_PKG_MGR} install -y gnome
  ;;
  *)
    echo "This script does not support installation of Gnome on your OS"
  ;;
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="Mate"
APP_WM_DESC[idx]="Full desktop environnement, graphical, easy to use. Fork from Gnome"
APP_WM_STAT[idx]="OFF"
Mate_routine () {
  case ${LINUX_OS} in
  debian)
    #TODO
  ;;
  ubuntu)
    add-apt-repository -y ppa:ubuntu-mate-dev/ppa
    add-apt-repository -y ppa:ubuntu-mate-dev/trusty-mate
    ${LINUX_PKG_MGR} install -y ubuntu-mate-core ubuntu-mate-desktop
  ;;
  *)
    echo "This script does not support installation of Mate on your OS"
  ;;
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="XFCE_4"
APP_WM_DESC[idx]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[idx]="OFF"
XFCE_4_routine() {
  case ${LINUX_OS} in
  debian|ubuntu)
    ${LINUX_PKG_MGR} install -y xfce4
  ;;
  *)
    echo "This script does not support installation of xfce4 on your OS"
  ;;
  esac
}
(( idx++ ))

APP_WM_NAME[idx]="Cinnamon"
APP_WM_DESC[idx]="Full desktop environnement, graphical, easy to use. Fork from Gnome"
APP_WM_STAT[idx]="OFF"
Cinnamon_routine () {
  case ${LINUX_OS} in
  debian)
    #TODO
    ;;
  ubuntu)
    add-apt-repository -y ppa:lestcape/cinnamon && ${LINUX_PKG_MGR} update
    ${LINUX_PKG_MGR} install -y cinnamon
  ;;
  *)
    echo "This script does not support installation of xfce4 on your OS"
  ;;
  esac
}
(( idx++ ))
