#!/bin/bash

dev="$1"
isp_dev="<TPL:LOCAL_IFACE>"
tun_mtu="$2"
link_mtu="$3"
local_ip="$4"
remote_ip="$5"
#isp_ip="WWW.XXX.YYY.ZZZ"
#isp_gateway="WWW.XXX.YYY.ZZZ"
#vpn_server="89.234.140.3"
isp_ip="<TPL:ISP_IP>"
isp_gateway="<TPL:ISP_GATEWAY>"
vpn_server="<TPL:VPN_IP>"

# Routing table to use
tableVPN=4242
tableLOC=1337

# IP inconnue de COIN, donc tun0 à monter
ip link set "$dev" up
ip addr add "$local_ip"/32 dev "$dev"

# Source-specific routing: use the normal default route by default,
# but use the VPN for replying to packets coming from the VPN.
# IPv4
if [ -n "local_ip" ]; then
  ip rule add pref 31000 lookup "$tableLOC"
  ip rule add pref 31050 from "$isp_ip" lookup main
  ip rule add pref 31100 lookup "$tableVPN"
  ip route add default dev "$dev" table "$tableVPN"
  ip route add "$vpn_server" via "$isp_gateway" table "$tableLOC" dev "$isp_dev"
fi

# IPv6
[ -n "$ifconfig_ipv6_local" ] && ip -6 addr add "$ifconfig_ipv6_local" dev "$dev" && ip -6 route add default dev "$dev"

exit 0
