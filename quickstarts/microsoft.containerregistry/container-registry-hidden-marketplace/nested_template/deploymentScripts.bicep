@description('Location of all resources to be deployed')
param location string = resourceGroup().location

@description('Custom Script to execute')
param installScriptUri string

@description('Random Value for Caching')
param utcValue string = utcNow()

param publisher string = 'microsoftcorporation1590077852919'
param offer string = 'horde-storage-container-preview'
param plan string = 'storage-container-test'

var identityName = 'scratch${uniqueString(resourceGroup().id)}'
var roleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var roleAssignmentName = guid(identityName, roleDefinitionId)
var config_guid = guid(resourceGroup().id)

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource identityRoleAssignDeployment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name: roleAssignmentName
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource customScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'customScript'
  location: location
  dependsOn: [
    identityRoleAssignDeployment
  ]
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'dsId')}': {
      }
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.10.1'
    timeout: 'PT30M'
    environmentVariables:  [
      {
        name: 'RESOURCEGROUP'
        secureValue: resourceGroup().name
      }
      {
        name: 'SUBSCRIPTION_ID'
        secureValue: subscription().subscriptionId
      }
      {
        name: 'PUBLISHER'
        secureValue: publisher
      }
      {
        name: 'OFFER'
        secureValue: offer
      }
      {
        name: 'PLAN'
        secureValue: plan
      }
      {
        name: 'CONFIG_GUID'
        secureValue: config_guid
      }    
    ]
    primaryScriptUri: installScriptUri
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
  }
}