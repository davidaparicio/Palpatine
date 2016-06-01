#!/bin/bash

# BEGIN NET INFO
ALL_APP_CAT+=":NET"
APP_NET_CAT="Network application"
APP_NET_EX="A set of application related to network"
# END NET INFO

idx=0
APP_NET_NAME[idx]="OpenVPN"
APP_NET_DESC[idx]="A server or client VPN application"
APP_NET_STAT[idx]="ON"
OpenVPN_routine () {
  case ${LINUX_OS} in
  debian|ubuntu)
  ${LINUX_PKG_MGR} install -y openvpn
    ;;
  *)
    return 1
  esac
  return 0
}
(( idx++ ))


