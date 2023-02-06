targetScope = 'subscription'

// Parameters for common
param location string = 'japaneast'
param systemCode string = 'hawk'
param env string = 'dev'

// Parameters for resorce group
param resourceGroupName string = 'rg-${systemCode}-${env}'

// Parameters for virtual machine
param adminUsername string = 'azureuser'
@minLength(12)
@secure()
param adminPassword string

// Parameters for Monitor Alerts
param emailAddress string = '${systemCode}@sample.com'
param emailReceiversName string = '${systemCode}-${env}'

// deploy resource groups.
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

// deploy virtual machine.
module vmModule 'modules/vm.bicep' = {
  scope: rg
  name: 'Deploy_Virtual_machine'
  params: {
    location: location
    systemCode: systemCode
    env: env
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

// deploy action groups.
module agModule 'modules/ag.bicep' = {
  scope: rg
  name: 'Deploy_action_groups'
  params: {
    emailAddress: emailAddress
    emailReceiversName: emailReceiversName
    env: env
    systemCode: systemCode
  }
}

// deploy alert rule.
module alModule 'modules/ar.bicep' = {
  scope: rg
  name: 'Deploy_alert_rule'
  params: {
    location: location
    env: env
    systemCode: systemCode
    resourceId: vmModule.outputs.id
    actionGroupId: agModule.outputs.id
  }
}
