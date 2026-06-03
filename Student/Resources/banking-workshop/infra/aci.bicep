targetScope = 'resourceGroup'

@description('Environment name (must match the azd environment used for provisioning).')
param environmentName string

@description('Location for the container group.')
param location string = resourceGroup().location

@description('Login server of the Azure Container Registry created by main.bicep.')
param acrLoginServer string

@description('Name of the user-assigned managed identity created by main.bicep.')
param identityName string

@description('Frontend image tag (defaults to :latest).')
param frontendImageTag string = 'latest'

@description('Backend image tag (defaults to :latest).')
param backendImageTag string = 'latest'

param cosmosDbEndpoint string
param azureOpenAiEndpoint string
param azureOpenAiCompletionsDeploymentId string
param azureOpenAiEmbeddingDeploymentId string

var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))
var dnsLabel = 'banking-${resourceToken}'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

module aci './shared/aci.bicep' = {
  name: 'banking-aci'
  params: {
    name: 'ci-banking-${resourceToken}'
    location: location
    tags: {
      'azd-env-name': environmentName
    }
    dnsNameLabel: dnsLabel
    acrLoginServer: acrLoginServer
    userAssignedIdentityId: identity.id
    userAssignedIdentityClientId: identity.properties.clientId
    frontendImage: '${acrLoginServer}/banking-frontend:${frontendImageTag}'
    backendImage: '${acrLoginServer}/banking-backend:${backendImageTag}'
    cosmosDbEndpoint: cosmosDbEndpoint
    azureOpenAiEndpoint: azureOpenAiEndpoint
    azureOpenAiCompletionsDeploymentId: azureOpenAiCompletionsDeploymentId
    azureOpenAiEmbeddingDeploymentId: azureOpenAiEmbeddingDeploymentId
  }
}

output APP_URL string = aci.outputs.url
output APP_FQDN string = aci.outputs.fqdn
