#!/usr/bin/env bash
# Only haproxy-vip objects exist; api-vip was already manually removed
STATE="$1"

mkdir -p "${STATE}/dns_a/example.com"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/haproxy-vip"
# api-vip A-record already gone

mkdir -p "${STATE}/hosts"
touch "${STATE}/hosts/haproxy-vip.example.com"
# api-vip host already gone

mkdir -p "${STATE}/services"
touch "${STATE}/services/HTTP_haproxy-vip.example.com"
# api-vip service already gone

mkdir -p "${STATE}/permissions"
touch "${STATE}/permissions/Manage haproxy-vip.example.com managedBy"
# api-vip permission already gone

mkdir -p "${STATE}/privileges"
touch "${STATE}/privileges/Service Host Management"

mkdir -p "${STATE}/privilege_perms/Service Host Management"
touch "${STATE}/privilege_perms/Service Host Management/Manage haproxy-vip.example.com managedBy"
# api-vip privilege perm already detached
