# FitCart v2.0 Release Request

This folder is the handoff package for the Agentic Deployment-as-a-Service POC.
It describes a realistic next release for the FitCart demo app already deployed
on AKS. ADaaS can use it as the uploaded release input, compare it with the
currently deployed Kubernetes, Helm, Terraform, Key Vault and application state,
then show the approval UI before executing the upgrade.

## Current Production Baseline

| Area | Current value |
|---|---|
| Application | FitCart v1.x, React frontend + Spring Boot backend + PostgreSQL |
| Azure resource group | `AZET-RG-Daas-Platform` |
| AKS cluster | `aks-fitcart-dev` |
| Namespace | `fitcart` |
| Frontend release | `fitcart-frontend`, LoadBalancer service `frontend:80` |
| Backend release | `fitcart-backend`, ClusterIP service `backend:8080` |
| Database release | `fitcart-database`, PostgreSQL service `postgres:5432` |
| Database | `backenddb` |
| Current Key Vault secrets | `postgres-user`, `postgres-password` |
| Current backend config | `DB_HOST`, `DB_PORT`, `DB_NAME`, `FRONTEND_ORIGIN` |
| Current Terraform node count | `1` |

## Target Release

FitCart v2.0 adds richer workout tracking, member photo support, audit logging,
notifications, safer rollout behavior and operational checks. This is a genuine
upgrade because it changes app behavior, database schema, runtime config, new
secrets, Helm values and validation expectations.

Primary changes:

- Add workout goal tracking fields to `gym_record`.
- Add member photo URL, fitness level, target calories and audit metadata.
- Enable audit mode.
- Add email/notification configuration.
- Add storage container configuration for profile and workout images.
- Increase backend replicas from `1` to `2`.
- Increase frontend replicas from `1` to `2`.
- Increase backend CPU/memory requests and limits.
- Keep AKS, ACR, VNet and Key Vault infrastructure unchanged for this release.

## Files

| File | Purpose |
|---|---|
| [release-request.yaml](./release-request.yaml) | Machine-readable request for ADaaS ingestion |
| [database/V2__fitcart_upgrade.sql](./database/V2__fitcart_upgrade.sql) | Database migration expected in the v2 package |
| [validation/smoke-tests.yaml](./validation/smoke-tests.yaml) | Validation checks ADaaS should run after deployment |
| [rollback/failure-simulation.yaml](./rollback/failure-simulation.yaml) | Demo failure and rollback scenario |
| [drift/drift-simulation.yaml](./drift/drift-simulation.yaml) | Demo drift detection scenario |

## Expected ADaaS Dashboard Summary

| Category | Expected comparison result |
|---|---|
| Application version | `v1.x` to `v2.0` |
| Configuration | `5 added`, `1 modified`, `0 removed` |
| Secrets | `3 added`, `0 updated`, `0 removed` |
| Database | Migration required |
| Storage | New logical container required |
| Infrastructure | No Terraform resource changes |
| Kubernetes | Backend and frontend replica changes |
| Risk | Medium |
| Estimated downtime | 10 to 15 minutes |
| Rollback | Available |

## Human Approval Message

Approve FitCart v2.0 deployment to namespace `fitcart`.

Affected services:

- Frontend deployment and service
- Backend deployment, config map and secret
- PostgreSQL schema
- Key Vault secrets
- Application validation checks

Rollback readiness:

- Helm revision rollback available for frontend and backend.
- Database backup required before migration.
- Existing Key Vault secret snapshot required before adding notification secrets.
- Traffic should remain paused at canary if validation fails.
