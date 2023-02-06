@description('Location for all resources.')
param location string

@description('System code')
param systemCode string

@description('Environment')
param env string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2022-datacenter'
  '2022-datacenter-azure-edition'
  '2022-datacenter-azure-edition-core'
  '2022-datacenter-azure-edition-core-smalldisk'
  '2022-datacenter-azure-edition-smalldisk'
  '2022-datacenter-core'
  '2022-datacenter-core-g2'
  '2022-datacenter-core-smalldisk'
  '2022-datacenter-core-smalldisk-g2'
  '2022-datacenter-g2'
  '2022-datacenter-smalldisk'
  '2022-datacenter-smalldisk-g2'
])
param OSVersion string = '2022-datacenter-azure-edition-core-smalldisk'

@description('Size of the virtual machine.')
@allowed([
  'Standard_B1s' // 02/04/2023 $12.85/month
  'Standard_B1ms' // 02/04/2023 $22.78/month
  'Standard_B2s' // 02/04/2023 $45.55/month
  'Standard_F1' // 02/04/2023 $79.55/month
  'Standard_B2ms' // 02/04/2023 $85.41/month
])
param vmSize string = 'Standard_B1s'

@description('managedDisk Type of osDisk.')
@allowed([
  'PremiumV2_LRS'
  'Premium_LRS'
  'Premium_ZRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
  'Standard_LRS'
  'UltraSSD_LRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Name of the virtual machine.')
param vmName string = 'vm-${systemCode}-${env}'

@description('Name of the network interface.')
var nicName = 'nic-${systemCode}-${env}'

var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = 'vnet-${systemCode}-${env}'

resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
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
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
