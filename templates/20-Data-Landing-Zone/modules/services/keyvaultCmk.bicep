// Licensed under the MIT license.

// This template is used to create a KeyVault.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string = ''
param keyvaultName string
param privateDnsZoneIdKeyVault string = ''

// Variables
var keyVaultPrivateEndpointName = '${keyVault.name}-private-endpoint'

// Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

resource keyVaultKeyStorage 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  parent: keyVault
  name: 'cmkStorage'
  properties: {
    attributes: {
      enabled: true
      exp: 1709484065
      exportable: false
    }
    curveName: 'P-256'
    keyOps: [
      'decrypt'
      'encrypt'
      'sign'
      'unwrapKey'
      'verify'
      'wrapKey'
    ]
    keySize: 2048
    kty: 'RSA'
  }
}

resource keyVaultKeyDataFactory 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  parent: keyVault
  name: 'cmkDataFactory'
  properties: {
    attributes: {
      enabled: true
      exp: 1709484065
      exportable: false
    }
    curveName: 'P-256'
    keyOps: [
      'decrypt'
      'encrypt'
      'sign'
      'unwrapKey'
      'verify'
      'wrapKey'
    ]
    keySize: 2048
    kty: 'RSA'
  }
}

resource keyVaultKeyVirtualMachine 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  parent: keyVault
  name: 'cmkVirtualMachine'
  properties: {
    attributes: {
      enabled: true
      exp: 1709484065
      exportable: false
    }
    curveName: 'P-256'
    keyOps: [
      'decrypt'
      'encrypt'
      'sign'
      'unwrapKey'
      'verify'
      'wrapKey'
    ]
    keySize: 2048
    kty: 'RSA'
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = if (!empty(subnetId)) {
  name: keyVaultPrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVault.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource keyVaultPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(subnetId) && !empty(privateDnsZoneIdKeyVault)) {
  parent: keyVaultPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${keyVaultPrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdKeyVault
        }
      }
    ]
  }
}

// Outputs
output keyvaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultKeyStorageName string = keyVaultKeyStorage.name
output keyVaultKeyStorageKeyUri string = keyVaultKeyStorage.properties.keyUri
output keyVaultKeyDataFactoryName string = keyVaultKeyDataFactory.name
output keyVaultKeyDataFactoryKeyUri string = keyVaultKeyDataFactory.properties.keyUri
output keyVaultKeyVirtualMachineName string = keyVaultKeyVirtualMachine.name
output keyVaultKeyVirtualMachineKeyUri string = keyVaultKeyVirtualMachine.properties.keyUri
