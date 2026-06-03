
param cosmosDbAccountName string
param identityName string
param openAIName string
param acrName string

@description('Id of the user principals to assign database and application roles.')    
param userPrincipalId string = '' 


resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: openAIName
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: cosmosDbAccountName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// Role Assignment for AcrPull to UAMI (so ACI can pull images using the managed identity)
resource acrPullRoleAssignmentUAMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, acr.id, 'acr-pull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


// Role Assignment for Cognitive Services User to UAMI
resource cognitiveServicesRoleAssignmentUAMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, openAi.id, 'cognitive-services-user')  // Unique GUID for role assignment
  scope: openAi
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')  // Cognitive Services User Role ID
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment for Cognitive Services User to Current User
resource cognitiveServicesRoleAssignmentCU 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userPrincipalId, openAi.id, 'cognitive-services-user')  // Unique GUID for role assignment
  scope: openAi
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')  // Cognitive Services User Role ID
    principalId: userPrincipalId
    principalType: 'User'
  }
}


// Role Assignment for Cosmos DB role to managed identity
resource cosmosAccessRoleUAMI 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-11-15' = {
  name: guid('00000000-0000-0000-0000-000000000002', identity.id, cosmosDb.id)
  parent: cosmosDb
  properties: {
    principalId: identity.properties.principalId
    roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDb.name, '00000000-0000-0000-0000-000000000002')
    scope: cosmosDb.id
  }
}


// Role Assignment for Cosmos DB role to current user
resource cosmosAccessRoleCU 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-11-15' = {
  name: guid('00000000-0000-0000-0000-000000000002', userPrincipalId, cosmosDb.id)
  parent: cosmosDb
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDb.name, '00000000-0000-0000-0000-000000000002')
    scope: cosmosDb.id
  }
}

output identityId string = identity.properties.principalId
output identityName string = identity.name
