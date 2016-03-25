#!/bin/bash

source setup_pkg_menu.sh

declare -A APP_WM

APP_WM_WIDTH=4

APP_WM[1,1]="Xubuntu_Desktop"
APP_WM[1,2]="xubuntu-desktop" # TODO
APP_WM[1,3]="Full well known desktop manager based on xfce"
APP_WM[1,4]="OFF"

Xubuntu_Desktop_routine () {
  # TODO Parse ALL_PKG_CHOOSEN to be sure it does not belong to it
  APP_WM[1,4]="ON"
  ALL_PKG_CHOOSEN+="${#APP_WM[@]} " 
}

APP_WM[2,1]="Ubuntu-Desktop"
APP_WM[2,2]="ubuntu-desktop" # TODO
APP_WM[2,3]="Full well known desktop manager based on unity"
APP_WM[2,4]="OFF"

APP_WM[3,1]="Kubuntu-Desktop"
APP_WM[3,2]="kubuntu-desktop" # TODO
APP_WM[3,3]="Full well known desktop manager based on KDE"
APP_WM[3,4]="OFF"

APP_WM[4,1]="Awesome_3.4"
APP_WM[4,2]="awesome" 
APP_WM[4,3]="A light and very customable WM 3.5"
APP_WM[4,4]="OFF"

APP_WM[5,1]="Awesome_3.5"
APP_WM[5,2]="awesome"
APP_WM[5,3]="A light and very customable WM v3.5"
APP_WM[5,4]="OFF"

APP_WM[6,1]="KDE"
APP_WM[6,2]="kde" # TODO
APP_WM[6,3]="Full desktop environnement, graphical, easy to use."
APP_WM[6,4]="OFF"

APP_WM[7,1]="LXQt"
APP_WM[7,2]="lxqt" # TODO
APP_WM[7,3]="Ligthweight desktop environnement, modular, portable"
APP_WM[7,4]="OFF"

APP_WM[8,1]="Gnome"
APP_WM[8,2]="gnome" # TODO
APP_WM[8,3]="Full desktop environnement, graphical, easy to use."
APP_WM[8,4]="OFF"

APP_WM[9,1]="Mate"
APP_WM[9,2]="mate" # TODO
APP_WM[9,3]="Full desktop environnement, graphical, easy to use. Fork from Gnome"
APP_WM[9,4]="OFF"

APP_WM[10,1]="XFCE_4"
APP_WM[10,2]="xfce4" # TODO
APP_WM[10,3]="Ligthweight desktop environnement, modular, portable"
APP_WM[10,4]="OFF"

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

install_base_pkg() {
    # Usage  : install_base_pkg
    # Input  : None
    # Output : None
    # Brief  : Instal minimal usefull soft
    verbose ${FUNCNAME}
    sudo apt-get install \
        apt-transport-https
    if $AWESOME_WM
    then
        sudo apt-get install \
          vim \
          git \
          mr \
          vcsh \
          zsh \
          keychain \
          xclip \
          awesome \
          awesome-extra \
          teWMinator \
	  tree
    else
        sudo apt-get install \
          vim \
          git \
          mr \
          vcsh \
          zsh \
          keychain \
          xclip \
          teWMinator \
	      tree
    fi
}
# End of install_base_pkg


wm_menu () {
  # wm_menu
  local NAME=$1
  local APP_ARR="APP_${NAME}"
  echo ${APP_ARR}
  APP_ARR=${APP_ARR}
  echo ${APP_ARR}
  local NB_APP=$(( ${#APP_ARR[@]} / 4 ))
  echo ${NB_APP}
  
  calc_wt_size
  
  local NB_WM=$(( ${#APP_WM[@]} / 4 ))

  local MENU_WM="whiptail --title 'Window Manager' --checklist  'Which window manager to install :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=1 ; idx <= ${NB_WM} ; idx++ ))
  do
    MENU_WM="${MENU_WM} '${APP_WM[${idx},1]}' '${APP_WM[${idx},3]}' '${APP_WM[${idx},4]}'"
  done

  local CMD=''

  eval "${MENU_WM}" 2> 'results_wm.txt'
  
  for CHOICE in $( cat results_wm.txt )
  do
    if [[ "${APP_WM[@]}" =~ "${CHOICE}" ]]
    then 
      return -1 
    fi
    idx=0
    FOUND=false
    while ! ${FOUND} 
    do
      if [[ "\"${APP_WM[${idx},1]}\"" == "${CHOICE}" ]]
        then  
          APP_WM[${idx},4]="ON"
          CMD="${APP_WM[${idx},1]}_routine"
          ${CMD}
          FOUND=true
      fi
      idx=$(( idx + 1 ))
      if [[ ${idx} == $(( ${#APP_WM[@]} / $APP_WM_WIDTH + $APP_WM_WIDTH  )) ]]
      then
        return -1 
      fi
    done
  done
}

wm_menu "WM"
