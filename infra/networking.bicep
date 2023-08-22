// Parameters
@description('Optional. Azure location to which the resources are to be deployed')
param location string

@description('Required. The naming module for facilitating resource naming convention.')
param naming object

param apimCSVNetNameAddressPrefix string = '10.2.0.0/16'

param bastionAddressPrefix string = '10.2.1.0/24'
param devOpsNameAddressPrefix string = '10.2.2.0/24'
param jumpBoxAddressPrefix string = '10.2.3.0/24'
param appGatewayAddressPrefix string = '10.2.4.0/24'
param backEndAddressPrefix string = '10.2.6.0/24'
param apimAddressPrefix string = '10.2.7.0/24'

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// Variables
var placeholder = '***'
var snetNameWithPlaceholder = replace(naming.subnet.name, '${naming.subnet.slug}-', '${naming.subnet.slug}-${placeholder}-')
var nsgNameWithPlaceholder = replace(naming.networkSecurityGroup.name, '${naming.networkSecurityGroup.slug}-', '${naming.networkSecurityGroup.slug}-${placeholder}-')
var resourceNames = {
  vnetName: naming.virtualNetwork.name
  bastionSubnetName: 'AzureBastionSubnet'
  devOpsSubnetName: replace(snetNameWithPlaceholder, placeholder, 'cicd')
  jumpboxSubnetName: replace(snetNameWithPlaceholder, placeholder, 'jbox')
  backEndSubnetName: replace(snetNameWithPlaceholder, placeholder, 'bcke')
  apimSubnetName: replace(snetNameWithPlaceholder, placeholder, 'apim')
  appGatewaySubnetName: replace(snetNameWithPlaceholder, placeholder, 'apgw')
  bastionSNNSG: replace(nsgNameWithPlaceholder, placeholder, 'bast')
  devOpsSNNSG: replace(nsgNameWithPlaceholder, placeholder, 'cicd')
  jumpBoxSNNSG: replace(nsgNameWithPlaceholder, placeholder, 'jbox')
  backEndSNNSG: replace(nsgNameWithPlaceholder, placeholder, 'bcke')
  apimSNNSG: replace(nsgNameWithPlaceholder, placeholder, 'apim')
  appGatewaySNNSG: replace(nsgNameWithPlaceholder, placeholder, 'apgw')
}

resource vnetApimCs 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: resourceNames.vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        apimCSVNetNameAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: defaultSubnets
  }
}

var defaultSubnets = [
  {
    name: resourceNames.bastionSubnetName
    properties: {
      addressPrefix: bastionAddressPrefix
      networkSecurityGroup: {
        id: bastionNSG.id
      }
    }
  }
  {
    name: resourceNames.devOpsSubnetName
    properties: {
      addressPrefix: devOpsNameAddressPrefix
      networkSecurityGroup: {
        id: devOpsNSG.id
      }
    }
  }
  {
    name: resourceNames.jumpboxSubnetName
    properties: {
      addressPrefix: jumpBoxAddressPrefix
      networkSecurityGroup: {
        id: jumpBoxNSG.id
      }
    }
  }
  {
    name: resourceNames.backEndSubnetName
    properties: {
      addressPrefix: backEndAddressPrefix
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]
      privateEndpointNetworkPolicies: 'Enabled'
      networkSecurityGroup: {
        id: backEndNSG.id
      }
    }
  }
  {
    name: resourceNames.apimSubnetName
    properties: {
      addressPrefix: apimAddressPrefix
      networkSecurityGroup: {
        id: apimNSG.id
      }
    }
  }
  {
    name: resourceNames.appGatewaySubnetName
    properties: {
      addressPrefix: appGatewayAddressPrefix
      networkSecurityGroup: {
        id: appGatewayNSG.id
      }
    }
  }
]

// Network Security Groups (NSG)

// Bastion NSG must have mininal set of rules below
resource bastionNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceNames.bastionSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 140
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInbound'
        properties: {
          priority: 150
          protocol: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          priority: 100
          protocol: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          priority: 120
          protocol: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          priority: 130
          protocol: '*'
          destinationPortRange: '80'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }
}

resource devOpsNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceNames.devOpsSNNSG
  location: location
  properties: {
    securityRules: []
  }
}

resource jumpBoxNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceNames.jumpBoxSNNSG
  location: location
  properties: {
    securityRules: []
  }
}

resource backEndNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceNames.backEndSNNSG
  location: location
  properties: {
    securityRules: []
  }
}

resource apimNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceNames.apimSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'apim-mgmt-endpoint-for-portal'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'ApiManagement'
          protocol: 'Tcp'
          destinationPortRange: '3443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'apim-azure-infra-lb'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: 'Tcp'
          destinationPortRange: '6390'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'apim-azure-storage'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
        }
      }
      {
        name: 'apim-azure-sql'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'SQL'
        }
      }
      {
        name: 'apim-azure-kv'
        properties: {
          priority: 2020
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureKeyVault'
        }
      }
    ]
  }
}

resource appGatewayNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceNames.appGatewaySNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'HealthProbes'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_TLS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 111
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

/// Output section
output vnetName string = resourceNames.vnetName
output vnetId string = vnetApimCs.id

output bastionSubnetName string = resourceNames.bastionSubnetName
output devOpsSubnetName string = resourceNames.devOpsSubnetName
output jumpBoxSubnetName string = resourceNames.jumpboxSubnetName
output appGatewaySubnetName string = resourceNames.appGatewaySubnetName
output backEndSubnetName string = resourceNames.backEndSubnetName
output apimSubnetName string = resourceNames.apimSubnetName

output bastionSubnetid string = '${vnetApimCs.id}/subnets/${resourceNames.bastionSubnetName}'
output devOpsSubnetId string = '${vnetApimCs.id}/subnets/${resourceNames.devOpsSubnetName}'
output jumpBoxSubnetid string = '${vnetApimCs.id}/subnets/${resourceNames.jumpboxSubnetName}'
output appGatewaySubnetid string = '${vnetApimCs.id}/subnets/${resourceNames.appGatewaySubnetName}'
output backEndSubnetid string = '${vnetApimCs.id}/subnets/${resourceNames.backEndSubnetName}'
output apimSubnetid string = '${vnetApimCs.id}/subnets/${resourceNames.apimSubnetName}'
