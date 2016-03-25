#!/bin/bash

ALL_PKG_CHOOSEN=""
ALL_APP_CAT=""

# FROM RASPI-CONFIG
calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]
  then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]
  then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

do_menu () {
  # USAGE = do_menu <CAT>
  # INPUT : 
  #   CAT : Category of application. Must be the same as the file menu_${CAT}.sh and APP_${CAT}.sh

  local NAME=$1
  local LOWER_NAME=`echo "${NAME}" | tr '[:upper:]' '[:lower:]'`
  local UPPER_NAME=`echo "${NAME}" | tr '[:lower:]' '[:upper:]'`
  
  source menu_${LOWER_NAME}.sh
  
  local ARR_NAME="APP_${NAME}_NAME[@]"
  local ARR_PKG="APP_${NAME}_PKG[@]"
  local ARR_DESC="APP_${NAME}_DESC[@]"
  local ARR_STAT="APP_${NAME}_STAT[@]"
  
  local APP_ARR_NAME=("${!ARR_NAME}")
  local APP_ARR_PKG=("${!ARR_PKG}")
  local APP_ARR_DESC=("${!ARR_DESC}")
  local APP_ARR_STAT=("${!ARR_STAT}")

  local NB_APP=$(( ${#APP_ARR_NAME[@]} ))

  calc_wt_size
  
  local MENU_APP="whiptail --title 'Window Manager' --checklist  'Which window manager to install :' \
  $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    MENU_APP="${MENU_APP} '${APP_ARR_NAME[${idx}]}' '${APP_ARR_DESC[${idx}]}' '${APP_ARR_STAT[${idx}]}'"
  done

  bash -c "${MENU_APP}" 2> results_menu.txt

  CHOICE=$( cat results_menu.txt )
  
  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    if echo ${CHOICE} | grep -q "\"${APP_ARR_NAME[${idx}]}\""
    then  
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"ON\"/g' menu_${LOWER_NAME}.sh"
      eval ${CMD}
    else
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"OFF\"/g' menu_${LOWER_NAME}.sh"
      eval ${CMD}
    fi
  done

  rm results_menu.txt
}

do_menu "WM"

do_menu "WM"
do_menu "WM"