# FitCart — Azure Infrastructure

Terraform for the AKS deployment of FitCart. Provisions, in order: a resource
group, a VNet, an Azure Container Registry, a Key Vault, and an AKS cluster
joined to the VNet subnet.

```
terraform/
├── bootstrap/        one-time, local state — creates the remote state backend
├── modules/          resource-group, networking, acr, key-vault, aks
└── envs/dev/         the dev environment root; wires the modules together
```

Modules never declare providers and never hardcode names. A second environment
is a copy of `envs/dev` with a different tfvars file and state key.

## What gets created

Everything is deployed into the **existing** resource group
`AZET-RG-Daas-Platform`, set by `resource_group_name` in
[envs/dev/dev.tfvars](envs/dev/dev.tfvars).

| Resource | Name | Notes |
|---|---|---|
| Virtual network | `vnet-fitcart-dev` | `10.0.0.0/16`; `snet-aks` is `10.0.1.0/24` |
| Container registry | `acrfitcartdev<suffix>` | Basic SKU, admin user disabled |
| Key Vault | `kv-fitcart-dev-<suffix>` | RBAC mode, holds the Postgres credentials |
| AKS cluster | `aks-fitcart-dev` | 1× `Standard_D2s_v3`, Azure CNI overlay, in `snet-aks` |
| Storage account | `stfitcarttfstate<suffix>` | Terraform state, created by `bootstrap/` |
| Role assignment | `AcrPull` | AKS kubelet identity → ACR |

Resources inherit the existing group's **region** — `location` in tfvars is only
consulted when Terraform creates the group itself.

`10.0.2.0/24` is intentionally left unallocated for App Service VNet integration
in a later phase.

### The group is read, not managed

`create_resource_group = false` makes Terraform look the group up with a data
source rather than own it. Two consequences worth knowing:

- **`terraform destroy` will not delete `AZET-RG-Daas-Platform`.** It removes the
  resources this configuration created and leaves the shared group in place.
- The group must already exist, and the service principal needs rights on it.
  Terraform will fail early with a clear "not found" if it doesn't.

To have Terraform create and own a group instead, set `create_resource_group = true`
and give `resource_group_name` a new name. `destroy` would then delete it.

### It is a shared group

`AZET-RG-Daas-Platform` is the organisation's standard working group and already
contains other people's resources, including at least two other AKS clusters.
Two rules follow:

- **Never delete the group**, and never `destroy` anything you did not create.
  This configuration only touches resources it provisioned itself.
- **Names must not collide.** Everything here is prefixed `fitcart-dev`
  (`vnet-fitcart-dev`, `aks-fitcart-dev`), and ACR and Key Vault carry a random
  suffix on top. Change `project` or `environment` in tfvars if that ever clashes.

### One resource group Terraform cannot control

AKS **always** creates a second resource group for its node infrastructure — the
VM scale set, node disks, and the load balancer that fronts the frontend Service.
Azure does not allow those to live in the cluster's own resource group; there is
no setting that changes this.

`aks_node_resource_group_name` is left `null` so Azure generates
`MC_AZET-RG-Daas-Platform_aks-fitcart-dev_eastus`, matching the convention the
existing clusters in this group already follow. It is deleted automatically with
the cluster, so it needs no separate cleanup.

### Why ACR is not inside the VNet

ACR is a global PaaS service with no subnet of its own. Placing it inside the
VNet requires a Private Endpoint, which requires the **Premium** SKU. This setup
uses Basic and controls access with the `AcrPull` role assignment instead of
network position. Moving to a private endpoint later is a change to the `acr`
module plus a private DNS zone.

## First-time setup

Run once, in order.

### 1. Sign in

```bash
az login
az account set --subscription <subscription-id>
```

### 2. Create the remote state backend

