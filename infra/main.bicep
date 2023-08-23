targetScope = 'subscription'

// Parameters
@description('A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param appName string

@description('Optional. A numeric suffix (e.g. "001") to be appended on the naming generated for the resources. Defaults to empty.')
param numericSuffix string = ''

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'qa'
  'prd'
])
param environment string

param location string = deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// @description('Flag to use Azure API Management to mediate the calls between the Web frontend and the backend API')
// param useAPIM bool = false

// @description('Id of the user or app to assign application roles')
// param principalId string = ''

var defaultTags = union({
    application: appName
    environment: environment
  }, tags)

var resourceSuffix = '${appName}-${environment}'
var networkingResourceGroupName = 'rg-networking-${resourceSuffix}'
var sharedResourceGroupName = 'rg-shared-${resourceSuffix}'
var backendResourceGroupName = 'rg-backend-${resourceSuffix}'
var apimResourceGroupName = 'rg-apim-${resourceSuffix}'

var defaultSuffixes = [
  appName
  environment
  // '**location**'
]
var namingSuffixes = empty(numericSuffix) ? defaultSuffixes : concat(defaultSuffixes, [
    numericSuffix
  ])

module naming 'modules/naming.module.bicep' = {
  scope: resourceGroup(sharedRG.name)
  name: 'namingModule-Deployment'
  params: {
    location: location
    suffix: namingSuffixes
    uniqueLength: 6
  }
}

resource networkingRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingResourceGroupName
  location: location
  tags: defaultTags
}

resource backendRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: backendResourceGroupName
  location: location
  tags: defaultTags
}

resource sharedRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: sharedResourceGroupName
  location: location
  tags: defaultTags
}

resource apimRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: apimResourceGroupName
  location: location
  tags: defaultTags
}

module networking './networking.bicep' = {
  name: 'networkingresources'
  scope: resourceGroup(networkingRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
  }
}

module shared './shared/shared.bicep' = {
  name: 'sharedresources-Deployment'
  scope: resourceGroup(sharedRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
  }
}

module appServicePlan './asp.bicep' = {
  name: 'appservicePlan-Deployment'
  scope: resourceGroup(backendRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
  }
}

module api './app/api.bicep' = {
  name: 'api'
  scope: resourceGroup(backendRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
    applicationInsightsName: shared.outputs.appInsightsName
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    keyVaultName: shared.outputs.keyVaultName
    // allowedOrigins: [ web.outputs.SERVICE_WEB_URI ]
    // appSettings: {
    //   AZURE_SQL_CONNECTION_STRING_KEY: sqlServer.outputs.connectionStringKey
    // }
  }
}

// Give the API access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: resourceGroup(sharedRG.name)
  params: {
    keyVaultName: shared.outputs.keyVaultName
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

// module apim './apim.bicep' = {
//   name: 'appservicePlan-Deployment'
//   scope: resourceGroup(apimRG.name)
//   params: {
//     location: location
//     naming: naming.outputs.names
//     tags: defaultTags
//     appInsightsName: shared.outputs.appInsightsName
//     appInsightsId: shared.outputs.appInsightsId
//     appInsightsInstrumentationKey: shared.outputs.appInsightsInstrumentationKey
//   }
// }

// module backend './backend.bicep' = {
//   name: 'backend-Deployment'
//   scope: resourceGroup(backendRG.name)
//   params: {
//     location: location
//     naming: naming.outputs.names
//     tags: defaultTags
//     logAnalyticsWorkspaceName: shared.outputs.logAnalyticsWorkspaceName
//     appInsightsName: shared.outputs.appInsightsName
//     appServicePlanName: appServicePlan.outputs.appServicePlanName
//     storageAccountName: shared.outputs.storageAccountName
//     sharedResourceGroupName: sharedResourceGroupName
//   }
// }
