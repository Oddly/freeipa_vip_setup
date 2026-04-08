#!/usr/bin/env bash
# Existing: haproxy-vip only. Adding: new-alias
STATE="$1"

mkdir -p "${STATE}/dns_a/example.com"
echo "10.128.1.100" > "${STATE}/dns_a/example.com/haproxy-vip"

mkdir -p "${STATE}/hosts"
touch "${STATE}/hosts/haproxy-vip.example.com"

mkdir -p "${STATE}/services"
touch "${STATE}/services/HTTP_haproxy-vip.example.com"

mkdir -p "${STATE}/permissions"
touch "${STATE}/permissions/Manage haproxy-vip.example.com managedBy"

mkdir -p "${STATE}/privileges"
touch "${STATE}/privileges/Service Host Management"

mkdir -p "${STATE}/privilege_perms/Service Host Management"
touch "${STATE}/privilege_perms/Service Host Management/Manage haproxy-vip.example.com managedBy"

mkdir -p "${STATE}/roles"
touch "${STATE}/roles/Certificate Manager"

mkdir -p "${STATE}/role_privs/Certificate Manager"
touch "${STATE}/role_privs/Certificate Manager/Service Host Management"

mkdir -p "${STATE}/role_members/Certificate Manager"
touch "${STATE}/role_members/Certificate Manager/certadmin"
