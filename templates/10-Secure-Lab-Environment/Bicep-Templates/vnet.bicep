@description('The name of the Virtual Network to Create')
param virtualNetworkName string

@description('The address range of the new VNET in CIDR format')
param virtualNetworkAddressRange string

@description('The name of the subnet created in the new VNET')
param subnetName string

@description('The address range of the subnet created in the VNET')
param subnetRange string

@description('The name of the Key Vault subnet created in the VNET')
param keyVaultSubnetName string

@description('The address range of the Key Vault subnet created in the new VNET')
param keyVaultSubnetRange string

@description('Location for all resources.')
param location string

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressRange
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetRange
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: keyVaultSubnetName
        properties: {
          addressPrefix: keyVaultSubnetRange
        }
      }
    ]
  }
}