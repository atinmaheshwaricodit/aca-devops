// Parameters
@description('Provide the object that contains all info about the common infrastructure.')
param infra object

@description('provides function name')
param functionName string

@description('Provide info about the release that deployed this resource.')
param releaseInfo object

@description('Provides app settings for this function and its staging slot')
param appSettings array

param appServicePlanName string = '${infra.environment.resourcePrefix}-consumptionplan'

param location string = resourceGroup().location

// Variables
var commonAppSettings = [
  {
    name: 'AzureWebJobsSecretStorageType'
    value: 'Files'
  }
  {
    name: 'USER_ASSIGNED_MANAGED_IDENTITY'
    value: infra.managedIdentity.clientId
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: reference(resourceId(infra.environment.resourceGroupName, 'Microsoft.Insights/components', '${infra.environment.resourcePrefix}-appInsights'), '2020-02-02').ConnectionString
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${infra.storageAccount.name};AccountKey=${listKeys(infra.storageAccount.id, '2015-05-01-preview').key1}'
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: functionName
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${infra.storageAccount.name};AccountKey=${listKeys(infra.storageAccount.id, '2015-05-01-preview').key1}'
  }
  {
    name: 'IsDeveloperMode'
    value: 'false'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet'
  }
]

var allAppSettings = union(appSettings, commonAppSettings)

// Resources
resource site 'Microsoft.Web/sites@2021-02-01' =  {
  name: functionName
  location: location
  tags: {
    displayName: functionName
    releaseName: releaseInfo.release.name
    version: releaseInfo.release.version
    createdBy: releaseInfo.release.url
    triggeredBy: releaseInfo.deployment.requestedFor
    triggerType: releaseInfo.deployment.triggerType
  }
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${infra.managedIdentity.id}': {}
    }
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${functionName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: resourceId(infra.environment.resourceGroupName, 'Microsoft.Web/serverfarms', appServicePlanName)
    reserved: false
    siteConfig: {
      appSettings: allAppSettings
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      alwaysOn: false
    }
    isXenon: false
    hyperV: false
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
  }
}

resource siteConfig 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: site
  name: 'web'
  location: location
  tags: {
    displayName: functionName
    releaseName: releaseInfo.release.name
    version: releaseInfo.release.version
    createdBy: releaseInfo.release.url
    triggeredBy: releaseInfo.deployment.requestedFor
    triggerType: releaseInfo.deployment.triggerType
  }
  properties: {
    FUNCTIONS_EXTENSION_VERSION: '~4'
    AzureWebJobsSecretStorageType: 'Files'
    scmIpSecurityRestrictionsUseMain: false
    netFrameworkVersion: 'v6.0'
  }
}

resource authSettings 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: site
  name: 'authsettingsV2'
  location: location
  tags: {
    displayName: functionName
    releaseName: releaseInfo.release.name
    version: releaseInfo.release.version
    createdBy: releaseInfo.release.url
    triggeredBy: releaseInfo.deployment.requestedFor
    triggerType: releaseInfo.deployment.triggerType
  }
  properties: {
    platform: {
      enabled: true
      runtimeVersion: '~1'
    }
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: infra.authentication.issuer
          clientId: infra.authentication.internalClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        }
        login: {
          disableWWWAuthenticate: false
        }
        validation: {
          jwtClaimChecks: {}
          allowedAudiences: [
            infra.authentication.internalClientId
          ]
          defaultAuthorizationPolicy: {
            allowedPrincipals: {}
          }
        }
      }
      facebook: {
        enabled: true
        registration: {}
        login: {}
      }
      gitHub: {
        enabled: true
        registration: {}
        login: {}
      }
      google: {
        enabled: true
        registration: {}
        login: {}
        validation: {}
      }
      twitter: {
        enabled: true
        registration: {}
      }
      legacyMicrosoftAccount: {
        enabled: true
        registration: {}
        login: {}
        validation: {}
      }
      apple: {
        enabled: true
        registration: {}
        login: {}
      }
    }
    login: {
      routes: {}
      tokenStore: {
        enabled: false
        tokenRefreshExtensionHours: 72
        fileSystem: {}
        azureBlobStorage: {}
      }
      preserveUrlFragmentsForLogins: false
      allowedExternalRedirectUrls: []
      cookieExpiration: {
        convention: 'FixedTime'
        timeToExpiration: '08:00:00'
      }
      nonce: {
        validateNonce: true
        nonceExpirationInterval: '00:05:00'
      }
    }
    httpSettings: {
      requireHttps: true
      routes: {
        apiPrefix: '/.auth'
      }
      forwardProxy: {
        convention: 'NoProxy'
      }
    }
  }
}
