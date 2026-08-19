# Vendor Modules

This directory contains vendored copies of reusable Terraform modules originally from the atg-ops-appserver repository.

## ⚠️ IMPORTANT: Configuration Required

**These modules contain placeholder values that MUST be updated before use.**

See [CONFIGURATION.md](./CONFIGURATION.md) for detailed setup instructions.

## Why Vendored?

These modules are copied locally to make this template repository **self-contained** and usable by anyone without requiring access to the private `atg-ops-appserver` repository.

## Modules Included

- **constants** - Environment constants and default values (⚠️ Update domain names)
- **ecr** - Amazon ECR repository configuration
- **ecs-app** - ECS service, task definition, ALB integration
- **network-data** - VPC and networking data sources (⚠️ Update VPC/subnet IDs)
- **route53** - DNS record management

## Quick Start

1. **Read the configuration guide:**
   ```bash
   cat CONFIGURATION.md
   ```

2. **Update network configuration:**
   ```bash
   # Edit with your AWS VPC and subnet IDs
   nano network-data/variables.tf
   ```

3. **Update domain configuration:**
   ```bash
   # Edit with your organization's domain
   nano constants/main.tf
   ```

4. **Test your configuration:**
   ```bash
   cd ../../environments/dev
   terraform init
   terraform plan
   ```

## Source

Originally sourced from: atg-ops-appserver repository

Copied and sanitized on: 2026-08-18

## Updates

These modules are **static copies**. If you need updates from the upstream repository:

1. Clone the source repository
2. Copy updated modules to this directory
3. Test thoroughly before committing

## Customization

Feel free to modify these modules to suit your needs. They are no longer tied to the upstream repository.

## Security Notice

**All sensitive infrastructure IDs have been replaced with placeholders.** This ensures the template can be safely shared publicly without exposing internal network topology.
