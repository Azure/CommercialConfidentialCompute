@description('The name of the Virtual Network to Create')
param virtualNetworkName string

@description('The address range of the new VNET in CIDR format')
param virtualNetworkAddressRange string

@description('The name of the subnet created in the new VNET')
param subnetName string

@description('The address range of the subnet created in the VNET')
param subnetRange string

@description('The Name of the Bastion Host')
param bastionHostName string

@description('The name of the Bastion subnet created in the  VNET')
param bastionSubnetName string

@description('The address range of the Bastion subnet created in the VNET')
param bastionSubnetRange string

@description('Azure region for Bastion and virtual network')
param location string = resourceGroup().location

var publicIpAddressName_var = 'pip-${bastionHostName}'
var publicIpAddressId = publicIpAddressName.id

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2021-05-01' = {
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
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetRange
        }
      }
    ]
  }
}

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIpAddressName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHostName_resource 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, bastionSubnetName)
          }
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
  }
}
