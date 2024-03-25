@minLength(3)
@maxLength(20)
@description('Used to create the names of the Azure artifacts created eg: solutionName = aifs ...func-aifm-message-ingester, staifsmessageingestion   ')
param solutionPrefix string = take(uniqueString(resourceGroup().id), 5)


@description('Storage Account type')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS'])
param storageAccountType string = 'Standard_LRS'

@description('Storage Account Name')
param storageAccountName string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed(['survival', 'creative', 'adventure '])
param gamemode string = 'creative'

@allowed(['minecraft-bedrock-server', 'minecraft-server'])
param serverType string = 'minecraft-bedrock-server'

var cpuCores = 1
var memoryInGb = 2
var minecractContainerGroupName = '${solutionPrefix}-minecraft'
var minecraftContainerName = 'ci-${solutionPrefix}'
var minecraftContainerImage = 'itzg/${serverType}'
var fileShareName = '${solutionPrefix}-data'

var tags = {
  solution: solutionPrefix
  app: 'mincraft'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource storageAccountName_default_fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-04-01' = {
  name: '${storageAccountName}/default/${fileShareName}'
  dependsOn: [storageAccount]
}

resource minecractContainerGroup 'Microsoft.ContainerInstance/containerGroups@2018-10-01' = {
  name: minecractContainerGroupName
  location: location
  tags: tags
  properties: {
    containers: [
      {
        name: minecraftContainerName
        properties: {
          image: minecraftContainerImage
          environmentVariables: [
            {
              name: 'EULA'
              value: 'TRUE'
            }
            {
              name: 'GAMEMODE'
              value: gamemode
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          ports: [
            {
              port: 25565
            }
            {
              protocol: 'UDP'
              port: 19132
            }
          ]
          volumeMounts: [
            {
              mountPath: '/data'
              name: 'data'
              readOnly: false
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: 25565
        }
        {
          protocol: 'UDP'
          port: 19132
        }
      ]
      dnsNameLabel: '${solutionPrefix}-minecraft-server'
    }
    restartPolicy: 'OnFailure'
    volumes: [
      {
        name: 'data'
        azureFile: {
          readOnly: false
          shareName: fileShareName
          storageAccountName: storageAccountName
          storageAccountKey: listKeys(storageAccountName, '2017-10-01').keys[0].value
        }
      }
    ]
  }
}

