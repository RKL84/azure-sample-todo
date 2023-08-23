targetScope = 'resourceGroup'

// Parameters
@description('Required. Azure location to which the resources are to be deployed')
param location string

@description('Required. The naming module for facilitating naming convention.')
param naming object

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The email address of the publisher of the APIM resource.')
@minLength(1)
param publisherEmail string = 'apim@contoso.com'

@description('Company name of the publisher of the APIM resource.')
@minLength(1)
param publisherName string = 'Contoso'

@description('The pricing tier of the APIM resource.')
param skuName string = 'Developer'

@description('The instance size of the APIM resource.')
param capacity int = 1

param appInsightsName string

// Variables 
var resourceNames = {
  apiManagement: naming.apiManagement.name
}

module apim '../core/gateway/apim.bicep' = {
  name: 'apim-Deployment'
  params: {
    name: resourceNames.apiManagement
    location: location
    tags: tags
    applicationInsightsName: appInsightsName
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: skuName
    skuCount: capacity
  }
}

// resource apimName_resource 'Microsoft.ApiManagement/service@2020-12-01' = {
//   name: resourceNames.apiManagement
//   location: location
//   sku: {
//     capacity: capacity
//     name: skuName
//   }
//   properties: {
//     publisherEmail: publisherEmail
//     publisherName: publisherName
//   }
//   tags: tags
// }

// resource apimName_appInsightsLogger_resource 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
//   parent: apimName_resource
//   name: appInsightsName
//   properties: {
//     loggerType: 'applicationInsights'
//     resourceId: appInsightsId
//     credentials: {
//       instrumentationKey: appInsightsInstrumentationKey
//     }
//   }
// }

// resource apimName_applicationinsights 'Microsoft.ApiManagement/service/diagnostics@2019-01-01' = {
//   parent: apimName_resource
//   name: 'applicationinsights'
//   properties: {
//     loggerId: apimName_appInsightsLogger_resource.id
//     alwaysLog: 'allErrors'
//     sampling: {
//       percentage: 100
//       samplingType: 'fixed'
//     }
//   }
// }
