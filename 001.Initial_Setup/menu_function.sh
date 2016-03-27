#!/bin/bash

do_menu () {
  # USAGE = do_menu <CAT>
  # INPUT :
  #   CAT : Category of application. Must be the same as the file menu_${CAT}.sh and APP_${CAT}.sh

  local NAME=$1
  local LOWER_NAME=`echo "${NAME}" | tr '[:upper:]' '[:lower:]'`
  local UPPER_NAME=`echo "${NAME}" | tr '[:lower:]' '[:upper:]'`

  source 001.Initial_Setup/menu/*${LOWER_NAME}.sh

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
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi

  CHOICE=$( cat results_menu.txt )

  for (( idx=0 ; idx <= ${NB_APP}-1 ; idx++ ))
  do
    if echo ${CHOICE} | grep -q "\"${APP_ARR_NAME[${idx}]}\""
    then
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"ON\"/g' 001.Initial_Setup/menu/*${LOWER_NAME}.sh"
      eval ${CMD}
    else
      CMD="sed -i 's/STAT\[${idx}\]=\"\(OFF\|ON\)\"/STAT\[${idx}\]=\"OFF\"/g' 001.Initial_Setup/menu/*${LOWER_NAME}.sh"
      eval ${CMD}
    fi
  done
  return 0
}


all_categorie_menu () {
  ALL_APP_CAT=""
  echo '#!/bin/bash  \n\n' > 001.Initial_Setup/menu_categories.sh
  for i in 001.Initial_Setup/menu/*.sh
  do
    BEGIN=$( grep -in "# BEGIN " ${i} | cut -d ':' -f1 )
    END=$( grep -in "# END " ${i} | cut -d ':' -f1 )
    sed -n "${BEGIN},${END}p" ${i} >> 001.Initial_Setup/menu_categories.sh
  done
  source 001.Initial_Setup/menu_categories.sh

  local ALL_CAT
  local NB_CAT
  local CAT_NAME
  local CAT_DESC

  IFS=':' read -r -a ALL_CAT <<< "${ALL_APP_CAT}"
  NB_CAT=$(( ${#ALL_CAT[@]} - 1 ))

  local MENU_CAT="whiptail --title 'Category of application' --menu  'Select which category of application you want to install :' \
  $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT"
  for (( idx=1 ; idx <= ${NB_CAT} ; idx++ ))
  do
    CAT_NAME="APP_${ALL_CAT[${idx}]}_CAT"
    CAT_DESC="APP_${ALL_CAT[${idx}]}_EX"
    MENU_CAT="${MENU_CAT} '${!CAT_NAME}' '${!CAT_DESC}'"
  done
  MENU_CAT="${MENU_CAT} 'CONTINUE' 'Continue to the next step'"

  bash -c "${MENU_CAT}" 2> results_menu.txt
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    return 1
  fi

  CHOICE=$( cat results_menu.txt )

  if [[ ${CHOICE} == "CONTINUE" ]]
  then
    do_finish
  fi

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

do_finish () {
  ALL_APP_CAT=""
  echo '#!/bin/bash  ' > 001.Initial_Setup/menu_categories.sh
  for i in 001.Initial_Setup/menu/*.sh
  do
    BEGIN=$( grep -in "# BEGIN " ${i} | cut -d ':' -f1 )
    END=$( grep -in "# END " ${i} | cut -d ':' -f1 )
    sed -n "${BEGIN},${END}p" ${i} >> 001.Initial_Setup/menu_categories.sh
  done
  source 001.Initial_Setup/menu_categories.sh

  calc_wt_size

  local HEIGHT=3
  local ALL_CAT
  local NB_CAT
  local CAT_NAME

  local ALL_PKG_CHOOSEN=""
  local ALL_REPO_ADD=""


  IFS=':' read -r -a ALL_CAT <<< "${ALL_APP_CAT}"
  NB_CAT=$(( ${#ALL_CAT[@]} - 1 ))

  MENU_ASK_FINISH="whiptail --title 'Last Check Before Install' --yesno  'This is the list of program this script will install : "
  for (( idxCat=1 ; idxCat <= ${NB_CAT} ; idxCat++ ))
  do
    local CAT_DONE=false
    local NAME=${ALL_CAT[${idxCat}]}
    local LOWER_NAME=`echo "${NAME}" | tr '[:upper:]' '[:lower:]'`
    local UPPER_NAME=`echo "${NAME}" | tr '[:lower:]' '[:upper:]'`

    source 001.Initial_Setup/menu/*${LOWER_NAME}.sh

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

    for (( idx=0 ; idx <= ${NB_APP} ; idx++ ))
    do
      if [[ ${APP_ARR_STAT[${idx}]} == "ON" ]]
      then
        if ! ${CAT_DONE}
        then
            MENU_ASK_FINISH="${MENU_ASK_FINISH}  \n ==== Category : ${CAT_NAME} ===="
            CAT_DONE=true
            HEIGHT=$(( HEIGHT + 1 ))
        fi
        MENU_ASK_FINISH="${MENU_ASK_FINISH} \n= ${APP_ARR_NAME[${idx}]} : ${APP_ARR_DESC[${idx}]}"
        HEIGHT=$(( HEIGHT + 1 ))

        if type -t ${APP_ARR_NAME[${idx}]}_routine &>/dev/null
        then
          ${APP_ARR_NAME[${idx}]}_routine
        fi
        ALL_PKG_CHOOSEN+=" ${APP_ARR_PKG[${idx}]}"

      fi
    done
    CAT_DONE=false
    MENU_ASK_FINISH="${MENU_ASK_FINISH} \n "
    HEIGHT=$(( HEIGHT + 2 ))
  done
  MENU_ASK_FINISH="${MENU_ASK_FINISH}' $HEIGHT $WT_WIDTH "
  bash -c "${MENU_ASK_FINISH}"
  RET=$?
  if [[ ${RET} -eq 0 ]]
  then
    for i in ${ALL_REPO_ADD}
    do
      add-apt-repository -y $i
    done
    apt-get update && apt-get upgrade -y && apt-get install -y ${ALL_PKG_CHOOSEN}
  elif [[ ${RET} -eq 1 ]]
  then
    return 1
  fi
}

all_categorie_menu_loop () {
  while true
  do
    all_categorie_menu
    RET=$?
    if [[ ${RET} -eq 1 ]]
    then
      return 1
    elif [[ ${RET} -eq 2 ]]
    then
      return 2
    fi
  done
}

setup_ask_categories () {
  all_categorie_menu_loop
  return 2
}

setup_ask_go_through () {
  ALL_APP_CAT=""
  echo '#!/bin/bash  \n\n' > 001.Initial_Setup/menu_categories.sh
  for i in 001.Initial_Setup/menu/*.sh
  do
    BEGIN=$( grep -in "# BEGIN " ${i} | cut -d ':' -f1 )
    END=$( grep -in "# END " ${i} | cut -d ':' -f1 )
    sed -n "${BEGIN},${END}p" ${i} >> 001.Initial_Setup/menu_categories.sh
  done
  source 001.Initial_Setup/menu_categories.sh

  local ALL_CAT
  local NB_CAT
  local CAT_NAME

  IFS=':' read -r -a ALL_CAT <<< "${ALL_APP_CAT}"
  NB_CAT=$(( ${#ALL_CAT[@]} - 1 ))

  echo "#!/bin/bash" > 001.Initial_Setup/setup_go_through.sh
  echo  >> 001.Initial_Setup/setup_go_through.sh
  echo "source 001.Initial_Setup/menu_function.sh" >> 001.Initial_Setup/setup_go_through.sh
  echo  >> 001.Initial_Setup/setup_go_through.sh
  echo "go_through() { " >> 001.Initial_Setup/setup_go_through.sh
  for (( idx=1 ; idx <= ${NB_CAT} ; idx++ ))
  do
    echo do_menu ${ALL_CAT[${idx}]} >> 001.Initial_Setup/setup_go_through.sh
    echo "RET=\$? " >> 001.Initial_Setup/setup_go_through.sh
    echo "if [[ \${RET} == 1 ]] " >> 001.Initial_Setup/setup_go_through.sh
    echo "then " >> 001.Initial_Setup/setup_go_through.sh
    echo "return 1" >> 001.Initial_Setup/setup_go_through.sh
    echo "fi " >> 001.Initial_Setup/setup_go_through.sh
  done
  echo "} " >> 001.Initial_Setup/setup_go_through.sh
  echo "go_through" >> 001.Initial_Setup/setup_go_through.sh

  chmod 755 001.Initial_Setup/setup_go_through.sh
  ./001.Initial_Setup/setup_go_through.sh
  RET=$?
  if [[ ${RET} -eq 1 ]]
  then
    all_categorie_menu_loop
    RET=$?
    rm 001.Initial_Setup/setup_go_through.sh
    return ${RET}
  fi
  rm 001.Initial_Setup/setup_go_through.sh
  do_finish
}

setup_direct_finish () {
  do_finish
  RET=$?
  if [[ ${RET} -eq 2 ]]
  then
    return 2
  elif [[ ${RET} -eq 1 ]]; then
    all_categorie_menu_loop
    return 2
  fi
}
