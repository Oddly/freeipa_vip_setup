#!/usr/bin/env bash
# State has TWO dns names. The new vars only include one.
# The role does NOT clean up orphaned names (it only processes what's in the list).
STATE="$1"

mkdir -p "${STATE}/dns_a/example.com"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/haproxy-vip"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/old-alias"

mkdir -p "${STATE}/hosts"
touch "${STATE}/hosts/haproxy-vip.example.com"
touch "${STATE}/hosts/old-alias.example.com"

mkdir -p "${STATE}/services"
touch "${STATE}/services/HTTP_haproxy-vip.example.com"
touch "${STATE}/services/HTTP_old-alias.example.com"

mkdir -p "${STATE}/permissions"
touch "${STATE}/permissions/Manage haproxy-vip.example.com managedBy"
touch "${STATE}/permissions/Manage old-alias.example.com managedBy"

mkdir -p "${STATE}/privileges"
touch "${STATE}/privileges/Service Host Management"

mkdir -p "${STATE}/privilege_perms/Service Host Management"
touch "${STATE}/privilege_perms/Service Host Management/Manage haproxy-vip.example.com managedBy"
touch "${STATE}/privilege_perms/Service Host Management/Manage old-alias.example.com managedBy"

mkdir -p "${STATE}/roles"
touch "${STATE}/roles/Certificate Manager"
