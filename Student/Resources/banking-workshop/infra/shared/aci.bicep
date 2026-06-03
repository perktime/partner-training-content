@description('Name of the container group.')
param name string

@description('Location for the container group.')
param location string = resourceGroup().location

@description('Tags applied to the container group.')
param tags object = {}

@description('DNS name label that becomes <label>.<region>.azurecontainer.io')
param dnsNameLabel string

@description('Login server of the Azure Container Registry, e.g. myacr.azurecr.io')
param acrLoginServer string

@description('Resource ID of the user-assigned managed identity used for ACR pull and Azure auth.')
param userAssignedIdentityId string

@description('Client ID of the user-assigned managed identity. Surfaced to the container so DefaultAzureCredential picks the right identity.')
param userAssignedIdentityClientId string

@description('Fully qualified frontend image, e.g. myacr.azurecr.io/banking-frontend:latest')
param frontendImage string

@description('Fully qualified backend image, e.g. myacr.azurecr.io/banking-backend:latest')
param backendImage string

param cosmosDbEndpoint string
param azureOpenAiEndpoint string
param azureOpenAiCompletionsDeploymentId string
param azureOpenAiEmbeddingDeploymentId string

resource group 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    imageRegistryCredentials: [
      {
        server: acrLoginServer
        identity: userAssignedIdentityId
      }
    ]
    ipAddress: {
      type: 'Public'
      dnsNameLabel: dnsNameLabel
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
    }
    containers: [
      {
        name: 'frontend'
        properties: {
          image: frontendImage
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
        }
      }
      {
        name: 'backend'
        properties: {
          image: backendImage
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 4
            }
          }
          ports: [
            {
              port: 8080
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'PYTHONUNBUFFERED'
              value: '1'
            }
            {
              name: 'COSMOSDB_ENDPOINT'
              value: cosmosDbEndpoint
            }
            {
              name: 'AZURE_OPENAI_ENDPOINT'
              value: azureOpenAiEndpoint
            }
            {
              name: 'AZURE_OPENAI_COMPLETIONSDEPLOYMENTID'
              value: azureOpenAiCompletionsDeploymentId
            }
            {
              name: 'AZURE_OPENAI_EMBEDDINGDEPLOYMENTID'
              value: azureOpenAiEmbeddingDeploymentId
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: userAssignedIdentityClientId
            }
          ]
        }
      }
    ]
  }
}

output fqdn string = group.properties.ipAddress.fqdn
output ip string = group.properties.ipAddress.ip
output url string = 'http://${group.properties.ipAddress.fqdn}'
