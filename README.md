# freeipa_vip_setup

Ansible role voor het aanmaken van FreeIPA objecten die nodig zijn voor TLS-certificaten met VIP-adressen via de [ipa_certmonger](https://github.com/Oddly/ipa_certmonger) module.

## Achtergrond

Bij een HAProxy/Keepalived setup met TCP passthrough ontvangen backend servers (bv. Elasticsearch, Logstash) TLS-verbindingen die via een gedeeld VIP-adres binnenkomen. Het certificaat van de backend server moet daarom het VIP-adres en/of de VIP DNS-naam als SAN (Subject Alternative Name) bevatten.

FreeIPA stelt een aantal eisen voordat een certificaat met VIP SANs uitgegeven kan worden:

- Er moet een DNS A-record bestaan voor elke VIP DNS-naam
- Er moet een PTR-record bestaan als het VIP IP als SAN in het certificaat moet
- Er moet een dummy host en service principal bestaan per VIP DNS-naam
- De certadmin gebruiker moet managedBy rechten hebben op de VIP service principals

Deze role automatiseert al deze stappen. Het is idempotent en veilig om meerdere keren te draaien.

Edge cases die afgehandeld worden:
- **IP wijziging**: detecteert verouderde A-records en vervangt ze met het juiste IP
- **PTR wijziging**: detecteert verouderde PTR-records en vervangt ze
- **PTR bij oud IP**: als het IP verandert, wordt ook de PTR bij het oude IP opgeruimd
- **`include_ip_in_cert` uitgezet**: verwijdert het PTR-record

## Vereisten

- Moet draaien op een FreeIPA server als root (of via `delegate_to` vanuit een ander playbook)
- FreeIPA DNS moet ingeschakeld zijn en het domein beheren
- Er moet een geldig Kerberos ticket beschikbaar zijn op de IPA server (bv. via een service account in de `admins` groep)

## Gebruik

### Standalone

```bash
# ACC omgeving aanmaken
ansible-playbook -i adm-aaa-001.rinis.cloud, setup-vip.yml -e @vars/acc.yml

# Dry-run (toont een overzicht van alle objecten zonder wijzigingen)
ansible-playbook -i adm-aaa-001.rinis.cloud, setup-vip.yml -e @vars/acc.yml --check

# Alles verwijderen
ansible-playbook -i adm-aaa-001.rinis.cloud, setup-vip.yml -e @vars/acc.yml -e freeipa_vip_state=absent
```

Let op de komma na de hostnaam — dit vertelt Ansible dat het een host is, geen inventory bestand.

### Integratie met andere playbooks

De role kan vanuit een ander playbook gedraaid worden via `delegate_to`. Dit zorgt ervoor dat de FreeIPA VIP setup automatisch gebeurt als onderdeel van de deploy.

```yaml
- name: FreeIPA VIP setup
  hosts: elasticsearch
  gather_facts: false
  run_once: true
  tasks:
    - name: Draai freeipa_vip_setup op de IPA server
      ansible.builtin.include_role:
        name: freeipa_vip_setup
      delegate_to: "{{ freeipa_server }}"
      become: true
      when: freeipa_vip_records | default([]) | length > 0
```

Hiervoor is nodig:
- `freeipa_server` variabele in de group_vars (bv. `adm-aaa-001.rinis.cloud`)
- `freeipa_vip_records` variabele in de group_vars
- SSH-toegang van de machine die het playbook draait naar de IPA server
- De role moet geinstalleerd zijn (via `requirements.yml`)

## Voorbeelden

### Meerdere DNS-namen op een VIP, zonder IP SAN

Vier DNS-namen wijzen naar hetzelfde VIP IP. Alleen de DNS-namen komen als SAN in de certificaten. Clients verbinden altijd via DNS-naam, nooit via IP.

```yaml
freeipa_vip_records:
  - dns_names:
      - "acc-haproxy-vip.rinis.cloud"
      - "acc-logstash-vip.rinis.cloud"
      - "acc-sensu-vip.rinis.cloud"
      - "acc-elastic-vip.rinis.cloud"
    ip: "10.128.6.200"
```

FreeIPA objecten die aangemaakt worden:
- 4 DNS A-records (alle naar `10.128.6.200`)
- 4 dummy hosts
- 4 service principals (`HTTP/acc-*-vip.rinis.cloud`)
- 4 managedBy permissies
- 1 privilege + 1 role voor certadmin

### Meerdere DNS-namen met IP SAN

Zelfde als hierboven, maar het VIP IP komt ook als SAN in het certificaat. Dit is nodig als clients direct het IP-adres gebruiken. FreeIPA vereist hiervoor een PTR-record — er kan maar een PTR per IP zijn, dus je moet expliciet aangeven welke DNS-naam de PTR krijgt.

```yaml
freeipa_vip_records:
  - dns_names:
      - "acc-haproxy-vip.rinis.cloud"
      - "acc-logstash-vip.rinis.cloud"
      - "acc-sensu-vip.rinis.cloud"
      - "acc-elastic-vip.rinis.cloud"
    ip: "10.128.6.200"
    include_ip_in_cert: true
    reverse_dns_name: "acc-haproxy-vip.rinis.cloud"
```

Extra FreeIPA object t.o.v. het vorige voorbeeld:
- 1 DNS PTR-record (`200.6` in zone `128.10.in-addr.arpa` -> `acc-haproxy-vip.rinis.cloud`)

### Meerdere VIPs

Twee aparte VIP-adressen met elk hun eigen DNS-namen.

```yaml
freeipa_vip_records:
  - dns_names:
      - "acc-elastic-vip.rinis.cloud"
      - "acc-logstash-vip.rinis.cloud"
    ip: "10.128.6.200"
    include_ip_in_cert: true
    reverse_dns_name: "acc-elastic-vip.rinis.cloud"
  - dns_names:
      - "acc-monitoring-vip.rinis.cloud"
    ip: "10.128.6.201"
    include_ip_in_cert: true
    reverse_dns_name: "acc-monitoring-vip.rinis.cloud"
```

### /24 reverse zone

Als het netwerk een /24 prefix gebruikt in plaats van /16, overschrijf `reverse_zone` per record:

```yaml
freeipa_vip_records:
  - dns_names:
      - "acc-vip.rinis.cloud"
    ip: "10.128.1.100"
    include_ip_in_cert: true
    reverse_dns_name: "acc-vip.rinis.cloud"
    reverse_zone: "1.128.10.in-addr.arpa"
```

## Wat doet de role vs wat is handmatig

| Stap | Role | Handmatig |
|------|------|-----------|
| DNS A-records | Automatisch | |
| DNS PTR-record | Automatisch | |
| Dummy hosts | Automatisch | |
| Service principals | Automatisch | |
| managedBy permissies | Automatisch | |
| Privilege aanmaken | Automatisch | |
| Role aanmaken + certadmin koppelen | Automatisch | |
| Kerberos ticket op IPA server | | Moet beschikbaar zijn (bv. service account) |
| SSH-toegang tot IPA server | | Moet geconfigureerd zijn |
| `freeipa_vip_records` definieren | | In group_vars per omgeving |

Bij `state: absent` worden alle per-VIP objecten verwijderd. De privilege en role worden **niet** verwijderd — die kunnen gedeeld zijn tussen omgevingen.

## Troubleshooting

### "no modifications to be performed"

Het object bestaat al met dezelfde configuratie. Dit is normaal bij een herhaalde run — de role is idempotent.

### "already exists"

Het object bestaat al. Zelfde als hierboven — de role skipt het.

### "DNS zone not found"

De zone bestaat niet in FreeIPA DNS, of de actieve Kerberos principal heeft geen rechten om DNS te beheren. Controleer:
```bash
ipa dnszone-find
```

### "The host ... does not exist to add a service to"

De dummy host is nog niet aangemaakt. Dit zou niet moeten voorkomen als de role in volgorde draait. Als het toch gebeurt, draai de role opnieuw.

### "Insufficient access"

De actieve Kerberos principal heeft niet genoeg rechten. Controleer welk ticket actief is:
```bash
klist
```
Het ticket moet van een gebruiker zijn die in de `admins` groep zit.

### "IP address in subjectAltName unreachable from DNS names"

Dit is een FreeIPA CA error bij het aanvragen van een certificaat (niet bij deze role). Het betekent dat:
1. Het DNS A-record voor de VIP DNS-naam ontbreekt, of
2. Het PTR-record voor het VIP IP ontbreekt, of
3. De VIP DNS-naam niet als SAN in het certificaat zit naast het IP

Controleer of de role succesvol gedraaid heeft:
```bash
dig acc-elastic-vip.rinis.cloud +short
dig -x 10.128.6.200 +short
```

### "service principal does not exist"

De VIP service principal is niet aangemaakt. Draai de role opnieuw of maak hem handmatig aan:
```bash
ipa host-add acc-elastic-vip.rinis.cloud --force
ipa service-add HTTP/acc-elastic-vip.rinis.cloud --force
```

## Variabelen

### Verplicht

| Variabele | Beschrijving |
|-----------|--------------|
| `freeipa_domain` | Domein voor DNS records (standaard: `rinis.cloud`) |
| `freeipa_vip_records` | Lijst van VIP records (zie voorbeelden hierboven) |

### vip_records structuur

| Veld | Verplicht | Standaard | Beschrijving |
|------|-----------|-----------|--------------|
| `dns_names` | ja | | Lijst van DNS-namen voor dit VIP |
| `ip` | ja | | VIP IP-adres |
| `include_ip_in_cert` | nee | `false` | Voeg het IP toe als SAN in certificaten |
| `reverse_dns_name` | bij `include_ip_in_cert` | | DNS-naam voor het PTR-record, moet in `dns_names` staan |
| `reverse_zone` | nee | afgeleid van IP als /16 | Reverse DNS zone (overschrijf voor /24 netwerken) |

### Optioneel (met standaardwaarden)

| Variabele | Standaard | Beschrijving |
|-----------|-----------|--------------|
| `freeipa_realm` | domein in hoofdletters | Kerberos realm |
| `freeipa_certadmin_user` | `certadmin` | Gebruiker die managedBy rechten krijgt |
| `freeipa_certadmin_role` | `Certificate Manager` | IPA role naam voor certadmin |
| `freeipa_vip_privilege` | `Service Host Management` | IPA privilege naam |
| `freeipa_service_type` | `HTTP` | Service principal type |
| `freeipa_vip_state` | `present` | `present` (aanmaken) of `absent` (verwijderen) |

### Reverse zone

Standaard wordt de reverse zone afgeleid van het IP-adres uitgaande van een /16 netwerk:
- `10.128.6.200` -> zone `128.10.in-addr.arpa`, record `200.6`

Overschrijf per VIP record met `reverse_zone` als het netwerk een andere prefix lengte gebruikt.

## Directory structuur

```
freeipa_vip_setup/
├── ansible.cfg                # Ansible configuratie
├── defaults/main.yml          # Standaard variabelen
├── meta/main.yml              # Role metadata
├── tasks/
│   ├── main.yml               # Validatie, preview, privilege/role setup
│   ├── vip_record.yml         # Per-record: DNS, hosts, services, permissies
│   └── vip_record_absent.yml  # Per-record verwijdering (omgekeerde volgorde)
├── vars/
│   └── acc.yml                # ACC omgeving variabelen
├── setup-vip.yml              # Standalone playbook
└── README.md
```

## Relatie met ipa_certmonger

Deze role maakt de FreeIPA vereisten aan. De `ipa_certmonger` module gebruikt ze vervolgens:

```
freeipa_vip_setup (eenmalig, als IPA admin)    ipa_certmonger (elke deploy, als certadmin)
────────────────────────────────────────       ──────────────────────────────────────────
DNS A-records                                  (leest dns_names als SANs)
DNS PTR-record                                 (maakt IP SAN validatie mogelijk)
Dummy hosts                                    (nodig voor service principals)
Service principals                             (nodig voor managedBy)
managedBy permissies                       ->  service-add-host (per host)
Privilege + role voor certadmin                (maakt service-add-host mogelijk)
```

Beide gebruiken dezelfde `freeipa_vip_records` variabelen structuur.
