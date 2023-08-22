targetScope = 'resourceGroup'
// Parameters
@description('Azure location to which the resources are to be deployed')
param location string

@description('Required. The naming module for facilitating naming convention.')
param naming object

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

var resourceNames = {
  keyVault: naming.keyVault.nameUnique
  storage: naming.storageAccount.nameUnique
  serviceBusNamespace: naming.serviceBusNamespace.name
  applicationInsights: naming.applicationInsights.name
  logAnalyticsWorkspace: naming.logAnalyticsWorkspace.name
}

module appInsights './appInsights.bicep' = {
  name: 'appInsights-Deployment'
  params: {
    location: location
    name: resourceNames.applicationInsights
    logAnalyticsWorkspaceName: resourceNames.logAnalyticsWorkspace
    tags: tags
  }
}

module storageModule './storage.bicep' = {
  name: 'storage-Deployment'
  params: {
    location: location
    name: resourceNames.storage
    tags: tags
  }
}

module keyVaultModule './keyVault.bicep' = {
  name: 'keyvault-Deployment'
  params: {
    location: location
    name: resourceNames.keyVault
    tags: tags
  }
}

module serviceBusNamespace './serviceBus.bicep' = {
  name: 'serviceBus-Deployment'
  params: {
    location: location
    name: resourceNames.keyVault
    tags: tags
  }
}

output storageAccountName string = storageModule.outputs.storageAccountName
output logAnalyticsWorkspaceName string = appInsights.outputs.logAnalyticsWorkspaceName
output appInsightsConnectionString string = appInsights.outputs.appInsightsConnectionString
output appInsightsName string = appInsights.outputs.appInsightsName
output appInsightsId string = appInsights.outputs.appInsightsId
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey
output keyVaultName string = keyVaultModule.outputs.keyVaultName
output serviceBusNamespace string = serviceBusNamespace.outputs.serviceBusNamespaceName
