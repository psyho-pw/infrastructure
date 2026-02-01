# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository manages infrastructure as code for a 5-server deployment using Ansible. All services run as Docker containers orchestrated by Docker Compose, with Traefik as the reverse proxy handling routing, SSL/TLS termination, and TCP routing.

## Architecture

### Server Layout

- **DB Server**: PostgreSQL, MariaDB (TLS passthrough), Redis - all exposed via Traefik TCP routing
- **Jenkins Server**: Jenkins CI/CD with agent ports
- **Pi Server**: Kafka cluster (KRaft mode), Squid proxy, n8n, Claude Code monitor
- **Production Server**: Production applications
- **Test Server**: Monitoring stack (Prometheus, Loki, Grafana)

All servers use Traefik for reverse proxy with automatic Let's Encrypt SSL certificates.

### Key Design Patterns

**Ansible Vault Security**: Sensitive data stored in `host_vars/*/vault.yml` files encrypted with Ansible Vault. Non-sensitive config in `host_vars/*/vars.yml`. Vault password in `.vault_pass` (gitignored). All Ansible commands automatically use vault password file via `ansible.cfg`.

**Base Directory Convention**: All services deploy to `~/server/{service-name}/` on each host. The `base_dir` variable in `inventory/group_vars/all.yml` controls this. Each service gets its own directory with `docker-compose.yml`, `.env`, and service-specific config files.

**Network Architecture**: All Docker services use a shared `proxy` network created by the docker role. Traefik connects to this network to route traffic to containers. Services can also have internal networks for inter-service communication.

**Role-Based Organization**: Ansible roles follow a standard structure:

- `tasks/main.yml`: Main task execution
- `templates/`: Jinja2 templates for docker-compose.yml, .env files, config files
- `handlers/main.yml`: Service restart handlers
- `defaults/main.yml`: Default variables (overridden by host_vars)

## Common Commands

### Initial Setup

```bash
# Install Ansible collections (first time only)
make install

# Test connectivity to all servers
make check
```

### Deployment

```bash
# Deploy entire infrastructure to all servers
make deploy-all

# Deploy individual servers
make deploy-pi      # Pi server only
make deploy-db      # DB server only
make deploy-jenkins # Jenkins server only
make deploy-test    # Test server only

# Deploy specific roles across appropriate hosts
make deploy-docker   # Install Docker on all hosts
make deploy-traefik  # Deploy Traefik on all hosts
```

### Dry Run (Check Mode)

```bash
# Preview changes without applying
make dry-run           # All infrastructure
make dry-run-pi        # Pi server only
make dry-run-db        # DB server only
make dry-run-jenkins   # Jenkins server only
make dry-run-test      # Test server only
```

### Direct Ansible Playbook Usage

```bash
# Run specific playbook with tags
ansible-playbook playbooks/pi.yml --tags kafka
ansible-playbook playbooks/db.yml --tags postgresql

# Use generic deploy target
make deploy TARGET=pi
make deploy TARGET=all DRY_RUN=true
```

### Ansible Vault Management

```bash
# Decrypt vault file (requires HOST variable)
make vault-decrypt HOST=pi-server
make vault-decrypt HOST=production  # For inventory file

# Encrypt vault file
make vault-encrypt HOST=pi-server

# Edit vault file (decrypts automatically)
ansible-vault edit inventory/host_vars/pi-server/vault.yml

# View vault file contents
ansible-vault view inventory/host_vars/pi-server/vault.yml
```

### Troubleshooting

```bash
# Check Docker container status on all servers
make docker-ps

# View container logs (requires HOST and SERVICE)
make docker-logs HOST=pi SERVICE=kafka
make docker-logs HOST=db SERVICE=postgres

# Check host variables for debugging
ansible-inventory -i inventory/production --host pi-server

# Test SSH connectivity with verbose output
ansible all -i inventory/production -m ping -vvv
```

### Code Quality

