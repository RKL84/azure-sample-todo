targetScope = 'resourceGroup'

// Parameters
@description('Required. Azure location to which the resources are to be deployed')
param location string

@description('Required. The naming module for facilitating naming convention.')
param naming object

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// Variables 
var placeholder = '***'
var appServiceNameWithPlaceholder = replace(naming.appService.name, '${naming.appService.slug}-', '${naming.appService.slug}-${placeholder}-')
var todoAppServiceName = replace(appServiceNameWithPlaceholder, placeholder, 'todo')

param allowedOrigins array = []
param appCommandLine string = ''
param applicationInsightsName string = ''
param sharedResourceGroupName string
param appServicePlanId string
@secure()
param appSettings object = {}
param keyVaultName string
param serviceName string = 'api'

module api '../core/host/appservice.bicep' = {
  name: '${todoAppServiceName}-app-module'
  params: {
    name: todoAppServiceName
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    allowedOrigins: allowedOrigins
    appCommandLine: appCommandLine
    applicationInsightsName: applicationInsightsName
    sharedResourceGroupName: sharedResourceGroupName
    appServicePlanId: appServicePlanId
    appSettings: appSettings
    keyVaultName: keyVaultName
    runtimeName: 'dotnetcore'
    runtimeVersion: '6.0'
    scmDoBuildDuringDeployment: false
  }
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = api.outputs.identityPrincipalId
output SERVICE_API_NAME string = api.outputs.name
output SERVICE_API_URI string = api.outputs.uri
