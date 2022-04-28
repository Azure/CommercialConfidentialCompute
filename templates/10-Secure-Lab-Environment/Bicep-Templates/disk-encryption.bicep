@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of Disk Encryption Set')
param diskEncryptSetName string = 'DES-01'

@description('Name of Azure Key Vault')
param keyVaultName string

@description('Object ID of the Confidential VM Orchestrator Service Principal')
param objectIDConfidentialOrchestrator string

var keyVaultSku = 'premium'
var keyName = 'acckey01'
var keyVaultID = keyvaultName_resource.id
var policyType = 'application/json; charset=utf-8'
var policyData = 'ew0KICAiYW55T2YiOiBbDQogICAgew0KICAgICAgImFsbE9mIjogWw0KICAgICAgICB7DQogICAgICAgICAgImNsYWltIjogIngtbXMtYXR0ZXN0YXRpb24tdHlwZSIsDQogICAgICAgICAgImVxdWFscyI6ICJzZXZzbnB2bSINCiAgICAgICAgfSwNCiAgICAgICAgew0KICAgICAgICAgICJjbGFpbSI6ICJ4LW1zLWNvbXBsaWFuY2Utc3RhdHVzIiwNCiAgICAgICAgICAiZXF1YWxzIjogImF6dXJlLWNvbXBsaWFudC1jdm0iDQogICAgICAgIH0NCiAgICAgIF0sDQogICAgICAiYXV0aG9yaXR5IjogImh0dHBzOi8vc2hhcmVkZXVzLmV1cy5hdHRlc3QuYXp1cmUubmV0LyINCiAgICB9LA0KICAgIHsNCiAgICAgICJhbGxPZiI6IFsNCiAgICAgICAgew0KICAgICAgICAgICJjbGFpbSI6ICJ4LW1zLWF0dGVzdGF0aW9uLXR5cGUiLA0KICAgICAgICAgICJlcXVhbHMiOiAic2V2c25wdm0iDQogICAgICAgIH0sDQogICAgICAgIHsNCiAgICAgICAgICAiY2xhaW0iOiAieC1tcy1jb21wbGlhbmNlLXN0YXR1cyIsDQogICAgICAgICAgImVxdWFscyI6ICJhenVyZS1jb21wbGlhbnQtY3ZtIg0KICAgICAgICB9DQogICAgICBdLA0KICAgICAgImF1dGhvcml0eSI6ICJodHRwczovL3NoYXJlZHd1cy53dXMuYXR0ZXN0LmF6dXJlLm5ldC8iDQogICAgfSwNCiAgICB7DQogICAgICAiYWxsT2YiOiBbDQogICAgICAgIHsNCiAgICAgICAgICAiY2xhaW0iOiAieC1tcy1hdHRlc3RhdGlvbi10eXBlIiwNCiAgICAgICAgICAiZXF1YWxzIjogInNldnNucHZtIg0KICAgICAgICB9LA0KICAgICAgICB7DQogICAgICAgICAgImNsYWltIjogIngtbXMtY29tcGxpYW5jZS1zdGF0dXMiLA0KICAgICAgICAgICJlcXVhbHMiOiAiYXp1cmUtY29tcGxpYW50LWN2bSINCiAgICAgICAgfQ0KICAgICAgXSwNCiAgICAgICJhdXRob3JpdHkiOiAiaHR0cHM6Ly9zaGFyZWRuZXUubmV1LmF0dGVzdC5henVyZS5uZXQvIg0KICAgIH0sDQogICAgew0KICAgICAgImFsbE9mIjogWw0KICAgICAgICB7DQogICAgICAgICAgImNsYWltIjogIngtbXMtYXR0ZXN0YXRpb24tdHlwZSIsDQogICAgICAgICAgImVxdWFscyI6ICJzZXZzbnB2bSINCiAgICAgICAgfSwNCiAgICAgICAgew0KICAgICAgICAgICJjbGFpbSI6ICJ4LW1zLWNvbXBsaWFuY2Utc3RhdHVzIiwNCiAgICAgICAgICAiZXF1YWxzIjogImF6dXJlLWNvbXBsaWFudC1jdm0iDQogICAgICAgIH0NCiAgICAgIF0sDQogICAgICAiYXV0aG9yaXR5IjogImh0dHBzOi8vc2hhcmVkd2V1LndldS5hdHRlc3QuYXp1cmUubmV0LyINCiAgICB9DQogIF0sDQogICJ2ZXJzaW9uIjogIjEuMC4wIg0KfQ'

resource keyvaultName_resource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: false
    enableSoftDelete: true
    enablePurgeProtection: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
    accessPolicies: []
    sku: {
      name: keyVaultSku
      family: 'A'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'disabled'
  }
}

resource keyvaultName_keyName 'Microsoft.KeyVault/vaults/keys@2021-11-01-preview' = {
  parent: keyvaultName_resource
  name: keyName
  properties: {
    attributes: {
      enabled: true
      exportable: true
    }
    keyOps: [
      'wrapKey'
      'unwrapKey'
    ]
    keySize: 3072
    kty: 'RSA-HSM'
    release_policy: {
      contentType: policyType
      data: policyData
    }
  }
}

resource diskEncryptSetName_resource 'Microsoft.Compute/diskEncryptionSets@2021-12-01' = {
  name: diskEncryptSetName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    activeKey: {
      sourceVault: {
        id: keyVaultID
      }
      keyUrl: reference(keyvaultName_keyName.id, '2019-09-01', 'Full').properties.keyUriWithVersion
    }
    encryptionType: 'ConfidentialVmEncryptedWithCustomerKey'
  }
}

resource keyvaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  parent: keyvaultName_resource
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(diskEncryptSetName_resource.id, '2019-07-01', 'Full').identity.PrincipalId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
          secrets: []
          certificates: []
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: objectIDConfidentialOrchestrator
        permissions: {
          keys: [
            'get'
            'release'
          ]
          secrets: []
          certificates: []
        }
      }
    ]
  }
}
