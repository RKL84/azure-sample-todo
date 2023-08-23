targetScope = 'resourceGroup'

@description('Required. Azure location to which the resources are to be deployed')
param location string

@description('Required. The naming module for facilitating naming convention.')
param naming object

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

param logAnalyticsWorkspaceName string
param appInsightsName string
param storageAccountName string
param appServicePlanName string
param sharedResourceGroupName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(sharedResourceGroupName)
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup(sharedResourceGroupName)
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: appServicePlanName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
  scope: resourceGroup(sharedResourceGroupName)
}

var placeholder = '***'
var funcNameWithPlaceholder = replace(naming.functionApp.name, '${naming.functionApp.slug}-', '${naming.functionApp.slug}-${placeholder}-')
var todoFunctionAppName = replace(funcNameWithPlaceholder, placeholder, 'todo')

resource todoFunctionApp 'Microsoft.Web/sites@2018-11-01' = {
  name: todoFunctionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  properties: {
    // enabled: true
    // hostNameSslStates: [
    //   {
    //     name: sites_funcappAPIMCSBackendMicroServiceA_siteHostname
    //     sslState: 'Disabled'
    //     hostType: 'Standard'
    //   }
    //   {
    //     name: sites_funcappAPIMCSBackendMicroServiceA_repositoryHostname
    //     sslState: 'Disabled'
    //     hostType: 'Repository'
    //   }
    // ]
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      numberOfWorkers: 1
      netFrameworkVersion: 'v6.0'
      // alwaysOn: true
      http20Enabled: false
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        // {
        //   name: 'WEBSITE_CONTENTOVERVNET'
        //   value: '1'
        // }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(todoFunctionAppName)
        }
        // {
        //   name: 'WEBSITE_VNET_ROUTE_ALL'
        //   value: '1'
        // }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
  }
  dependsOn: []
}

// resource todoFunctionApp 'Microsoft.Web/sites@2021-02-01' = {
//   name: todoFunctionAppName
//   location: location
//   kind: 'functionapp'
//   identity: {
//     type: 'SystemAssigned'
//     // userAssignedIdentities: {
//     //   '${managedIdentity.id}': {}
//     // }
//   }
//   tags: tags
//   properties: {
//     serverFarmId: appServicePlan.id
//     // keyVaultReferenceIdentity: managedIdentity.id
//     // httpsOnly: true
//     // virtualNetworkSubnetId: appServiceSubnet.id
//     siteConfig: {
//       powerShellVersion: '7.2'
//       appSettings: [
//         {
//           name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
//           value: appInsights.properties.InstrumentationKey
//         }
//         {
//           name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
//           value: appInsights.properties.ConnectionString
//         }
//         {
//           name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
//           value: '~3'
//         }
//         {
//           name: 'XDT_MicrosoftApplicationInsights_Mode'
//           value: 'Recommended'
//         }
//         // {
//         //   name: 'ServiceBusConnection__fullyQualifiedNamespace'
//         //   value: '${serviceBusNamespace.name}.servicebus.windows.net'
//         // }
//         {
//           name: 'ServiceBusConnection__credential'
//           value: 'managedIdentity'
//         }
//         // {
//         //   name: 'ServiceBusConnection__clientId'
//         //   value: managedIdentity.properties.clientId
//         // }
//         // {
//         //   name: 'AzureAdClientId'
//         //   value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${functionAADServicePrincipalClientIdSecretName})'
//         // }
//         // {
//         //   name: 'AzureAdClientSecret'
//         //   value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${functionAADServicePrincipalClientSecretSecretName})'
//         // }
//         {
//           name: 'AzureAdTenantId'
//           value: subscription().tenantId
//         }
//         {
//           name: 'AzureWebJobsStorage'
//           value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
//         }
//         {
//           name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
//           value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
//         }
//         {
//           name: 'WEBSITE_CONTENTSHARE'
//           value: toLower(todoFunctionAppName)
//         }
//         {
//           name: 'FUNCTIONS_EXTENSION_VERSION'
//           value: '~4'
//         }
//         {
//           name: 'FUNCTIONS_WORKER_RUNTIME'
//           value: 'powershell'
//         }
//         {
//           name: 'WEBSITE_RUN_FROM_PACKAGE'
//           value: '1'
//         }
//       ]
//     }
//   }
// }

resource todoAppDiagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  name: 'Logging'
  scope: todoFunctionApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
