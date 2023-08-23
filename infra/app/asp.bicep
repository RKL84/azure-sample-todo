targetScope = 'resourceGroup'

// Parameters
@description('Required. Azure location to which the resources are to be deployed')
param location string

@description('Required. The naming module for facilitating naming convention.')
param naming object

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// Variables 
var resourceNames = {
  appServicePlan: naming.appServicePlan.name
}

module appServicePlan '../core/host/appserviceplan.bicep' = {
  name: 'appservicePlan-Deployment'
  params: {
    name: resourceNames.appServicePlan
    location: location
    tags: tags
    sku: {
      name: 'B1'
      //     // name: 'Y1'
      //     // tier: 'Dynamic'
    }
  }
}

// Outputs
output appServicePlanName string = appServicePlan.outputs.name
output appServicePlanId string = appServicePlan.outputs.id
