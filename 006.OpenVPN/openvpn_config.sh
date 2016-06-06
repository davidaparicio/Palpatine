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
    'udp' '' \
    'tcp' ''"
  bash -c "${server_proto}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_proto=$( cat results_menu.txt )
}

set_password() {
  # Set Yunohost user password
  local passwd_ok=false
  # REGEX PASSWORD
  #^([a-zA-Z0-9@*#_]{8,15})$
  #Description
  #Password matching expression.
  #Match all alphanumeric character and predefined wild characters.
  #Password must consists of at least 8 characters and not more than 15 characters.
  local passwd1=""
  local passwd2=""

  while true
  do
    passwd1="whiptail --title 'OpenVPN Configuration' \
      --passwordbox 'Please enter the password to connect to your VPN provider' \
      ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${passwd1}" 2>results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    passwd1=$( cat results_menu.txt )
    local passwd2="whiptail --title 'OpenVPN Configuration' \
      --passwordbox 'Please enter the password again.' ${WT_HEIGHT} ${WT_WIDTH}"
    bash -c "${passwd2}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    passwd2=$( cat results_menu.txt )
    if [[ ! ${passwd1} == ${passwd2} ]]
    then
      if ! ( whiptail --title 'OpenVPN Configuration' \
        --yesno "Passwords do not match.

Do you want to retry ?" ${WT_HEIGHT} ${WT_WIDTH} )
      then
        return 1
      fi
    else
      user_pass=${passwd1}
      return 0
    fi
  done
}

set_login() {
  user_login="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the username to use to connect to your VPN :' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_login}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_login=$( cat results_menu.txt )

  set_password
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  is_login=true
  return 0
}

set_server_cert_url() {
  server_cert_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download server certificate or if \
you have already copy it on the system, you can enter its absolute path like \
/home/user/path/to/server.crt' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${server_cert_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  server_cert_url=$( cat results_menu.txt )

  return 0
}

set_user_cert() {
  user_cert_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download client certificate or if \
you have already copy it on the system, you can enter its absolute path like \
/home/user/path/to/client.crt' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_cert_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_cert_url=$( cat results_menu.txt )

  user_key_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download client key or if \
you have already copy it on the system, you can enter its absolute path like \
/home/user/path/to/client.key' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_key_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_key_url=$( cat results_menu.txt )

  is_certificate=true
  return 0
}

set_shared_secret() {
  user_shared_url="whiptail --title 'OpenVPN Configuration' \
    --inputbox 'Please enter the http URL to download shared key or if \
you have already copy it on the system, you can enter its absolute path like \
/home/user/path/to/shared.key' \
    ${WT_HEIGHT} ${WT_WIDTH}"
  bash -c "${user_shared_url}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  user_shared_url=$( cat results_menu.txt )

  is_shared_secret=true
  return 0
}

set_auth_method() {
  echo ${FUNCNAME}
  menu="whiptail --title 'OpenVPN Configuration' \
    --checklist 'Select authentication method to you VPN provider, if no auth \
method do not select anything.' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
    'Login'         'Require login and password'       'ON' \
    'Certificate'   'Require user certificate and key' 'OFF' \
    'Shared-Secret' 'Require shared secret key'        'OFF'"
  bash -c "${menu}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  for auth in $CHOICE
  do
    case ${auth} in
      '"Login"')
        set_login
        RET=$?; [[ ${RET} -eq 1 ]] && return 1
        ;;
      '"Certificate"')
        set_user_cert
        RET=$?; [[ ${RET} -eq 1 ]] && return 1
        ;;
      '"Shared-Secret"')
        set_shared_secret
        RET=$?; [[ ${RET} -eq 1 ]] && return 1
        ;;
      *)
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        ;;
    esac
  done <<< $( cat results_menu.txt )
  return 0
}

