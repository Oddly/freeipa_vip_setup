#!/usr/bin/env bash
# Full state from a previous present run
STATE="$1"

mkdir -p "${STATE}/dns_a/example.com"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/haproxy-vip"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/api-vip"

mkdir -p "${STATE}/dns_ptr/128.10.in-addr.arpa"
echo "haproxy-vip.example.com." > "${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"

mkdir -p "${STATE}/hosts"
touch "${STATE}/hosts/haproxy-vip.example.com"
touch "${STATE}/hosts/api-vip.example.com"

mkdir -p "${STATE}/services"
touch "${STATE}/services/HTTP_haproxy-vip.example.com"
touch "${STATE}/services/HTTP_api-vip.example.com"

mkdir -p "${STATE}/permissions"
touch "${STATE}/permissions/Manage haproxy-vip.example.com managedBy"
touch "${STATE}/permissions/Manage api-vip.example.com managedBy"

mkdir -p "${STATE}/privileges"
touch "${STATE}/privileges/Service Host Management"

mkdir -p "${STATE}/privilege_perms/Service Host Management"
touch "${STATE}/privilege_perms/Service Host Management/Manage haproxy-vip.example.com managedBy"
touch "${STATE}/privilege_perms/Service Host Management/Manage api-vip.example.com managedBy"

mkdir -p "${STATE}/roles"
touch "${STATE}/roles/Certificate Manager"
