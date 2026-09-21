#!/usr/bin/env bash
# Tears down the mdbtest environment (terraform/envs/mdbtest): AKS cluster,
# ACR, Key Vault and the managed PostgreSQL Flexible Server. Mirrors exactly
# what the "[mdbtest] Terraform — Test Infrastructure" GitHub Actions workflow
# runs for action=destroy — this is the same operation, run locally.
#
# The shared resource group AZET-RG-Daas-Platform is only ever read
# (create_resource_group = false in mdbtest.tfvars), so this cannot remove it
# or anything dev owns — Terraform state for this environment is a separate
# blob (mdbtest.terraform.tfstate).
#
# Usage:
#   ./destroy.sh <subscription-id>
# or export TF_VAR_subscription_id beforehand and run with no arguments.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ "${1:-}" != "" ]; then
  export TF_VAR_subscription_id="$1"
fi

if [ "${TF_VAR_subscription_id:-}" = "" ]; then
  echo "Error: no subscription id given." >&2
  echo "Usage: ./destroy.sh <subscription-id>   (or export TF_VAR_subscription_id first)" >&2
  exit 1
fi

echo "== terraform init =="
terraform init -input=false

echo
echo "== terraform plan -destroy =="
terraform plan -destroy -input=false -var-file=mdbtest.tfvars -out=tfplan-destroy

echo
echo "The plan above will PERMANENTLY delete every resource it lists —"
echo "including the managed Postgres server and all data in it."
echo "AZET-RG-Daas-Platform itself is only read and will not be touched."
echo
read -r -p "Type 'destroy mdbtest' to proceed: " confirm

if [ "$confirm" != "destroy mdbtest" ]; then
  echo "Aborted. Nothing was destroyed."
  rm -f tfplan-destroy
  exit 1
fi

echo
echo "== terraform apply (destroy plan) =="
terraform apply -input=false tfplan-destroy

rm -f tfplan-destroy
