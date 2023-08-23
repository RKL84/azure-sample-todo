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

module networking './app/networking.bicep' = {
  name: 'networkingResources-Deployment'
  scope: resourceGroup(networkingRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
  }
}

module shared './shared/shared.bicep' = {
  name: 'sharedResources-Deployment'
  scope: resourceGroup(sharedRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
  }
}

module appServicePlan './app/asp.bicep' = {
  name: 'appservicePlan-Deployment'
  scope: resourceGroup(backendRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
  }
}

// module apim './app/apim.bicep' = {
//   name: 'apim-Deployment'
//   scope: resourceGroup(apimRG.name)
//   params: {
//     location: location
//     naming: naming.outputs.names
//     tags: defaultTags
//     appInsightsName: shared.outputs.appInsightsName
//   }
// }

module api './app/api.bicep' = {
  name: 'apim-Deployment'
  scope: resourceGroup(backendRG.name)
  params: {
    location: location
    naming: naming.outputs.names
    tags: defaultTags
    sharedResourceGroupName: sharedResourceGroupName
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

// // Configures the API in the Azure API Management (APIM) service
// module apimApi './app/apim-api.bicep' = if (useAPIM) {
//   name: 'apim-api-deployment'
//   scope: rg
//   params: {
//     name: useAPIM ? apim.outputs.apimServiceName : ''
//     apiName: 'todo-api'
//     apiDisplayName: 'Simple Todo API'
//     apiDescription: 'This is a simple Todo API'
//     apiPath: 'todo'
//     webFrontendUrl: web.outputs.SERVICE_WEB_URI
//     apiBackendUrl: api.outputs.SERVICE_API_URI
//     apiAppName: api.outputs.SERVICE_API_NAME
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

output APPLICATIONINSIGHTS_CONNECTION_STRING string = shared.outputs.appInsightsConnectionString
output AZURE_KEY_VAULT_ENDPOINT string = shared.outputs.keyVaultUri
output AZURE_KEY_VAULT_NAME string = shared.outputs.keyVaultName
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
