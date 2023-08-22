targetScope = 'resourceGroup'
// Parameters
@description('Azure location to which the resources are to be deployed')
param location string

@description('Required. Resource name.')
param name string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

resource keyVaultModule 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForTemplateDeployment: true // ARM is permitted to retrieve secrets from the key vault. 
    accessPolicies: []
  }
}

output keyVaultName string = keyVaultModule.name
