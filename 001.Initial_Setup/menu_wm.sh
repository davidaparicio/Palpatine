#!/bin/bash

ALL_APP_CAT+='WM'


declare -A APP_WM

APP_WM_WIDTH=4

APP_WM_NAME[0]="Xubuntu_Desktop"
APP_WM_PKG[0]="xubuntu-desktop" # TODO
APP_WM_DESC[0]="Full well known desktop manager based on xfce"
APP_WM_STAT[0]="OFF"

Xubuntu_Desktop_routine () {
  # TODO Parse ALL_PKG_CHOOSEN to be sure it does not belong to it
  echo
}

APP_WM_NAME[1]="Ubuntu-Desktop"
APP_WM_PKG[1]="ubuntu-desktop" # TODO
APP_WM_DESC[1]="Full well known desktop manager based on unity"
APP_WM_STAT[1]="OFF"

APP_WM_NAME[2]="Kubuntu-Desktop"
APP_WM_PKG[2]="kubuntu-desktop" # TODO
APP_WM_DESC[2]="Full well known desktop manager based on KDE"
APP_WM_STAT[2]="OFF"

APP_WM_NAME[3]="Awesome_3.4"
APP_WM_PKG[3]="awesome" 
APP_WM_DESC[3]="A light and very customable WM 3.5"
APP_WM_STAT[3]="OFF"

APP_WM_NAME[4]="Awesome_3.5"
APP_WM_PKG[4]="awesome"
APP_WM_DESC[4]="A light and very customable WM v3.5"
APP_WM_STAT[4]="OFF"

APP_WM_NAME[5]="KDE"
APP_WM_PKG[5]="kde" # TODO
APP_WM_DESC[5]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[5]="OFF"

APP_WM_NAME[6]="LXQt"
APP_WM_PKG[6]="lxqt" # TODO
APP_WM_DESC[6]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[6]="OFF"

APP_WM_NAME[7]="Gnome"
APP_WM_PKG[7]="gnome" # TODO
APP_WM_DESC[7]="Full desktop environnement, graphical, easy to use."
APP_WM_STAT[7]="OFF"

APP_WM_NAME[8]="Mate"
APP_WM_PKG[8]="mate" # TODO
APP_WM_DESC[8]="Full desktop environnement, graphical, easy to use. Fork from Gnome"
APP_WM_STAT[8]="OFF"

APP_WM_NAME[9]="XFCE_4"
APP_WM_PKG[9]="xfce4" # TODO
APP_WM_DESC[9]="Ligthweight desktop environnement, modular, portable"
APP_WM_STAT[9]="OFF"

#add_repo_awesome3.5() {
    # Usage  : add_repo_awesome3.5
    # Input  : None
    # Output : None
    # Brief  : Add ppa for awesome 3.5 on ubuntu 14.04
 #   verbose ${FUNCNAME}
#    echo "Add ppa for awesome-3.5"
  #  ask_continue ${FUNCNAME}
   # if [[ $yn == [Yy] ]]
    #then
#        sudo add-apt-repository ppa:klaus-voWMweg/awesome
 #       sudo apt-get update
  #  else 
   #     AWESOME_WM=false
    #fi
#}
# End of add_repo_awesome3.5