```bash
# Run ansible-lint with auto-fix
make lint

# Install git pre-commit hooks
make install-hooks
```

### Cleanup

```bash
# Remove Ansible log files
make clean
```

## Development Workflow

### Making Configuration Changes

1. Edit variables in `inventory/host_vars/{server}/vars.yml` for non-sensitive config
2. For secrets, use: `ansible-vault edit inventory/host_vars/{server}/vault.yml`
3. Run dry-run to preview changes: `make dry-run-{server}`
4. Deploy: `make deploy-{server}`

### Adding a New Service

1. Create new role in `roles/{service-name}/`
2. Add `tasks/main.yml`, `templates/compose.yml.j2`, `templates/{service}.env.j2`
3. Define service variables in appropriate `host_vars/{server}/vars.yml`
4. Add role to corresponding playbook in `playbooks/{server}.yml`
5. Test with dry-run before deployment

### Inventory Structure

Inventory file (`inventory/production`) is encrypted with Ansible Vault and contains:

- Host definitions with ansible_host, ansible_user, ansible_ssh_private_key_file
- Group definitions: [db], [jenkins], [pi], [production], [test]
- Meta groups: [docker_hosts], [traefik_hosts]

### Template Variables

Templates use Jinja2 syntax. Common variable sources:

- `inventory/group_vars/all.yml`: Global defaults
- `inventory/group_vars/{group}.yml`: Group-specific variables
- `inventory/host_vars/{host}/vars.yml`: Host-specific non-sensitive variables
- `inventory/host_vars/{host}/vault.yml`: Host-specific sensitive variables (encrypted)

Variables are merged with precedence: host_vars > group_vars > all.yml > role defaults.

## Special Considerations

### Traefik Configuration

Traefik handles multiple routing patterns:

- **HTTP/HTTPS**: Standard web services with automatic SSL termination
- **TCP Routing**: For services like Kafka (9092), PostgreSQL (5432), Redis (6379), Squid (8080)
- **TLS Passthrough**: MariaDB (3306) uses TLS passthrough - Traefik routes encrypted traffic without termination

Service labels in docker-compose templates control Traefik routing. Check existing templates for examples.

### Kafka Cluster

Pi server runs Kafka in KRaft mode (no Zookeeper). Key details:

- Cluster ID must be generated once: `kafka-storage random-uuid`
- SASL/SCRAM authentication configured via init script
- External access via Traefik TCP routing on port 9092
- Kafka UI included for monitoring

### Monitoring Stack

Test server runs Prometheus, Loki, Grafana. Other services should:

- Expose Prometheus metrics endpoints where applicable
- Send logs in a format Loki can scrape
- Use labels for proper metric/log organization

### SSH Key Management

Each server may use different SSH keys specified in the inventory file via `ansible_ssh_private_key_file`. Ensure keys are properly configured before running playbooks.

## Pre-Commit Hook

When installed via `make install-hooks`, the pre-commit hook:

- Runs `ansible-lint --fix` on staged files
- Blocks commits if linting fails
- Auto-stages fixed files
- Can be bypassed with `git commit --no-verify` if needed

## File Organization

```txt
infrastructure/
├── ansible.cfg              # Ansible configuration (vault_password_file, logging)
├── inventory/
│   ├── production           # Encrypted inventory file
│   ├── group_vars/          # Variables by group
│   └── host_vars/           # Variables by host (vars.yml + vault.yml)
├── playbooks/
│   ├── pi.yml               # Pi server deployment
│   ├── db.yml               # DB server deployment
│   ├── production.yml       # Production server deployment
│   └── test.yml             # Test server deployment
├── roles/                   # Ansible roles (one per service)
│   ├── common/              # Base system setup
│   ├── docker/              # Docker installation
│   ├── traefik/             # Traefik reverse proxy
│   ├── kafka/               # Kafka cluster
│   ├── postgresql/          # PostgreSQL database
│   └── .../                 # Other service roles
└── Makefile                 # Command shortcuts
```
