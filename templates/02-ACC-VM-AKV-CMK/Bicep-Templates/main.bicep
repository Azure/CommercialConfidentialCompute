@description('The name of the administrator account of the new VM and domain')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine.')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('Virtual machine base name that will incrimented and built on for resources.')
@maxLength(10)
param virtualMachineBaseName string = 'accvm'

@description('Number of ACC VMs to deploy')
@minValue(1)
@maxValue(50)
param numberOfACCVMs int = 1

@description('Size of the VM for the DC')
@allowed([
  'Standard_DC2as_v5'
  'Standard_DC4as_v5'
  'Standard_DC8as_v5'
  'Standard_DC16as_v5'
  'Standard_DC32as_v5'
  'Standard_DC48as_v5'
  'Standard_DC64as_v5'
  'Standard_DC96as_v5'
  'Standard_DC2ads_v5'
  'Standard_DC4ads_v5'
  'Standard_DC8ads_v5'
  'Standard_DC16ads_v5'
  'Standard_DC32ads_v5'
  'Standard_DC48ads_v5'
  'Standard_DC64ads_v5'
  'Standard_DC96ads_v5'
])
param vmSize string = 'Standard_DC2as_v5'

@description('OS Image for VMs to use')
@allowed([
  'Windows Server 2022 Gen 2'
  'Windows Server 2019 Gen 2'
  'Ubuntu 20.04 LTS Gen 2'
])
param osImageName string = 'Windows Server 2022 Gen 2'

@description('VM security type.')
@allowed([
  'VMGuestStateOnly'
  'DiskWithVMGuestState'
])
param securityType string = 'DiskWithVMGuestState'

@allowed([
  'yes'
  'no'
])
param createBastionHost string = 'yes'

@description('Object ID of the Confidential VM Orchestrator Service Principal')
@secure()
param objectIDConfidentialOrchestrator string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Use current deployment time to generate unique Azure Key Vault name.')
param timeUnique string = utcNow('hhmmss')

var virtualNetworkName = 'vnet-acc-lab'
var virtualNetworkAddressRange = '10.0.0.0/16'
var subnetName = 'sn00'
var subnetRange = '10.0.0.0/24'
var bastionHostName = 'bastion-01'
var bastionSubnetName = 'AzureBastionSubnet'
var bastionSubnetRange = '10.0.255.0/24'
var keyVaultName = 'AKV-${uniqueString(resourceGroup().id, timeUnique)}'
var diskEncryptSetName = 'DES-01'
var imageReference = imageList[osImageName]
var imageList = {
  'Windows Server 2022 Gen 2': {
    publisher: 'microsoftwindowsserver'
    offer: 'windowsserver'
    sku: '2022-datacenter-smalldisk-g2'
    version: 'latest'
  }
  'Windows Server 2019 Gen 2': {
    publisher: 'microsoftwindowsserver'
    offer: 'windowsserver'
    sku: '2019-datacenter-smalldisk-g2'
    version: 'latest'
  }
  'Ubuntu 20.04 LTS Gen 2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-confidential-vm-focal'
    sku: '20_04-lts-cvm'
    version: 'latest'
  }
}
var isWindows = contains(osImageName, 'Windows')
var windowsConfiguration = {
  enableAutomaticUpdates: 'true'
  provisionVmAgent: 'true'
}
var linuxConfiguration = {
  disablePasswordAuthentication: 'true'
  ssh: {
    publicKeys: [
      {
        keyData: adminPasswordOrKey
        path: '/home/${adminUsername}/.ssh/authorized_keys'
      }
    ]
  }
}

module DiskEncryption 'disk-encryption.bicep' = {
  name: 'DiskEncryption'
  params: {
    diskEncryptSetName: diskEncryptSetName
    keyVaultName: keyVaultName
    objectIDConfidentialOrchestrator: objectIDConfidentialOrchestrator
    location: location
  }
}

module VNet 'vnet.bicep' = {
  name: 'VNet'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: subnetName
    subnetRange: subnetRange
    location: location
  }
  dependsOn: [
    DiskEncryption
  ]
}

module Bastion 'bastion.bicep'  = if (createBastionHost == 'yes') {
  name: 'Bastion'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: subnetName
    subnetRange: subnetRange
    bastionSubnetName: bastionSubnetName
    bastionSubnetRange: bastionSubnetRange
    bastionHostName: bastionHostName
    location: location
  }
  dependsOn: [
    VNet
  ]
}

resource virtualMachineBaseName_nic 'Microsoft.Network/networkInterfaces@2019-02-01' = [for i in range(0, numberOfACCVMs): {
  name: '${virtualMachineBaseName}-nic-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    Bastion
  ]
}]

resource virtualMachineBaseName_resource 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, numberOfACCVMs): {
  name: '${virtualMachineBaseName}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${virtualMachineBaseName}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
          securityProfile: {
            diskEncryptionSet: {
              id: resourceId('Microsoft.Compute/diskEncryptionSets', diskEncryptSetName)
            }
            securityEncryptionType: securityType
          }
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineBaseName}-nic-${i}')
        }
      ]
    }
    osProfile: {
      computerName: '${virtualMachineBaseName}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      windowsConfiguration: (isWindows ? windowsConfiguration : json('null'))
    }
    securityProfile: {
      securityType: 'ConfidentialVM'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
  dependsOn: [
    virtualMachineBaseName_nic
  ]
}]
