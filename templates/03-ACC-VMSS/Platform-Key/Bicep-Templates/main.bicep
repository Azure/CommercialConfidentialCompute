@description('Size of the VM.')
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
  'Standard_EC2as_v5'
  'Standard_EC4as_v5'
  'Standard_EC8as_v5'
  'Standard_EC16as_v5'
  'Standard_EC20as_v5'
  'Standard_EC32as_v5'
  'Standard_EC48as_v5'
  'Standard_EC64as_v5'
  'Standard_EC96as_v5'
  'Standard_EC96ias_v5'
  'Standard_EC2ads_v5'
  'Standard_EC4ads_v5'
  'Standard_EC8ads_v5'
  'Standard_EC16ads_v5'
  'Standard_EC20ads_v5'
  'Standard_EC32ads_v5'
  'Standard_EC48ads_v5'
  'Standard_EC64ads_v5'
  'Standard_EC96ads_v5'
  'Standard_EC96iads_v5'
])
param vmSize string = 'Standard_DC2as_v5'

@description('OS Image for the Virtual Machine')
@allowed([
  'Windows Server 2022 Gen 2'
  'Windows Server 2019 Gen 2'
  'Ubuntu 20.04 LTS Gen 2'
])
param osImageName string = 'Windows Server 2022 Gen 2'

@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.')
@minLength(3)
@maxLength(61)
param vmssName string

@description('Number of VM instances (100 or less).')
@minValue(1)
@maxValue(100)
param instanceCount int = 3

@description('When true this limits the scale set to a single placement group, of max size 100 virtual machines. NOTE: If singlePlacementGroup is true, it may be modified to false. However, if singlePlacementGroup is false, it may not be modified to true.')
param singlePlacementGroup bool = true

@description('VM security type.')
@allowed([
  'VMGuestStateOnly'
])
param securityType string = 'VMGuestStateOnly'

@description('Admin user name of the VM.')
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

@description('Fault Domain count for each placement group.')
param platformFaultDomainCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

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
  'Ubuntu 18.04 LTS Gen 2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-confidential-vm-experimental'
    sku: '18_04-gen2'
    version: 'latest'
  }
}
var imageReference = imageList[osImageName]
var isWindows = contains(osImageName, 'Windows')
var namingInfix = toLower(substring('${vmssName}${uniqueString(resourceGroup().id)}', 0, 9))
var longNamingInfix = toLower(vmssName)
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var networkSecurityGroupName = '${namingInfix}-nsg'
var networkSecurityGroupId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var virtualNetworkName = '${namingInfix}vnet'
var publicIPAddressName = '${namingInfix}pip'
var subnetName = '${namingInfix}subnet'
var loadBalancerName = '${namingInfix}lb'
var publicIPAddressID = publicIPAddress.id
var lbProbeID = resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'tcpProbe')
var natPoolName = '${namingInfix}natpool'
var bePoolName = '${namingInfix}bepool'
var lbPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, bePoolName)
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = (isWindows ? '3389' : '22')
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')
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
var windowsConfiguration = {
  enableAutomaticUpdates: 'true'
  provisionVmAgent: 'true'
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: loadBalancerName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource vmscaleset 'Microsoft.Compute/virtualMachineScaleSets@2021-11-01' = {
  name: namingInfix
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    singlePlacementGroup: singlePlacementGroup
    platformFaultDomainCount: platformFaultDomainCount
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            securityProfile: {
              securityEncryptionType: securityType
            }
          }
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
        windowsConfiguration: (isWindows ? windowsConfiguration : json('null'))
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbPoolID
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName, natPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      securityProfile: {
        uefiSettings: {
          secureBootEnabled: true
          vTpmEnabled: true
        }
        securityType: 'ConfidentialVM'
      }
      extensionProfile: {
        extensions: []
      }
    }
  }
  dependsOn: [
    loadBalancer
    virtualNetwork
  ]
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {}
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupId
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroup
  ]
}

output applicationUrl string = 'http://${publicIPAddress.properties.dnsSettings.fqdn}/MyApp'
