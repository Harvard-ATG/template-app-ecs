# Vendor Modules

This directory contains vendored copies of reusable Terraform modules originally from the [Harvard-ATG/atg-ops-appserver](https://github.com/Harvard-ATG/atg-ops-appserver) repository.

## Why Vendored?

These modules are copied locally to make this template repository **self-contained** and usable by anyone without requiring access to the private `atg-ops-appserver` repository.

## Modules Included

- **constants** - Environment constants and default values
- **ecr** - Amazon ECR repository configuration
- **ecs-app** - ECS service, task definition, ALB integration
- **network-data** - VPC and networking data sources
- **route53** - DNS record management

## Source

Originally sourced from: `git::https://github.com/Harvard-ATG/atg-ops-appserver.git//terraform/modules/reusable/*?ref=main`

Copied on: 2026-08-18

## Updates

These modules are **static copies**. If you need updates from the upstream repository:

1. Clone the source repository
2. Copy updated modules to this directory
3. Test thoroughly before committing

## Customization

Feel free to modify these modules to suit your needs. They are no longer tied to the upstream repository.
