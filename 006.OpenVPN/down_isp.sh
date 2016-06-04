#!/bin/bash

dev="$1"
tun_mtu="$2"
link_mtu="$3"
local_ip="$4"
remote_ip="$5"

table=4242

# Delete table for source-specific routing.
[ -n "$local_ip" ] \
  && ip rule del from "$local_ip" \
  && ip route del default table "$table"
[ -n "$ifconfig_ipv6_local" ] \
  && ip -6 rule del from "$ifconfig_ipv6_local" \
  && ip -6 route del default table "$table"

exit 0
