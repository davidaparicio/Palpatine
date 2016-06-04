#!/bin/bash

dev="$1"
tun_mtu="$2"
link_mtu="$3"
local_ip="$4"
remote_ip="$5"

# Routing table to use
table=4242

# Source-specific routing: use the normal default route by default,
# but use the VPN for replying to packets coming from the VPN.
# IPv4
[ -n "$local_ip" ] \
  && ip rule add from "$local_ip" table "$table" \
  && ip route add default dev "$dev" table "$table"
# IPv6
[ -n "$ifconfig_ipv6_local" ] \
  && ip -6 rule add from "$ifconfig_ipv6_local" table "$table" \
  && ip -6 route add default dev "$dev" table "$table"
