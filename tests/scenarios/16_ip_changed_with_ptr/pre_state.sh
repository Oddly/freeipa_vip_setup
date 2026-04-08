#!/usr/bin/env bash
# Old IP was 10.128.1.100, changing to 10.128.2.200
# PTR was under old IP's reverse record
STATE="$1"

mkdir -p "${STATE}/dns_a/example.com"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/haproxy-vip"

# Old PTR for old IP (100.1 in zone 128.10.in-addr.arpa)
mkdir -p "${STATE}/dns_ptr/128.10.in-addr.arpa"
echo "haproxy-vip.example.com." > "${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"

mkdir -p "${STATE}/hosts"
touch "${STATE}/hosts/haproxy-vip.example.com"

mkdir -p "${STATE}/services"
touch "${STATE}/services/HTTP_haproxy-vip.example.com"

mkdir -p "${STATE}/permissions"
touch "${STATE}/permissions/Manage haproxy-vip.example.com managedBy"

mkdir -p "${STATE}/privileges"
touch "${STATE}/privileges/Service Host Management"

mkdir -p "${STATE}/roles"
touch "${STATE}/roles/Certificate Manager"
