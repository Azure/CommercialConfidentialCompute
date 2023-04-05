// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param vnetId string
param nsgId string
param rtId string
param runtimesSubnetAddressPrefix string = '10.1.0.0/28'
param storageSubnetAddressPrefix string = '10.1.0.16/28'

// Variables
var rtName = length(split(rtId, '/')) == 9 ? last(split(rtId, '/')) : 'incorrectSegmentLength'
var nsgName = length(split(nsgId, '/')) == 9 ? last(split(nsgId, '/')) : 'incorrectSegmentLength'
var vnetName = length(split(vnetId, '/')) == 9 ? last(split(vnetId, '/')) : 'incorrectSegmentLength'
var runtimesSubnetName = 'RuntimesSubnet'
var storageSubnetName = 'StorageSubnet'

// Resources
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' existing = {
  name: nsgName
}

resource rt 'Microsoft.Network/routeTables@2022-09-01' existing = {
  name: rtName
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
}

resource runtimesSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  parent: vnet
  name: runtimesSubnetName
  properties: {
    addressPrefix: runtimesSubnetAddressPrefix
    addressPrefixes: []
    delegations: []
    networkSecurityGroup: {
      id: nsg.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTable: {
      id: rt.id
    }
    serviceEndpointPolicies: []
    serviceEndpoints: []
  }
}

resource storageSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  parent: vnet
  name: storageSubnetName
  properties: {
    addressPrefix: storageSubnetAddressPrefix
    addressPrefixes: []
    delegations: []
    networkSecurityGroup: {
      id: nsg.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTable: {
      id: rt.id
    }
    serviceEndpointPolicies: []
    serviceEndpoints: []
  }
}

// Outputs
output runtimesSubnetId string = runtimesSubnet.id
output storageSubnetId string = storageSubnet.id