This is the only Terraform that runs on local state — it creates the storage
account the rest of the configuration stores its state in, inside the same
`AZET-RG-Daas-Platform` group.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="subscription_id=<subscription-id>"
```

Copy the `storage_account_name` output into `storage_account_name` in
[envs/dev/backend.tf](envs/dev/backend.tf), replacing `REPLACE_WITH_BOOTSTRAP_OUTPUT`.
The name carries a random suffix, so it cannot be committed ahead of time.

### 3. The CI service principal

If you already have one, skip creating it and check its permissions instead:

```bash
az role assignment list --assignee <appId> --all -o table
```

Otherwise:

```bash
az ad sp create-for-rbac \
  --name sp-fitcart-github \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/AZET-RG-Daas-Platform
```

#### What the principal must be able to do

| Capability | Role that provides it | Used for |
|---|---|---|
| Create resources in the group | `Contributor` | VNet, ACR, Key Vault, AKS, storage |
| Create the AKS node resource group | `Contributor` at **subscription** scope | AKS creates its own `MC_*` group |
| Read/write Key Vault secrets | `Key Vault Secrets Officer` | the generated Postgres password |
| **Create role assignments** | `Owner` or `Role Based Access Control Administrator` | the `AcrPull` grant |

That last row is the one that trips people up. **`Contributor` cannot create role
assignments**, and the configuration needs one so AKS can pull from ACR. If your
principal is Contributor-only, have an admin run this once:

```bash
az role assignment create \
  --assignee-object-id <sp-object-id> \
  --assignee-principal-type ServicePrincipal \
  --role "Role Based Access Control Administrator" \
  --scope /subscriptions/<subscription-id>/resourceGroups/AZET-RG-Daas-Platform
```

`Role Based Access Control Administrator` is narrower than
`User Access Administrator` — it permits managing role assignments and nothing
else — so it is usually the easier approval to obtain.

#### How this environment is configured

Neither the service principal nor the operator holds more than `Contributor`, so
no role assignment can be created by any route. The configuration therefore runs
on the fallback: the ACR admin user is enabled, and the deploy workflows create a
`docker-registry` secret from it that the backend and frontend charts reference.

Three toggles in [envs/dev/dev.tfvars](envs/dev/dev.tfvars):

| Toggle | Value | Why |
|---|---|---|
| `create_key_vault_role_assignment` | `false` | the principal already holds Key Vault Secrets Officer at subscription scope; re-granting is redundant and would fail |
| `create_acr_role_assignment` | `false` | Contributor cannot create it |
| `use_image_pull_secret` | `true` | enables ACR admin so the cluster can still pull |

**This is a deliberate POC trade-off**, not the intended end state. A shared
registry password ends up stored in the cluster, and ACR admin is on. Once
someone grants `Role Based Access Control Administrator` on the resource group,
switch to `create_acr_role_assignment = true` and `use_image_pull_secret = false`,
re-apply, and delete the now-unused secret:

```bash
kubectl delete secret acr-pull-secret -n fitcart
```

The workflows detect which mode is active by querying `adminUserEnabled` on the
registry, so no workflow change is needed either way.

#### If Azure Policy blocks the ACR admin user

Governed subscriptions sometimes deny it. Check before running a full apply —
this costs about thirty seconds:

```bash
az acr create --name acrpolicytest$RANDOM --resource-group AZET-RG-Daas-Platform \
  --sku Basic --admin-enabled true
