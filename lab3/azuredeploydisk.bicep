@description('Name of the managed disk to create')
param managedDiskName string = 'az104-disk5'

@description('Location for the managed disk')
param location string = resourceGroup().location

@description('Size of the managed disk in GiB')
param diskSizeinGiB int = 32

@description('SKU (storage type) for the managed disk')
param skuName string = 'StandardSSD_LRS'

@description('Tags to apply to the managed disk')
param tags object = {
  deployment: 'task5-bicep'
}

resource managedDisk 'Microsoft.Compute/disks@2023-04-02' = {
  name: managedDiskName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: diskSizeinGiB
  }
  tags: tags
}

output diskId string = managedDisk.id
