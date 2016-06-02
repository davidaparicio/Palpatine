#!/bin/bash

set_conf_name() {
  conf_name="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter a name for your configuration' \
    ${WT_HEIGHT} ${WT_WIDTH} illyse"
  bash -c "${conf_name}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  conf_name=$( cat results_menu.txt )
}

set_server_address(){
  server_address="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the url address of your vpn' \
    ${WT_HEIGHT} ${WT_WIDTH} vpn.illyse.net"
  bash -c "${server_address}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_address=$( cat results_menu.txt )
}

set_server_port() {
  server_port="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the port to access to your vpn' \
    ${WT_HEIGHT} ${WT_WIDTH} 1194"
  bash -c "${server_port}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_port=$( cat results_menu.txt )
}

set_server_proto() {
  server_proto="whiptail --title 'OpenVPN Configuration' \
    --menu 'Select communication protocol to use' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'UDP' '' \
    'TCP' ''"
  bash -c "${server_proto}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_proto=$( cat results_menu.txt )
}

set_login() {
  user_login="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the username to use to connect to your VPN :' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_login}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_login=$( cat results_menu.txt )

  user_pass="whiptail --title 'OpenVPN Configuration' \
    --passwordbox 'Please enter the password to use to connect to your VPN :' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_pass}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_pass=$( cat results_menu.txt )
}

set_out_method() {
  out="whiptail --title 'OpenVPN configuration' \
    --menu 'choose the way you want to output connexion' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Default' ': If input from isp, out from isp. if input from vpn, out from vpn'\
    'Out VPN' ': Whatever input is, output will be from vpn address'\
    'Out ISP' ': Whatever input is, output will be from isp address'"
  echo ${out}
  bash -c "${out}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  case ${CHOICE} in
    'Default')
      is_out_vpn=false
      is_out_isp=false
      ;;
    'Out VPN')
      is_out_vpn=true
      is_out_isp=false
      ;;
    'Out ISP')
      is_out_vpn=false
      is_out_isp=true
      ;;
    * )
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
      return 1
      ;;
  esac
  return 0
}

set_server_cert_url() {
  server_cert_url="whiptail --title 'OpenVPN configuration' \
    --inputbox 'Please enter the URL to download to get server certificate' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${server_cert_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_cert_url=$( cat results_menu.txt )
}

valid_config() {
   if ( whiptail --title 'OpenVPN Configuration' \
    --yesno "Here is your VPN configuration :
    Configration Name : ${conf_name}
    Server   : ${server_address}:${server_port}
    Protocol : ${server_proto}
    Login    : ${user_login}
    Password : The one you set
    Server Certificate URL : ${server_cert_url}" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    apply_config
    RET=$?; [[ ${RET} -eq 1 ]] && return 1
    return 0
  else
    return 1
  fi
}

apply_config() {
  cp $dir/template.conf /etc/openvpn/conf-${conf_name}.conf
  sed -i  -e "s/<TPL:CONF_NAME>/${conf_name}/g" \
      -e "s/<TPL:SERVER_NAME>/${server_name}/g" \
      -e "s/<TPL:SERVER_PORT>/${server_port}/g" \
      -e "s/<TPL:SERVER_PROTO>/${server_proto}/g" /etc/openvpn/conf-${conf_name}.conf
  if [[ ${is_login} == true ]]
  then
    sed -i -e "s/<TPL:LOGIN_COMMENT>//g" /etc/openvpn/conf-${conf_name}.conf
    mkdir -p /etc/openvpn/keys
    echo ${user_login} > /etc/openvpn/keys/credentials-${conf_name}
    echo ${user_pass} >> /etc/openvpn/keys/credentials-${conf_name}
  else
    sed -i -e "s/<TPL:LOGIN_COMMENT>/#/g" /etc/openvpn/conf-${conf_name}.conf
  fi

  if [[ ${is_udp} == true ]]
  then
    sed -i -e "s/<TPL:UDP_COMMENT>//g" /etc/openvpn/conf-${conf_name}.conf
  else
    sed -i -e "s/<TPL:UDP_COMMENT>/#/g" /etc/openvpn/conf-${conf_name}.conf
  fi
}

new_config() {
  # Get script directory, gonna need sometime to be sure to get back to the
  # right directory
  local server_address
  local server_port
  local server_proto
  local is_udp
  local is_out_vpn
  local is_out_isp
  local is_login
  local conf_name
  local user_login
  local user_pass
  local server_cert_url

  set_conf_name
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_address
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_port
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_proto
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  [[ ${server_proto} == UDP ]] && is_udp=true || is_udp=false

  if ( whiptail --title 'OpenVPN Configuration' \
    --yesno 'Does your VPN require login information (i.e. login and password) ?'\
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    is_login=true
    set_login
    RET=$?; [[ ${RET} -eq 1 ]] && return 1
  else
    is_login=false
  fi

  set_out_method
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_cert_url
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  valid_config
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
}

openvpn_config() {
  local dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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
    read

    bash -c "${menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )
    case ${CHOICE} in
      '<-- Back' )
        return 1
        ;;
      'New Config')
        new_config
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