valid_config() {
  local auth_type='|'
  local login_info=''
  if [[ ${is_login} == true ]]
  then
    auth_type="${auth_type} Login |"
    login_info="${login_info}
    Login    : ${user_login}
    Password : The on you set"
  fi

  if [[ ${is_certificate} == true ]]
  then
    auth_type="${auth_type} Certificate |"
    login_info="${login_info}
    User Cert : ${user_cert_url}
    User Key  : ${user_key_url}"
  fi

  if [[ ${is_shared_secret} == true ]]
  then
    auth_type="${auth_type} Shared-Secret |"
    login_info="${login_info}
    Shared Key : ${user_shared_url}"
  fi

  [[ ${is_shared_secret} == true ]] && auth_type="${auth_type} Shared-Secret |"

  if ( whiptail --title 'OpenVPN Configuration' \
    --yesno "Here is your VPN configuration :
    Configration Name : ${conf_name}
    Server    : ${server_address}:${server_port}
    Protocol  : ${server_proto}
    Auth Type : ${auth_type}
    ${login_info}
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
  cp $dir/template.conf /etc/openvpn/openvpn-${conf_name}.conf
  # Apply config
  sed -i  -e "s/<TPL:CONF_NAME>/${conf_name}/g" \
      -e "s/<TPL:SERVER_NAME>/${server_address}/g" \
      -e "s/<TPL:SERVER_PORT>/${server_port}/g" \
      -e "s/<TPL:SERVER_PROTO>/${server_proto}/g" /etc/openvpn/openvpn-${conf_name}.conf

  if [[ ${is_udp} == true ]]
  then
    sed -i -e "s/<TPL:UDP_COMMENT>//g" /etc/openvpn/openvpn-${conf_name}.conf
  else
    sed -i -e "s/<TPL:UDP_COMMENT>/#/g" /etc/openvpn/openvpn-${conf_name}.conf
  fi

  if echo ${server_cert_url} | grep -q http
  then
    wget ${server_cert_url} -O /etc/openvpn/keys/ca-server-${conf_name}.crt
  else
    cp ${server_cert_url} /etc/openvpn/keys/ca-server-${conf_name}.crt
  fi

  if [[ ${is_login} == true ]]
  then
    sed -i -e "s/<TPL:LOGIN_COMMENT>//g" /etc/openvpn/openvpn-${conf_name}.conf
    mkdir -p /etc/openvpn/keys
    echo ${user_login} > /etc/openvpn/keys/credentials-${conf_name}
    echo ${user_pass} >> /etc/openvpn/keys/credentials-${conf_name}
  else
    sed -i -e "s/<TPL:LOGIN_COMMENT>/#/g" /etc/openvpn/openvpn-${conf_name}.conf
  fi

  if [[ ${is_certificate} == true ]]
  then
    sed -i -e "s/<TPL:CERT_COMMENT>//g" /etc/openvpn/openvpn-${conf_name}.conf
    mkdir -p /etc/openvpn/keys
    if echo ${user_cert_url} | grep -q http
    then
      wget ${user_cert_url} -O /etc/openvpn/keys/user-${conf_name}.crt
    else
      cp ${user_cert_url} /etc/openvpn/keys/user-${conf_name}.crt
    fi
    if echo ${user_key_url} | grep -q http
    then
      wget ${user_key_url} -O /etc/openvpn/keys/user-${conf_name}.key
    else
      cp ${user_key_url} /etc/openvpn/keys/user-${conf_name}.key
    fi
  else
    sed -i -e "s/<TPL:CERT_COMMENT>/#/g" /etc/openvpn/openvpn-${conf_name}.conf
  fi

  if [[ ${is_shared_secret} == true ]]
  then
    sed -i -e "s/<TPL:TA_COMMENT>//g" /etc/openvpn/openvpn-${conf_name}.conf
    mkdir -p /etc/openvpn/keys
    if echo ${user_shared_url} | grep -q http
    then
      wget ${user_shared_url} -O /etc/openvpn/keys/user_ta-${conf_name}.key
    else
      cp ${user_shared_url} /etc/openvpn/keys/user_ta-${conf_name}.key
    fi
  else
    sed -i -e "s/<TPL:TA_COMMENT>/#/g" /etc/openvpn/openvpn-${conf_name}.conf
  fi

}

choose_config() {
  local all_conf
  local name
  local menu="whiptail --title 'OpenVPN Configuration' \
    --menu 'Choose configuration you wan to $1:' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT}"
  for conf in /etc/openvpn/*.conf
  do
    name=${conf##*openvpn/openvpn-}
    name=${name%%.conf}
    menu="${menu} '${name}' ''"
  done
  bash -c "${menu}" 2> results_menu.txt
  RET=$? ; [[ ${RET} -eq 1 ]] && return 1
  conf_name=$( cat results_menu.txt )
}

menu_config() {
  local menu="whiptail --title 'OpenVPN Configuration' \
    --menu 'What do you want to do change :' \
    ${WT_HEIGHT} ${WT_WIDTH} ${WT_MENU_HEIGHT} \
  'Name' 'Change config name' \
  'Server Address' 'Change VPN Server address' \
  'Server Port'    'Change VPN Server port' \
  'Protocol'       'Change VPN Server protocol to use' \
  'Authentication Method' 'Change method to authenticate' \
  'Server Certificate'    'Change server certificate file' \
  'UPDATE'                'Apply update' \
  '<-- Back'              'Back to previous menu'"
  bash -c "${menu}" 2> results_menu.txt
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  CHOICE=$( cat results_menu.txt )
  case ${CHOISE} in
    'Name')
      set_conf_name
      ;;
    'Server Address')
      set_server_address
      ;;
    'Server Port')
      set_server_port
      ;;
    'Protocol')
      set_server_proto
      ;;
    'Authentication Method')
      set_auth_method
      ;;
    'Server Certificate')
      set_server_cert_url
      ;;
    'UPDATE')
      valid_config
      ;;
    '<-- Back')
      return 0
      ;;
  esac
}

new_config() {
  # Get script directory, gonna need sometime to be sure to get back to the
  # right directory
  set_conf_name
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_address
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_port
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_proto
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  [[ ${server_proto} == udp ]] && is_udp=true || is_udp=false

  set_auth_method
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  set_server_cert_url
  RET=$?; [[ ${RET} -eq 1 ]] && return 1

  valid_config
  RET=$?; [[ ${RET} -eq 1 ]] && return 1
  return 0
}

update_config() {
  local credential_file=$( grep "^auth-user-pass " /etc/openvpn/openvpn-${conf_name} | awk '${print $2}' )
  server_address=$( grep "^remote " /etc/openvpn/openvpn-${conf_name}.conf | awk '{print $2}' )
  server_port=$( grep "^port " /etc/openvpn/openvpn-${conf_name}.conf | awk '{print $2}' )
  server_proto=$( grep "^proto " /etc/openvpn/openvpn-${conf_name}.conf | awk '{print $2}' )
  [[ ${server_proto} == 'udp' ]] && is_udp=true || is_udp=false
  grep -q "^auth-user-pass " /etc/openvpn/openvpn-${conf_name}.conf \
    && is_login=true || is_login=false
  server_cert_url=$( grep "^ca " /etc/openvpn/openvpn-${conf_name}.conf | awk '{print $2}' )
  user_cert_url=$( grep "^cert " /etc/openvpn/openvpn-${conf_name}.conf | awk '{print $2}' )
  user_key_url=$( grep "^key " /etc/openvpn/openvpn-${conf_name}.conf | awk '{print $2}' )

  menu_config
}

delete_config() {
  if ( whiptail --title 'OpenVPN Configuration' \
    --yesno "Are you sur you want to delete following configuration and its \
associate files : ${conf_name} ?" ${WT_HEIGHT} ${WT_WIDTH} )
  then
    rm /etc/openvpn/openvpn-${conf_name}.conf
    rm /etc/openvpn/keys/credentials-${conf_name}
    rm /etc/openvpn/keys/user-${conf_name}.crt
    rm /etc/openvpn/keys/user-${conf_name}.key
    rm /etc/openvpn/keys/user_ta-${conf_name}.key
    rm /etc/openvpn/ca-server-${conf_name}.crt
    return 0
  else
    return 1
  fi
}

openvpn_config() {
  local conf_name
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

    bash -c "${menu}" 2> results_menu.txt
    RET=$? ; [[ ${RET} -eq 1 ]] && return 1
    CHOICE=$( cat results_menu.txt )
    case ${CHOICE} in
      '<-- Back' )
        return 1
        ;;
      'New Config')
        new_config
        RET=$? ; [[ ${RET} -eq 1 ]] && menu_config
        ;;
      'Update Config')
        choose_config
        RET=$? ; ! [[ ${RET} -eq 1 ]] && update_config
        ;;
      'Delete Config')
        choose_config
        RET=$? ; ! [[ ${RET} -eq 1 ]] && delete_config
        ;;
      * )
        echo "Programmer error : Option ${CHOICE} uknown in ${FUNCNAME}."
        return 1
        ;;
    esac
  done
}
