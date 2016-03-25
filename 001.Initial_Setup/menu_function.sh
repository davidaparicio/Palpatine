#!/bin/bash

source global.sh

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
  
  source menu/*${LOWER_NAME}.sh
  
  local ARR_NAME="APP_${NAME}_NAME[@]"
  local ARR_PKG="APP_${NAME}_PKG[@]"
  local ARR_DESC="APP_${NAME}_DESC[@]"
  local ARR_STAT="APP_${NAME}_STAT[@]"
  local CAT_NAME="APP_${NAME}_CAT"
  
  local APP_ARR_NAME=("${!ARR_NAME}")
  local APP_ARR_PKG=("${!ARR_PKG}")
  local APP_ARR_DESC=("${!ARR_DESC}")
  local APP_ARR_STAT=("${!ARR_STAT}")
  CAT_NAME=("${!CAT_NAME}")

  local NB_APP=${#APP_ARR_NAME[@]}

  calc_wt_size
  
  local MENU_APP="whiptail --title '${CAT_NAME}' --checklist  'Select which ${CAT_NAME} you want to install :' \
  $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    MENU_APP="${MENU_APP} '${APP_ARR_NAME[${idx}]}' '${APP_ARR_DESC[${idx}]}' '${APP_ARR_STAT[${idx}]}'"
  done

  bash -c "${MENU_APP}" 2> results_menu.txt
  RET=$?
  if [[ ${RET} == 1 ]]
  then
    return 1
  fi

  CHOICE=$( cat results_menu.txt )
  
  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    if echo ${CHOICE} | grep -q "\"${APP_ARR_NAME[${idx}]}\""
    then  
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"ON\"/g' menu/${LOWER_NAME}.sh"
      eval ${CMD}
    else
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"OFF\"/g' menu/${LOWER_NAME}.sh"
      eval ${CMD}
    fi
  done
  return 0
}


all_categorie_menu () {
  ALL_APP_CAT=""
    
  echo '#!/bin/bash  \n\n' > menu_categories.sh
  for i in menu/*.sh
  do
    BEGIN=$( grep -in "# BEGIN " ${i} | cut -d ':' -f1 )
    END=$( grep -in "# END " ${i} | cut -d ':' -f1 )
    sed -n "${BEGIN},${END}p" ${i} >> menu_categories.sh
  done
  source menu_categories.sh
  
  local ALL_CAT
  local NB_CAT
  local CAT_NAME
  local CAT_DESC

  IFS=':' read -r -a ALL_CAT <<< "${ALL_APP_CAT}"
  NB_CAT=$(( ${#ALL_CAT[@]} - 1 ))

  calc_wt_size
  
  local MENU_CAT="whiptail --title 'Category of application' --menu  'Select which category of application you want to install :' \
  $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=1 ; idx <= ${NB_CAT} ; idx++ ))
  do
    CAT_NAME="APP_${ALL_CAT[${idx}]}_CAT"
    CAT_DESC="APP_${ALL_CAT[${idx}]}_EX"
    MENU_CAT="${MENU_CAT} '${!CAT_NAME}' '${!CAT_DESC}'"
  done

  bash -c "${MENU_CAT}" 2> results_menu.txt
  RET=$?
  if [[ ${RET} == 1 ]]
  then 
    return 1
  fi

  CHOICE=$( cat results_menu.txt )
  
  for (( idx=0 ; idx <= ${NB_CAT} ; idx++ ))
  do
    CAT_NAME="APP_${ALL_CAT[${idx}]}_CAT"
    if [[ ${!CAT_NAME} == ${CHOICE} ]]
    then
        do_menu ${ALL_CAT[${idx}]}
    fi
  done
  return 0
}

all_categorie_menu_loop () {
  while true
  do
    all_categorie_menu
    RET=$?
    if [[ ${RET} == 1 ]]
    then
      return 1 
    fi
  done
}

all_categorie_menu_loop