dev="$1"
tun_mtu="$2"
link_mtu="$3"
local_ip="$4"
remote_ip="$5"
isp_ip="WWW.XXX.YYY.ZZZ"
isp_gateway="WWW.XXX.YYY.ZZZ"
vpn_server="89.234.140.3"

# Routing table to use
tableVPN=4242
tableLOC=1337

# Delete table for source-specific routing.
if [ "$local_ip" ]; then
  ip route del "$vpn_server" via "$isp_gateway" table "$tableLOC"
  ip route del default dev "$dev" table "$tableVPN"
  ip rule del pref 31100 lookup "$tableVPN"
  ip rule del pref 31050 from "$isp_ip" lookup main
  ip rule del pref 31000 lookup "$tableLOC"
          fi

[ -n "$ifconfig_ipv6_local" ] && ip -6 route del default dev "$dev" && ip -6 addr del "$ifconfig_ipv6_local" dev "$dev"

exit 0

