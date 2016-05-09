#!/bin/bash

##############################################################################
do_install_pkg() {
  local pkg=$1
  case ${LINUX_PKG_MGR} in
    apt* )
      ${LINUX_PKG_MGR} install -y ${pkg}
      RET=$? ; [[ ${RET} -eq 1 ]] && return 1 || return 0
    ;;
    * )
      echo "Programmer error : Option ${LINUX_PKG_MGR} not supported."
    ;;
  esac
}

setup_pkg_ask_finish () {
  local all_app_choosen
  local nb_app_choosen=0
  local all_routine
  local nb_routine=0

  menu_ask_finish="whiptail --title '002.Package : Last Check Before Install' \
    --menu  'This is the list of program this script will install :' \
    ${WT_WIDE_HEIGHT} ${WT_WIDTH} ${WT_WIDE_MENU_HEIGHT} "
  for (( idxCat=1 ; idxCat <= ${nb_cat} ; idxCat++ ))
  do
    local cat_done=false
    local cat_name=${all_cat[idxCat]}
    local lower_name=`echo "${cat_name}" | tr '[:upper:]' '[:lower:]'`
    local upper_name=`echo "${cat_name}" | tr '[:lower:]' '[:upper:]'`

    source ${dir}/menu/*${lower_name}.sh

    local arr_name="APP_${cat_name}_NAME[@]"
    local arr_desc="APP_${cat_name}_DESC[@]"
    local arr_stat="APP_${cat_name}_STAT[@]"
    local cat_desc="APP_${cat_name}_EX"
    cat_name="APP_${cat_name}_CAT"

    local app_arr_name=("${!arr_name}")
    local app_arr_desc=("${!arr_desc}")
    local app_arr_stat=("${!arr_stat}")
    cat_desc=("${!cat_desc}")
    cat_name=("${!cat_name}")

    local nb_app=${#app_arr_name[@]}
    local cat_pkg=''
    local nb_cat_pkg=0

    for (( idx=0 ; idx <= ${nb_app} ; idx++ ))
    do
      if [[ ${app_arr_stat[idx]} == "ON" ]]
      then
        if [[ ${cat_done} == false ]]
        then
          menu_ask_finish="${menu_ask_finish} '' '' '=====> ${cat_name}' '${cat_desc}'"
          cat_done=true
        fi
        app_name="${app_arr_name[idx]}"
        all_app_choosen[nb_app_choosen]=${app_name}
        (( nb_app_choosen++ ))
        app_desc="${app_arr_desc[idx]}"
        menu_ask_finish="${menu_ask_finish} '${app_name}' '${app_desc}'"

        if type -t ${app_arr_name[idx]}_routine &>/dev/null
        then
          all_routine[nb_routine]="${app_arr_name[idx]}_routine"
          (( nb_routine++ ))
        else
          echo "Programmer Error : No routine function for ${app_arr_name[idx]}"
        fi
      fi
    done
    cat_done=false
  done

  menu_ask_finish="${menu_ask_finish}  \
    ''                                ''\
    '=============================='  '===================================' \
    '<-- Back'                         'Back to list of categories' \
    'INSTALL PACKAGES'                'Launch installation of all packages'"

  while true
  do
    bash -c "${menu_ask_finish}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      '<-- Back' )
        return 1
        ;;
      'INSTALL PACKAGES' )
        NEED_UPDATE=true ; do_fullupdate
        for (( i=0; i < $nb_routine; i++ ))
        do
          pourcent=$( awk "BEGIN { print "$i"/"$nb_routine"*100 }" )
          pourcent=${pourcent%%.*}
          ${all_routine[i]} 2>&1 >> ${dir}/install_pkg.log | whiptail --gauge "INSTALLATION :
  Installation of ${all_app_choosen[i]} \n\n
  Please wait..." 10 ${WT_WIDTH} ${pourcent}
        done
        return 0
      ;;
    esac
  done
}

setup_pkg_all_app () {
  local name=$1
  local lower_name=`echo "${name}" | tr '[:upper:]' '[:lower:]'`
  local upper_name=`echo "${name}" | tr '[:lower:]' '[:upper:]'`

  source ${dir}/menu/*${lower_name}.sh

  local arr_name="APP_${name}_NAME[@]"
  local arr_pkg="APP_${name}_PKG[@]"
  local arr_desc="APP_${name}_DESC[@]"
  local arr_stat="APP_${name}_STAT[@]"
  local cat_name="APP_${name}_CAT"

  local app_arr_name=("${!arr_name}")
  local app_arr_pkg=("${!arr_pkg}")
  local app_arr_desc=("${!arr_desc}")
  local app_arr_stat=("${!arr_stat}")
  cat_name=("${!cat_name}")

  local nb_app=${#app_arr_name[@]}

  local menu_app="whiptail --title '002.Package Setup : ${cat_name}' \
    --checklist  'Select which ${cat_name} you want to install :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for (( idx=0 ; idx <= ${nb_app}-1 ; idx++ ))
  do
    menu_app="${menu_app} '${app_arr_name[idx]}' '${app_arr_desc[idx]}' '${app_arr_stat[idx]}'"
  done

  bash -c "${menu_app}" 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1

  CHOICE=$( cat results_menu.txt )
  for (( idx=0 ; idx <= ${nb_app}-1 ; idx++ ))
  do
    line=$(grep -n ${app_arr_name[idx]}_routine ${dir}/menu/*${lower_name}.sh | cut -d ":" -f1)
    (( line-- ))
    if echo ${CHOICE} | grep -q "\"${app_arr_name[idx]}\""
    then
      sed -i "${line}s/\(OFF\|ON\)/ON/g" ${dir}/menu/*${lower_name}.sh
    else
      sed -i "${line}s/\(OFF\|ON\)/OFF/g" ${dir}/menu/*${lower_name}.sh
    fi
  done
  return 0
}

setup_pkg_all_cat () {
  local cat_name
  local cat_desc

  local menu_cat="whiptail --title '002.Package Setup : Category of application' \
    --menu  'Select which category of application you want to install :' \
    ${WT_WIDE_HEIGHT} ${WT_WIDTH} ${WT_WIDE_MENU_HEIGHT}"
  for (( idx=1 ; idx <= ${nb_cat} ; idx++ ))
  do
    cat_name="APP_${all_cat[idx]}_CAT"
    cat_desc="APP_${all_cat[idx]}_EX"
    menu_cat="${menu_cat} '${!cat_name}' '${!cat_desc}'"
  done
  menu_cat="${menu_cat} \
  'INSTALL'  'Install selected packages' \
  '<-- Back' 'Return to main menu'"

  while true
  do
    bash -c "${menu_cat}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )

    case ${CHOICE} in
      'INSTALL' )
        return 0
        ;;
      '<-- Back' )
        return 1
        ;;
      * )
        for (( idxCat=0 ; idxCat <= ${nb_cat} ; idxCat++ ))
        do
          cat_name="APP_${all_cat[idxCat]}_CAT"
          [[ ${!cat_name} == ${CHOICE} ]] && setup_pkg_all_app ${all_cat[idxCat]}
        done
    esac
  done
  return 0
}

setup_pkg_go_through () {
  for (( idxCat=1 ; idxCat <= ${nb_cat} ; idxCat++ ))
  do
    setup_pkg_all_app ${all_cat[idxCat]}
    RET=$? ; [[ ${RET} -eq 1 ]] && idxCat=$(( ${nb_cat} + 1 ))
  done
  return ${RET}
}

###############################################################################
# SETUP INSTALL PACKAGE PART
###############################################################################
package_menu () {
  local pkg_ask_menu="whiptail --title '002.Package setup' \
    --menu 'Select how to manage package setup :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Go through'     'Let the script go through all categories of programm to setup.' \
    'Choose package' 'Choose the categorie of programs you want to setup.' \
    'Direct setup'   'Directly install my personnal base list of application' \
    '<-- Back'       'Return to main menu'"

  bash -c "${pkg_ask_menu}" 2> results_menu.txt
  RET=$? ; [[ $RET -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  case ${CHOICE} in
    '<-- Back' )
      return 0
      ;;
    'Go through' )
      setup_pkg_go_through
      RET=$? ; [[ ${RET} -eq 0 ]] && return 0
      setup_pkg_all_cat
      RET=$? ; [[ ${RET} -eq 0 ]] && return 0 || return 1
      ;;
    'Choose package' )
      setup_pkg_all_cat
      RET=$? ; [[ ${RET} -eq 0 ]] && return 0 || return 1
      ;;
    'Direct setup' )
      return 0
      ;;
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}. "
      return 1
      ;;
  esac
}

package_setup () {
  local ALL_APP_CAT="" # NOTE : DO NOT ERASE. NEED TO REINIT CATEGORIES LIST
  local all_cat
  local nb_cat
  local cat_name
  local dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  # Create menu categorie
  echo '#!/bin/bash' > ${dir}/menu_categories.sh
  for i in ${dir}/menu/*.sh
  do
    BEGIN=$( grep -in "# BEGIN " ${i} | cut -d ':' -f1 )
    END=$( grep -in "# END " ${i} | cut -d ':' -f1 )
    sed -n "${BEGIN},${END}p" ${i} >> ${dir}/menu_categories.sh
  done
  source ${dir}/menu_categories.sh

  IFS=':' read -r -a all_cat <<< "${ALL_APP_CAT}"
  nb_cat=$(( ${#all_cat[@]} - 1 ))

#  setup_pkg_fullupdate
#  setup_pkg_base
  package_menu
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  while true
  do
    setup_pkg_ask_finish
    RET=$? ; [[ ${RET} -eq 0 ]] && return 0
    setup_pkg_all_cat
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  done
}
