#!/bin/bash

# BEGIN WM INFO
ALL_APP_CAT+=":WM"
APP_WM_CAT="Window Manager"
APP_WM_EX="A set of window manager"
# END WM INFO

APP_WM_NAME[0]="Xubuntu_Desktop"
APP_WM_PKG[0]="xubuntu-desktop"
APP_WM_DESC[0]="Full well known desktop manager based on xfce"
APP_WM_STAT[0]="ON"

APP_WM_NAME[1]="Ubuntu-Desktop"
APP_WM_PKG[1]="ubuntu-desktop"
APP_WM_DESC[1]="Full well known desktop manager based on unity"
APP_WM_STAT[1]="OFF"

APP_WM_NAME[2]="Kubuntu-Desktop"
APP_WM_PKG[2]="kubuntu-desktop"
APP_WM_DESC[2]="Full well known desktop manager based on KDE"
APP_WM_STAT[2]="OFF"

APP_WM_NAME[3]="Lubuntu-Desktop"
APP_WM_PKG[3]="lubuntu-desktop"
APP_WM_DESC[3]="Full well known desktop manager based on LXQt"
APP_WM_STAT[3]="OFF"

APP_WM_NAME[4]="Awesome_3.4"
APP_WM_PKG[4]="awesome awesome-extra"
APP_WM_DESC[4]="A light and very customable WM 3.5"
APP_WM_STAT[4]="OFF"

APP_WM_NAME[5]="Awesome_3.5"
APP_WM_PKG[5]="awesome awesome-extra"
APP_WM_DESC[5]="A light and very customable WM v3.5"
APP_WM_STAT[5]="OFF"
Awesome_3.5_routine () {
	ALL_REPO_ADD+=" ppa:klaus-vormweg/awesome"
}

APP_WM_NAME[6]="KDE"
APP_WM_PKG[6]="kde-full"
APP_WM_DESC[6]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[6]="OFF"

APP_WM_NAME[7]="LXQt"
APP_WM_PKG[7]="lxqt-metapackage lxqt-panel openbox"
APP_WM_DESC[7]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[7]="OFF"
LXQt_routine () {
	ALL_REPO_ADD+=" ppa:lubuntu-dev/lubuntu-daily"
}

APP_WM_NAME[8]="Gnome"
APP_WM_PKG[8]="ubuntu-gnome-desktop"
APP_WM_DESC[8]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[8]="OFF"

APP_WM_NAME[9]="Mate"
APP_WM_PKG[9]="ubuntu-mate-core ubuntu-mate-desktop"
APP_WM_DESC[9]="Full desktop environnement, graphical, easy to use. Fork from Gnome"
APP_WM_STAT[9]="OFF"
Mate_routine () {
	ALL_REPO_ADD+=" ppa:ubuntu-mate-dev/ppa"
	ALL_REPO_ADD+=" ppa:ubuntu-mate-dev/trusty-mate"
}

APP_WM_NAME[10]="XFCE_4"
APP_WM_PKG[10]="xfce4"
APP_WM_DESC[10]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[10]="OFF"

APP_WM_NAME[11]="Cinnamon"
APP_WM_PKG[11]="cinnamon"
APP_WM_DESC[11]="Full desktop environnement, graphical, easy to use. Fork from Gnome"
APP_WM_STAT[11]="OFF"
Cinnamon_routine () {
	ALL_REPO_ADD+=" ppa:lestcape/cinnamon"
}