# succeeded? policy allows it. Delete the test registry:
az acr delete --name <that-name> --resource-group AZET-RG-Daas-Platform --yes
```

A policy denial there means neither the role assignment nor the admin user is
available, and the remaining options are to push images to GitHub Container
Registry instead, or to obtain the RBAC grant after all.

#### Credentials

Save four GitHub **secrets** (*Settings → Secrets and variables → Actions →
Secrets*):

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | `appId` from the output |
| `AZURE_CLIENT_SECRET` | `password` from the output |
| `AZURE_TENANT_ID` | `tenant` from the output |
| `AZURE_SUBSCRIPTION_ID` | your subscription ID |

`password` is shown once and cannot be retrieved later — copy it now. If you lose
it, reset with `az ad sp credential reset --id <appId>`.

### 4. Provision

Run the **Terraform — Azure Infrastructure** workflow with `action: apply`, or
locally:

```bash
cd terraform/envs/dev
terraform init
terraform apply -var-file=dev.tfvars -var="subscription_id=<subscription-id>"
```

### 5. Publish the outputs as repository variables

```bash
terraform output -json workflow_env
```

Set each key as a GitHub **repository variable** (*Settings → Secrets and
variables → Actions → Variables*) — the deploy workflows read them from `vars`:

- `ACR_NAME`
- `ACR_LOGIN_SERVER`
- `AKS_CLUSTER_NAME`
- `AZURE_RESOURCE_GROUP`
- `KEY_VAULT_NAME`

These are **variables**, not secrets — the four `AZURE_*` values above are the
only secrets. Getting the two categories mixed up is the most common setup
mistake: `vars.ACR_NAME` reads empty if you saved it as a secret, and `az acr
login` then fails with an unhelpful error.

## Deploying the application

Charts live in [../helm](../helm), one release per tier. Run the workflows in
this order the first time — the backend cannot start without a database:

1. **Database — Deploy**
2. **Backend — Build & Deploy**
3. **Frontend — Build & Deploy**

After that each workflow triggers independently on pushes touching its own paths.

The Postgres password is generated by Terraform, stored only in Key Vault and
state, and read back by the deploy workflows at run time. It is never a GitHub
secret and never committed.

## Tearing down

Run the Terraform workflow with `action: destroy`, or:

```bash
cd terraform/envs/dev
terraform destroy -var-file=dev.tfvars -var="subscription_id=<subscription-id>"
```

The Key Vault has `purge_protection_enabled = false` and the provider is
configured with `purge_soft_delete_on_destroy`, so the vault name is released
and a later `apply` succeeds. Turning purge protection on in a test environment
means the next apply fails on the still-reserved name.

Left running, the footprint costs roughly **$95–110/month** — most of it the
single `Standard_D2s_v3` node at about $70.

Two constraints shaped that choice, both specific to this subscription:

- **Allowed-SKU policy** blocks the cheaper B-series. The permitted
  `standard_b2ps_v2` / `standard_b2pls_v2` are ARM64, which the amd64 images
  built on GitHub runners cannot execute, so they are not an option without
  cross-building.
- **East US regional vCPU quota** had only 2 vCPU free. Each D2s_v3 consumes 2,
  so two nodes were rejected with `ErrCode_InsufficientVCPUQuota`.

One node is adequate here: the three tiers request about 350m CPU and 850Mi
total, against roughly 1.9 vCPU and 5.5Gi allocatable. The trade-off is no surge
capacity during cluster upgrades and no resilience to node loss. Raise
`node_count` once quota allows — and note the AKS module deliberately does *not*
set `ignore_changes` on it, so the change takes effect.

`AZET-RG-Daas-Platform` survives `destroy` — Terraform only reads it. The state
storage account inside it also survives, since it is owned by the separate
`bootstrap/` configuration. **Do not delete the group by hand**: it is shared,
and removing it would take the state account and anything else in it with it.

To remove the state account specifically, run `terraform destroy` in
`terraform/bootstrap` — that deletes the account and, because
`create_resource_group` is false there too, leaves the group alone.

## Conventions

- Workload names derive from `var.project` and `var.environment`, so nothing is
  hardcoded to `fitcart` or `dev`. The resource group is the exception: it is
  named explicitly because it is pre-existing and shared.
- `subscription_id` is never committed. Locally pass `-var`, in CI it comes from
  `TF_VAR_subscription_id`, set from the `AZURE_SUBSCRIPTION_ID` secret.
- Run `terraform fmt -recursive` before committing — CI fails on unformatted files.
