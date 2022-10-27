param Location string = resourceGroup().location

@description('Provide the pricing tier of the key vault.')
param Storage_SkuName string = 'Standard_LRS'
param StorageAccountTableName string = 'EncryptionTable'
param Application_Name string = 'dev-we-lab-app'
param Application_Environment string = 'dev'
param Application_Version string = '1.0'

@description('The Runtime stack of current web app')
param Appication_LinuxFxVersion string = 'DOTNETCORE|6.0'
param Release_Name string = 'releasetest'
param Release_RequestedFor string = 'lab'
param Release_SourceCodeBranch string = 'develop'
param Release_TriggerType string = 'Manual'
param Release_Url string = 'url'

@description('Provide the pricing tier of the App Service Plan.')
param AppSvcPlan_SkuName string = 'B1'

@description('Provide the pricing tier of the key vault.')
param Keyvault_SkuName string = 'Standard'
param Keyvault_TenantId string = '0d876cc9-1767-4fc7-b562-1d3d31671c8f'
param Keyvault_ObjectId string = '7517bc42-bcf8-4916-a677-b5753051f846'

@description('Specifies the name of the secret that you want to create.')
param Keyvault_SecretName string = 'EncryptionKey'

@description('Value of the secret from Key Vault.')
@secure()
param Keyvault_SecretValue string

var KeyVaultName_var = '${Application_Name}-vault'
var KeyVaultUri = 'https://${KeyVaultName_var}.vault.azure.net/'
var AppServicePlanName_var = '${Application_Name}Plan'
var AppServiceName_var = Application_Name
var StorageAccountName_var = '${toLower(replace(Application_Name, '-', ''))}storage'
var StorageAccountResourceId = StorageAccountName.id
var Tags = {
  environment: Application_Environment
  version: Application_Version
  releaseName: Release_Name
  createdBy: Release_Url
  branch: Release_SourceCodeBranch
  triggeredBy: Release_RequestedFor
  triggerType: Release_TriggerType
}

resource default 'Microsoft.Resources/tags@2019-10-01' = {
  name: 'default'
  properties: {
    tags: Tags
  }
  dependsOn: []
}

resource StorageAccountName 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: StorageAccountName_var
  location: Location
  tags: Tags
  sku: {
    name: Storage_SkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource StorageAccountName_default 'Microsoft.Storage/storageAccounts/tableServices@2022-05-01' = {
  parent: StorageAccountName
  name: 'default'
}

resource StorageAccountName_default_StorageAccountTableName 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-05-01' = {
  parent: StorageAccountName_default
  name: StorageAccountTableName
  properties: {}
  dependsOn: [
    StorageAccountName
  ]
}

resource AppServicePlanName 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: AppServicePlanName_var
  location: Location
  tags: Tags
  sku: {
    name: AppSvcPlan_SkuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource AppServiceName 'Microsoft.Web/sites@2020-06-01' = {
  name: AppServiceName_var
  location: Location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: AppServicePlanName.id
    siteConfig: {
      linuxFxVersion: Appication_LinuxFxVersion
    }
  }
}

resource AppServiceName_appsettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: AppServiceName
  name: 'appsettings'
  properties: {
    VaultUri: KeyVaultUri
    StorageAccountTableName: StorageAccountTableName
    EncryptionKey1: '@Microsoft.KeyVault(SecretUri=https://${KeyVaultName_var}.vault.azure.net/secrets/${Keyvault_SecretName}/)'
    EncryptionKey2: '@Microsoft.KeyVault(SecretUri=https://aca-devops-vault.vault.azure.net/secrets/EncryptionKey/)'
    WEBSITE_DYNAMIC_CACHE: '0'
    WEBSITE_LOCAL_CACHE_OPTION: 'Never'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
  dependsOn: [
    KeyvaultName
    KeyvaultName_Keyvault_SecretName
  ]
}

resource AppServiceName_connectionstrings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: AppServiceName
  name: 'connectionstrings'
  properties: {
    'StorageAccount.ConnectionString': {
      value: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName_var};AccountKey=${listKeys(StorageAccountResourceId, '2019-06-01').keys[0].value}'
      type: 'Custom'
    }
  }
}

resource KeyvaultName 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: KeyVaultName_var
  location: Location
  tags: Tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    tenantId: Keyvault_TenantId
    accessPolicies: [
      {
        tenantId: Keyvault_TenantId
        objectId: Keyvault_ObjectId
        permissions: {
          keys: [
            'list'
            'get'
          ]
          secrets: [
            'list'
            'get'
          ]
          certificates: []
        }
      }
      {
        tenantId: Keyvault_TenantId
        objectId: reference(AppServiceName.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'get'
          ]
        }
      }
      {
        tenantId: '7517bc42-bcf8-4916-a677-b5753051f846'
        objectId: '93054fe9-1538-442c-96fd-2040f61f3a99'
        permissions: {
          keys: []
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: []
        }
      }
    ]
    sku: {
      name: Keyvault_SkuName
      family: 'A'
    }
  }
}

resource KeyvaultName_Keyvault_SecretName 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: KeyvaultName
  name: '${Keyvault_SecretName}'
  tags: Tags
  properties: {
    value: Keyvault_SecretValue
  }
}