# freeipa_vip_setup

Ansible role for setting up FreeIPA objects required for TLS certificates with VIP addresses via the [ipa_certmonger](https://github.com/Oddly/ipa_certmonger) module.

## Background

In a HAProxy/Keepalived setup with TCP passthrough, backend servers (e.g. Elasticsearch, Logstash) receive TLS connections arriving via a shared VIP address. The backend server's certificate must therefore include the VIP address and/or VIP DNS name as a SAN (Subject Alternative Name).

FreeIPA requires several objects before a certificate with VIP SANs can be issued:

- A DNS A-record must exist for each VIP DNS name
- A PTR-record must exist if the VIP IP needs to be included as a SAN in the certificate
- A dummy host and service principal must exist per VIP DNS name
- The certadmin user must have managedBy permissions on the VIP service principals

This role automates all of these steps. It is idempotent and safe to run multiple times.

It also handles edge cases:
- **IP change**: detects stale A-records and replaces them with the correct IP
- **PTR change**: detects stale PTR-records and replaces them
- **`include_ip_in_cert` toggled off**: removes the PTR-record

## Requirements

- Must run on a FreeIPA server as root (or via `delegate_to` from another playbook)
- FreeIPA DNS must be enabled and managing the domain
- A valid Kerberos ticket must be available on the IPA server (e.g. via a service account in the `admins` group)

## Usage

### Standalone

```bash
# Create VIP objects
ansible-playbook -i ipa-server.example.com, setup-vip.yml -e @vars/myenv.yml

# Dry-run (shows an overview of all objects without making changes)
ansible-playbook -i ipa-server.example.com, setup-vip.yml -e @vars/myenv.yml --check

# Remove all VIP objects
ansible-playbook -i ipa-server.example.com, setup-vip.yml -e @vars/myenv.yml -e freeipa_vip_state=absent
```

Note the trailing comma after the hostname — this tells Ansible to treat it as a host, not an inventory file.

### Integration with other playbooks

The role can be run from another playbook via `delegate_to`. This ensures the FreeIPA VIP setup happens automatically as part of the deploy, without running it separately.

```yaml
- name: FreeIPA VIP setup
  hosts: elasticsearch
  gather_facts: false
  run_once: true
  tasks:
    - name: Run freeipa_vip_setup on the IPA server
      ansible.builtin.include_role:
        name: freeipa_vip_setup
      delegate_to: "{{ freeipa_server }}"
      become: true
      when: freeipa_vip_records | default([]) | length > 0
```

This requires:
- `freeipa_server` variable in group_vars (e.g. `ipa-server.example.com`)
- `freeipa_vip_records` variable in group_vars
- SSH access from the machine running the playbook to the IPA server
- The role must be installed (via `requirements.yml`)

Example `requirements.yml`:
```yaml
- src: https://github.com/Oddly/freeipa_vip_setup.git
  scm: git
  name: freeipa_vip_setup
  version: main
```

## Examples

### Multiple DNS names on a VIP, without IP SAN

Four DNS names pointing to the same VIP IP. Only the DNS names are included as SANs in certificates. Clients always connect via DNS name, never via IP.

```yaml
freeipa_domain: "example.com"

freeipa_vip_records:
  - dns_names:
      - "haproxy-vip.example.com"
      - "logstash-vip.example.com"
      - "sensu-vip.example.com"
      - "elastic-vip.example.com"
    ip: "10.0.0.100"
```

FreeIPA objects created:
- 4 DNS A-records (all pointing to `10.0.0.100`)
- 4 dummy hosts
- 4 service principals (`HTTP/*-vip.example.com`)
- 4 managedBy permissions
- 1 privilege + 1 role for certadmin

### Multiple DNS names with IP SAN

Same as above, but the VIP IP is also included as a SAN in the certificate. This is needed when clients connect directly via the IP address instead of a DNS name. FreeIPA requires a PTR-record for this — only one PTR per IP is possible, so you must explicitly specify which DNS name gets the PTR.

```yaml
freeipa_domain: "example.com"

freeipa_vip_records:
  - dns_names:
      - "haproxy-vip.example.com"
      - "logstash-vip.example.com"
      - "sensu-vip.example.com"
      - "elastic-vip.example.com"
    ip: "10.0.0.100"
    include_ip_in_cert: true
    reverse_dns_name: "haproxy-vip.example.com"
```

Additional FreeIPA object compared to the previous example:
- 1 DNS PTR-record (in the reverse zone for `10.0.0.100` -> `haproxy-vip.example.com`)

### Single DNS name per VIP

Simplest configuration — a VIP with a single DNS name and IP SAN.

```yaml
freeipa_domain: "example.com"

freeipa_vip_records:
  - dns_names:
      - "elastic-vip.example.com"
    ip: "10.0.0.100"
    include_ip_in_cert: true
    reverse_dns_name: "elastic-vip.example.com"
```

### Multiple VIPs

Two separate VIP addresses with their own DNS names.

```yaml
freeipa_domain: "example.com"

freeipa_vip_records:
  - dns_names:
      - "elastic-vip.example.com"
      - "logstash-vip.example.com"
    ip: "10.0.0.100"
    include_ip_in_cert: true
    reverse_dns_name: "elastic-vip.example.com"
  - dns_names:
      - "monitoring-vip.example.com"
    ip: "10.0.0.101"
    include_ip_in_cert: true
    reverse_dns_name: "monitoring-vip.example.com"
```

### /24 reverse zone

If the network uses a /24 prefix instead of /16, override `reverse_zone` per record:

```yaml
freeipa_domain: "example.com"

freeipa_vip_records:
  - dns_names:
      - "vip.example.com"
    ip: "10.0.1.100"
    include_ip_in_cert: true
    reverse_dns_name: "vip.example.com"
    reverse_zone: "1.0.10.in-addr.arpa"
```

## What the role does vs what is manual

| Step | Role | Manual |
|------|------|--------|
| DNS A-records | Automatic | |
| DNS PTR-record | Automatic | |
| Dummy hosts | Automatic | |
| Service principals | Automatic | |
| managedBy permissions | Automatic | |
| Privilege creation | Automatic | |
| Role creation + certadmin assignment | Automatic | |
| Kerberos ticket on IPA server | | Must be available (e.g. service account) |
| SSH access to IPA server | | Must be configured |
| Define `freeipa_vip_records` | | In group_vars per environment |

When using `state: absent`, all per-VIP objects are removed. The privilege and role are **not** removed — they may be shared across environments.

## Troubleshooting

### "no modifications to be performed"

The object already exists with the same configuration. This is normal on a repeated run — the role is idempotent.

### "already exists"

The object already exists. Same as above — the role skips it.

### "DNS zone not found"

The zone does not exist in FreeIPA DNS, or the active Kerberos principal does not have permission to manage DNS. Check:
```bash
ipa dnszone-find
```

### "The host ... does not exist to add a service to"

The dummy host has not been created yet. This should not occur if the role runs in order. If it does, run the role again.

### "Insufficient access"

The active Kerberos principal does not have sufficient permissions. Check which ticket is active:
```bash
klist
```
The ticket must belong to a user in the `admins` group, or one that has specific permissions for the required operations.

### "IP address in subjectAltName unreachable from DNS names"

This is a FreeIPA CA error when requesting a certificate (not from this role). It means:
1. The DNS A-record for the VIP DNS name is missing, or
2. The PTR-record for the VIP IP is missing, or
3. The VIP DNS name is not included as a SAN alongside the IP

Check that the role has run successfully and that DNS records are correct:
```bash
dig elastic-vip.example.com +short
dig -x 10.0.0.100 +short
```

### "service principal does not exist"

The VIP service principal has not been created. Run the role again or create it manually:
```bash
ipa host-add elastic-vip.example.com --force
ipa service-add HTTP/elastic-vip.example.com --force
```

## Variables

### Required

| Variable | Description |
|----------|-------------|
| `freeipa_domain` | Domain for DNS records (e.g. `example.com`) |
| `freeipa_vip_records` | List of VIP records (see examples above) |

### vip_records structure

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `dns_names` | yes | | List of DNS names for this VIP |
| `ip` | yes | | VIP IP address |
| `include_ip_in_cert` | no | `false` | Add the IP as a SAN in certificates |
| `reverse_dns_name` | when `include_ip_in_cert` | | DNS name for the PTR record, must be in `dns_names` |
| `reverse_zone` | no | derived from IP as /16 | Reverse DNS zone (override for /24 networks) |

### Optional (with defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `freeipa_realm` | uppercase of `freeipa_domain` | Kerberos realm |
| `freeipa_certadmin_user` | `certadmin` | User that gets managedBy permissions |
| `freeipa_certadmin_role` | `Certificate Manager` | IPA role name for certadmin |
| `freeipa_vip_privilege` | `Service Host Management` | IPA privilege name |
| `freeipa_service_type` | `HTTP` | Service principal type |
| `freeipa_vip_state` | `present` | `present` (create) or `absent` (remove) |

### Reverse zone

By default, the reverse zone is derived from the IP address assuming a /16 network:
- `10.128.6.200` -> zone `128.10.in-addr.arpa`, record `200.6`

Override per VIP record with `reverse_zone` if the network uses a different prefix length.

## Directory structure

```
freeipa_vip_setup/
├── ansible.cfg                # Ansible configuration
├── defaults/main.yml          # Default variables
├── meta/main.yml              # Role metadata
├── tasks/
│   ├── main.yml               # Validation, preview, privilege/role setup
│   ├── vip_record.yml         # Per-record: DNS, hosts, services, permissions
│   └── vip_record_absent.yml  # Per-record removal (reverse order)
├── setup-vip.yml              # Standalone playbook
└── README.md
```

## Relationship with ipa_certmonger

This role creates the FreeIPA prerequisites. The `ipa_certmonger` module then uses them:

```
freeipa_vip_setup (once, as IPA admin)         ipa_certmonger (each deploy, as certadmin)
──────────────────────────────────────         ──────────────────────────────────────────
DNS A-records                                  (reads dns_names as SANs)
DNS PTR-record                                 (enables IP SAN validation)
Dummy hosts                                    (required for service principals)
Service principals                             (required for managedBy)
managedBy permissions                      ->  service-add-host (per host)
Privilege + role for certadmin                 (enables service-add-host)
```

Both consume the same `freeipa_vip_records` variable structure.

## License

GNU General Public License v3.0+
