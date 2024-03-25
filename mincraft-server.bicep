resource minecraft_server_deployment 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
    name: 'minecraft-server-deployment'
    location: resourceGroup().location
    properties: {
      sku: 'Standard'
      containers: [
        {
          name: uniqueString(resourceGroup().id, deployment().name)
          properties: {
            image: 'itzg/minecraft-bedrock-server'
            ports: [
              {
                port: 19132
                protocol: 'udp'
              }
            ]
            resources: {
              requests: {
                cpu: 2
                memoryInGB: 4
              }
            }
            environmentVariables: [
              {
                name: 'EULA'
                value: 'TRUE'
              }
            ]
          }
        }
      ]
      
      osType: 'Linux'
      restartPolicy: 'OnFailure'
      ipAddress: {
        type: 'Public'
        dnsNameLabel: 'marikos-minecraft-server'
        ports: [
          {
            protocol: 'udp'
            port: 19132
          }
        ]
      }
    }
  }
  