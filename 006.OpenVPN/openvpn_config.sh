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
  out="whiptail --title 'OpenVPN Configuration' \
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
  server_cert_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download server certificate or if \
you have already copy it on the system, you can enter it's absolute path like \
/home/user/path/to/server.crt' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${server_cert_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_cert_url=$( cat results_menu.txt )
}

set_user_cert() {
  user_cert_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download client certificate or if \
you have already copy it on the system, you can enter it's absolute path like \
/home/user/path/to/client.crt' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_cert_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_cert_url=$( cat results_menu.txt )

  user_key_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download client key or if \
you have already copy it on the system, you can enter it's absolute path like \
/home/user/path/to/client.key' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_key_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_key_url=$( cat results_menu.txt )
}

set_shared_secret() {
  user_shared_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download shared key or if \
you have already copy it on the system, you can enter it's absolute path like \
/home/user/path/to/shared.key' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_shared_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_shared_url=$( cat results_menu.txt )
}

select_auth_type() {
  menu="whiptail --title 'OpenVPN Configuration' \
    --menu 'Select authentication method to you VPN provider' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Login'         'Require login and password' \
    'Certificate'   'Require user certificate and key' \
    'Shared-Secret' 'Require shared secret key' \
    'NONE'          'No authentication required'"
  bash -c "${menu}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  case ${CHOICE} in
    'Login')
      set_login
      RET=$?; [[ ${RET} -eq 1 ]] && return 1
      ;;
    'Certificate')
      set_user_cert
      RET=$?; [[ ${RET} -eq 1 ]] && return 1
      ;;
    'Shared-Secret')
      set_shared_secret
      RET=$?; [[ ${RET} -eq 1 ]] && return 1
      ;;
    'NONE')
      return 0
      ;;
    *)
      echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
      return 1
      ;;
  esac
  return 0
}

valid_config() {
  local auth_type='|'
  local login_info=''
  if [[ ${is_login} == true ]]
  then
    auth_type="${auth_type} Login |"
    login_info="${login_info}\
    Login    : ${user_login}
    Password : The on you set"
  fi
  if [[ ${is_certificate} == true ]]
  then
    auth_type="${auth_type} Certificate |"
    login_info="${login_info}\
    User Cert : ${user_cert_url}
    User Key  : ${user_key_url}"
  fi
  if [[ ${is_shared_secret} == true ]]
  then
    auth_type="${auth_type} Shared-Secret |"
    login_info="${login_info}\
    Shared Key : ${user_shared_url}"
  fi
  [[ ${is_shared_secret} == true ]] && auth_type="${auth_type} Shared-Secret |"


  if ( whiptail --title 'OpenVPN Configuration' \
    --yesno "Here is your VPN configuration :
    Configration Name : ${conf_name}
    Server    : ${server_address}:${server_port}
    Protocol  : ${server_proto}
    Auth Type : ${auth_type}
    Login     : ${user_login}
    Password  : The one you set
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

  if [[ ${is_certificate} == true ]]
  then
    sed -i -e "s/<TPL:CERT_COMMENT>//g" /etc/openvpn/conf-${conf_name}.conf
    mkdir -p /etc/openvpn/keys
    if echo ${user_cert_url} | grep -q http
    then
      wget ${user_cert_url} -O /etc/openvpn/keys/user.crt
    else
      cp ${user_cert_url} /etc/openvpn/keys/user.crt
    fi
    if echo ${user_key_url} | grep -q http
    then
      wget ${user_key_url} -O /etc/openvpn/keys/user.key
    else
      cp ${user_key_url} /etc/openvpn/keys/user.key
    fi
  else
    sed -i -e "s/<TPL:CERT_COMMENT>/#/g" /etc/openvpn/conf-${conf_name}.conf
  fi

  if [[ ${is_shared_secret} == true ]]
  then
    sed -i -e "s/<TPL:TA_COMMENT>//g" /etc/openvpn/conf-${conf_name}.conf
    mkdir -p /etc/openvpn/keys
    if echo ${user_shared_url} | grep -q http
    then
      wget ${user_shared_url} -O /etc/openvpn/keys/user_ta.key
    else
      cp ${user_shared_url} /etc/openvpn/keys/user_ta.key
    fi
  else
    sed -i -e "s/<TPL:TA_COMMENT>/#/g" /etc/openvpn/conf-${conf_name}.conf
  fi

  echo "TODO : Update ip to use ISP in up and down script and move script to /etc/openvpn"

  if [[ ${is_out_vpn} == true ]]
  then
    sed -i -e "s/<TPL:OUT_VPN_COMMENT//g" /etc/openvpn/conf-${conf_name}.conf
  else
    sed -i -e "s/<TPL:OUT_VPN_COMMENT/#/g" /etc/openvpn/conf-${conf_name}.conf
  fi
  if [[ ${is_out_isp} == true ]]
  then
    sed -i -e "s/<TPL:OUT_ISP_COMMENT//g" /etc/openvpn/conf-${conf_name}.conf
  else
    sed -i -e "s/<TPL:OUT_ISP_COMMENT/#/g" /etc/openvpn/conf-${conf_name}.conf
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

  if ( whiptail --title 'OpenVPN Configuration' \
    --yesno 'Does your VPN require certificate to login ?'\
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    is_certificate=true
    set_user_cert
    RET=$?; [[ ${RET} -eq 1 ]] && return 1
  else
    is_certificate=false
  fi

  if ( whiptail --title 'OpenVPN Configuration' \
    --yesno 'Does your VPN require shared-secret key ?'
    ${WT_HEIGHT} ${WT_WIDTH} )
  then
    is_shared_secret=true
    set_shared_secret
    RET=$?; [[ ${RET} -eq 1 ]] && return 1
  else
    is_shared_secret=false
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
