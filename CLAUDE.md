# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GitOps-managed homelab infrastructure running on a Talos Linux Kubernetes cluster called "pitower". The project manages infrastructure as code using:
- **Talos Linux** for the Kubernetes operating system
- **Flux CD** for GitOps continuous deployment
- **Kustomize** for Kubernetes manifest management
- **SOPS** for secrets encryption
- **Renovate** for automated dependency updates

## Key Architecture

### Cluster Structure
- **Control Plane**: 3 Raspberry Pi 4 nodes (master-01 to master-03) at IPs 192.168.0.201-203
- **Workers**: 6 nodes total
  - 3 AMD-based workers (worker-01 to worker-03)
  - 1 Intel-based worker (worker-04)
  - 2 Raspberry Pi workers (worker-05 to worker-06)
- **Virtual IP**: 192.168.0.200:6443 for cluster API endpoint

### Directory Structure
- `/kubernetes/pitower/` - Main Kubernetes cluster manifests
  - `/apps/` - Application deployments organized by namespace
  - `/flux/` - Flux CD configuration
  - `/talos/` - Talos configuration and patches
  - `/bootstrap/` - Cluster bootstrap secrets
- `/terraform/` - AWS infrastructure for state backend and IAM roles

## Common Commands

### Talos Management
```bash
# Generate cluster configuration
task talos:config

# Apply configuration patches
task talos:patch

# Bootstrap the cluster
task talos:bootstrap

# Apply configurations to nodes
task talos:apply:controlplanes
task talos:apply:workers

# Upgrade nodes
task talos:controlplanes:upgrade
task talos:workers:upgrade:amd
task talos:workers:upgrade:intel
task talos:workers:upgrade:raspberrypi
```

### Kubernetes/Flux Operations
```bash
# Bootstrap Flux
task kubernetes:bootstrap

# Check pre-commit hooks
task pre-commit:check

# Encrypt secrets with SOPS
task secret:encrypt

# Apply Talos addons
just addons  # or task talos:addons
```

### Development Workflow
1. All secrets must be encrypted with SOPS before committing
2. Use pre-commit hooks to validate changes: `task pre-commit:check`
3. Renovate automatically creates PRs for dependency updates
4. Flux watches the main branch and auto-deploys changes

## Important Patterns

### Adding New Applications
1. Create a new directory under `/kubernetes/pitower/apps/<namespace>/<app-name>/`
2. Include:
   - `ks.yaml` - Kustomization for Flux
   - `app/` directory with Kubernetes manifests
   - `kustomization.yaml` files for resource management

### Secrets Management
- Secrets use SOPS encryption with age keys
- External secrets are managed via 1Password Connect
- Pattern: `*.sops.yaml` files contain encrypted secrets
- Use `externalsecret.yaml` for 1Password-backed secrets

### Helm Releases
- Managed via Flux HelmRelease CRDs
- Helm repositories defined in `/kubernetes/pitower/flux/repositories/helm/`
- Values can be inline or in separate files

### Network Architecture
- Currently flat network (see NETWORK.md)
- Cilium CNI with L2 announcements
- Cloudflare tunnels for external access
- Nginx ingress controllers (internal/external)

## Key Technologies per Namespace
- **cert-manager**: SSL certificate management
- **rook-ceph**: Distributed storage
- **monitoring**: Prometheus, Grafana, Loki stack
- **security**: Authelia, LLDAP, 1Password Connect
- **networking**: External DNS, Cloudflared, Tailscale
- **media**: Plex, Jellyfin, *arr stack
- **home-automation**: Home Assistant, Zigbee2MQTT