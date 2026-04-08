#!/usr/bin/env bash
# Existing entry WITH PTR. Now toggling include_ip_in_cert to false.
STATE="$1"

mkdir -p "${STATE}/dns_a/example.com"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/haproxy-vip"

# Existing PTR record
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
