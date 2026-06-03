#!/usr/bin/env bash
#
# Build the backend + frontend images in Azure Container Registry and deploy
# them to a single Azure Container Instances container group.
#
# Prerequisites:
#   * azd up (or azd provision) has already created the resource group,
#     Azure Cosmos DB, Azure OpenAI, ACR, and the user-assigned managed identity.
#   * The AZD environment is selected (azd env select <name>) or AZURE_ENV_NAME
#     is exported.
#
# Run from: Student/Resources/banking-workshop/infra
#   ./deploy-app.sh
#
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
repo_root="$(cd -- "${script_dir}/.." &>/dev/null && pwd)"

# --- Read configuration from azd ---
echo "Reading deployment configuration from azd..."
eval "$(azd env get-values | grep -E '^(AZURE_ENV_NAME|AZURE_LOCATION|RG_NAME|ACR_NAME|ACR_LOGIN_SERVER|AZURE_IDENTITY_NAME|COSMOSDB_ENDPOINT|AZURE_OPENAI_ENDPOINT|AZURE_OPENAI_COMPLETIONSDEPLOYMENTID|AZURE_OPENAI_EMBEDDINGDEPLOYMENTID)=')"

for var in AZURE_ENV_NAME AZURE_LOCATION RG_NAME ACR_NAME ACR_LOGIN_SERVER AZURE_IDENTITY_NAME COSMOSDB_ENDPOINT AZURE_OPENAI_ENDPOINT AZURE_OPENAI_COMPLETIONSDEPLOYMENTID AZURE_OPENAI_EMBEDDINGDEPLOYMENTID; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: $var is not set. Run 'azd provision' first." >&2
    exit 1
  fi
done

image_tag="${IMAGE_TAG:-$(date +%Y%m%d-%H%M%S)}"

echo "  Resource group : $RG_NAME"
echo "  ACR            : $ACR_LOGIN_SERVER"
echo "  Image tag      : $image_tag"
echo ""

# --- Build backend image ---
echo "Building backend image in ACR..."
az acr build \
  --registry "$ACR_NAME" \
  --image "banking-backend:${image_tag}" \
  --image "banking-backend:latest" \
  --file "${repo_root}/backend/Dockerfile" \
  "${repo_root}/backend"

# --- Build frontend image ---
echo "Building frontend image in ACR..."
az acr build \
  --registry "$ACR_NAME" \
  --image "banking-frontend:${image_tag}" \
  --image "banking-frontend:latest" \
  --file "${repo_root}/frontend/Dockerfile" \
  "${repo_root}/frontend"

# --- Deploy the ACI container group ---
echo "Deploying ACI container group..."
deployment_output=$(az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file "${script_dir}/aci.bicep" \
  --parameters \
      environmentName="$AZURE_ENV_NAME" \
      location="$AZURE_LOCATION" \
      acrLoginServer="$ACR_LOGIN_SERVER" \
      identityName="$AZURE_IDENTITY_NAME" \
      frontendImageTag="$image_tag" \
      backendImageTag="$image_tag" \
      cosmosDbEndpoint="$COSMOSDB_ENDPOINT" \
      azureOpenAiEndpoint="$AZURE_OPENAI_ENDPOINT" \
      azureOpenAiCompletionsDeploymentId="$AZURE_OPENAI_COMPLETIONSDEPLOYMENTID" \
      azureOpenAiEmbeddingDeploymentId="$AZURE_OPENAI_EMBEDDINGDEPLOYMENTID" \
  --query "properties.outputs" \
  --output json)

app_url=$(echo "$deployment_output" | jq -r 'to_entries[] | select(.key | ascii_downcase == "app_url") | .value.value')
app_fqdn=$(echo "$deployment_output" | jq -r 'to_entries[] | select(.key | ascii_downcase == "app_fqdn") | .value.value')

echo ""
echo "===== Banking app deployment summary ====="
echo "Public URL : $app_url"
echo "FQDN       : $app_fqdn"
echo "=========================================="
echo ""
echo "It can take 1-2 minutes for the containers to start and pull images."
echo "Watch container logs with:"
echo "  az container logs --resource-group $RG_NAME --name ci-banking-<token> --container-name backend --follow"
