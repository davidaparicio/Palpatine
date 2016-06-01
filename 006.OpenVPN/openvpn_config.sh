#!/bin/bash

openvpn_config() {
  local menu=''
  while true
  do
    menu="whiptail --title 'OpenVPN Configuration' \
      --menu 'What do you want to do :' $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT \
      'New Config'    'Install a new VPN Configuration'"
    if ls /etc/openvpn/*.conf 1> /dev/null 2>&1
    then
      menu="${menu} \
        'Update Config' 'Update an existing VPN Configuration' \
        'Delete Config' 'Delete an exisiting VPN Configuration'"
    fi
    menu="${menu} '<-- Back'      'Back to main menu'"

    bash -c "${menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )
    case ${CHOICE} in
      '<-- Back' )
        return 1
        ;;
      'New Config')
        echo TODO New Config VPN
        ;;
      'Update Config')
        echo TODO Update Config VPN
        ;;
      'Delete Config')
        echo TODO Delete Config VPN
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}
