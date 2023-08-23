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

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: resourceNames.appServicePlan
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  tags: tags
}

// Outputs
output appServicePlanName string = appServicePlan.name
output appServicePlanId string = appServicePlan.id
