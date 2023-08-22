targetScope = 'resourceGroup'
// Parameters
@description('Azure location to which the resources are to be deployed')
param location string

@description('Required. Resource name.')
param name string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

output serviceBusNamespaceName string = serviceBusNamespace.name
