#!/bin/bash

new_config() {
  # Get script directory, gonna need sometime to be sure to get back to the
  # right directory
  local dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local name=''
  cd ${dir}
  cp template.conf /etc/vpn-${name}.conf
}

openvpn_config() {
  menu="whiptail --title 'OpenVPN Configuration' \
    --menu 'What do you want to do ? $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT \
    'New Config'    'Install a new VPN Configuration'
    'Update Config' 'Update an existing VPN Configuration'
    'Delete Config' 'Delete an exisiting VPN Configuration'
    '<-- Back'      'Back to main menu'"
  while true
  do
    bash -c "${menu}" > results_menu.txt
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
