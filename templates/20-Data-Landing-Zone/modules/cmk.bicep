// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create metadata resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object

// Variables
var userAssignedIdentityName = '${prefix}-uai001'
var keyvaultName = '${prefix}-vault001'

// Resources
module userAssignedIdentity 'services/userassignedidentity.bicep' = {
  name: 'userAssignedIdentity'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    userAssignedIdentityName: userAssignedIdentityName
  }
}

module keyVault 'services/keyvaultCmk.bicep' = {
  name: 'keyVault'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    keyvaultName: keyvaultName
    subnetId: ''
  }
}

module keyVaultRoleAssignmentUserAssignedIdentity 'auxiliary/uaiRoleAssignmentKeyVault.bicep' = {
  name: 'keyVaultRoleAssignmentUserAssignedIdentity'
  scope: resourceGroup()
  params: {
    keyVaultId: keyVault.outputs.keyvaultId
    userAssignedIdentityId: userAssignedIdentity.outputs.userAssignedIdentityId
    role: 'KeyVaultCryptoServiceEncryptionUser'
  }
}

// Outputs
output userAssignedIdentityId string = userAssignedIdentity.outputs.userAssignedIdentityId
output keyVaultUri string = keyVault.outputs.keyVaultUri
output keyVaultId string = keyVault.outputs.keyvaultId
output keyVaultKeyStorageName string = keyVault.outputs.keyVaultKeyStorageName
output keyVaultKeyStorageKeyUri string = keyVault.outputs.keyVaultKeyStorageKeyUri
output keyVaultKeyDataFactoryName string = keyVault.outputs.keyVaultKeyDataFactoryName
output keyVaultKeyDataFactoryKeyUri string = keyVault.outputs.keyVaultKeyDataFactoryKeyUri
output keyVaultKeyVirtualMachineName string = keyVault.outputs.keyVaultKeyVirtualMachineName
output keyVaultKeyVirtualMachineKeyUri string = keyVault.outputs.keyVaultKeyVirtualMachineKeyUri
