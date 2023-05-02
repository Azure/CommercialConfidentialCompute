// Licensed under the MIT license.

targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'
@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string
@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

// Resource parameters
@description('Specifies the resource ID of the central purview instance.')
param purviewId string = ''
@description('Specifies the subscription IDs of the other Data Landing Zones.')
param dataLandingZoneSubscriptionIds array = []
@secure()
@description('Specifies the administrator password of the sql servers.')
param administratorPassword string

// Network parameters
@description('Specifies the resource id of the vnet of the data landing zone.')
param vnetId string
@description('Specifies the resource id of the network security group of the data landing zone.')
param nsgId string
@description('Specifies the resource id of the route table of the data landing zone.')
param rtId string
@description('Specifies the address space of the subnet that is used for runtimes services of the data landing zone.')
param runtimesSubnetAddressPrefix string = '10.1.0.0/28'
@description('Specifies the address space of the subnet that is used for storage services of the data landing zone.')
param storageSubnetAddressPrefix string = '10.1.0.16/28'

// Private DNS Zone parameters
@description('Specifies the resource ID of the private DNS zone for Key Vault.')
param privateDnsZoneIdKeyVault string = ''
@description('Specifies the resource ID of the private DNS zone for Data Factory.')
param privateDnsZoneIdDataFactory string = ''
@description('Specifies the resource ID of the private DNS zone for Data Factory Portal.')
param privateDnsZoneIdDataFactoryPortal string = ''
@description('Specifies the resource ID of the private DNS zone for Blob Storage.')
param privateDnsZoneIdBlob string = ''
@description('Specifies the resource ID of the private DNS zone for Datalake Storage.')
param privateDnsZoneIdDfs string = ''

// Variables
var administratorUsername = 'SuperMainUser'
var name = toLower('${prefix}-${environment}')
var vnetResourceGroupName = length(split(vnetId, '/')) == 9 ? split(vnetId, '/')[4] : 'incorrectSegmentLength'
var cmkResourceGroupName = '${name}-cmk-rg'
var storageResourceGroupName = '${name}-storage-rg'
var runtimesResourceGroupName = '${name}-runtimes-rg'

// Network Resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: vnetResourceGroupName
}

module networkServices 'modules/network.bicep' = {
  name: 'networkServices'
  scope: networkResourceGroup
  params: {
    nsgId: nsgId
    rtId: rtId
    vnetId: vnetId
    runtimesSubnetAddressPrefix: runtimesSubnetAddressPrefix
    storageSubnetAddressPrefix: storageSubnetAddressPrefix
  }
}

// CMK services
resource cmkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: cmkResourceGroupName
  location: location
  tags: tags
  properties: {}
}

module cmkResources 'modules/cmk.bicep' = {
  name: 'cmkResources'
  scope: cmkResourceGroup
  params: {
    location: location
    tags: tags
    prefix: name
  }
}

// Storage services
resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: storageResourceGroupName
  location: location
  tags: tags
  properties: {}
}

module storageResources 'modules/storage.bicep' = {
  name: 'storageResources'
  scope: storageResourceGroup
  params: {
    location: location
    tags: tags
    prefix: name
    subnetId: networkServices.outputs.storageSubnetId
    purviewId: purviewId
    dataLandingZoneSubscriptionIds: dataLandingZoneSubscriptionIds
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    userAssignedIdentityId: cmkResources.outputs.userAssignedIdentityId
    keyVaultUri: cmkResources.outputs.keyVaultUri
    keyVaultKeyName: cmkResources.outputs.keyVaultKeyStorageName
  }
}

// Runtimes resources
resource runtimesResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: runtimesResourceGroupName
  location: location
  tags: tags
  properties: {}
}

module runtimesResources 'modules/runtimes.bicep' = {
  name: 'runtimesResources'
  scope: runtimesResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.runtimesSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    deploySelfHostedIntegrationRuntimes: true
    datafactoryIds: []
    purviewId: purviewId
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    userAssignedIdentityId: cmkResources.outputs.userAssignedIdentityId
    keyVaultId: cmkResources.outputs.keyVaultId
    keyVaultUri: cmkResources.outputs.keyVaultUri
    keyVaultKeyVirtualMachineUri: cmkResources.outputs.keyVaultKeyVirtualMachineKeyUri
    keyVaultKeyDataDactoryName: cmkResources.outputs.keyVaultKeyDataFactoryName
  }
}

// Outputs
