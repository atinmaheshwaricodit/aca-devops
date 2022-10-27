// Parameters
param utcValue string = utcNow()
param infra object
param policyBaseUri string 
param openApiBaseUri string 
@secure()
param policySasToken string 
@secure()
param openApiSasToken string 

param operations array 
param namedValues object = {}
@secure()
param secrets object = {}
param majorVersion string = '1'
param minorVersion string = '0'
param apiName string
param apiDisplayName string
param description string

param apiProperties object

param tags array

// Variables
var apiVersionSanitized = replace('v${majorVersion}', '.', '-')
var minorVersionSanitized = ';rev=${minorVersion}'

var apiBasicProperties = {
  apiDisplayName: apiDisplayName
  apiVersion: 'v${majorVersion}'
  apiVersionSetId: apiVersionSet.id
  value: '${openApiBaseUri}/openapi.json${openApiSasToken}'
  format: 'openapi-link'
  description: description
}

// Operation level policies
resource apimOperationPolicies 'Microsoft.ApiManagement/service/apis/operations/policies@2021-01-01-preview' = [for operation in operations: {       
    name: '${infra.apim.name}/${apiName}-${apiVersionSanitized}${minorVersionSanitized}/${operation}/policy'
    properties: {
      value: '${policyBaseUri}/${operation}.xml${policySasToken}'
      format: 'rawxml-link'
    }
    dependsOn: [
      api
    ]
}]

// Named values
resource apimNamedValues 'Microsoft.ApiManagement/service/namedValues@2021-01-01-preview' = [for namedValue in items(namedValues): {       
  name: '${infra.apim.name}/${namedValue.key}'
  properties: {
    displayName: namedValue.key
    value: namedValue.value
    tags: []
    secret: false
  }
  dependsOn: []
}]

// Secrets in Key Vault
module keyvaultSecrets './keyvault.v1.bicep' = {
  name: 'keyvault-secret-${utcValue}'
  params: {
    infra: infra
    secrets: secrets
  }
}

resource apimsecrets 'Microsoft.ApiManagement/service/namedValues@2021-01-01-preview'  = [for secret in items(secrets): {
  name: '${infra.apim.name}/${secret.key}'
  properties: {
    displayName: secret.key
    tags: []
    secret: true
    keyVault: {
      identityClientId: '${infra.managedIdentity.clientId}'
      secretIdentifier: 'https://${infra.secrets.keyVault.name}${environment().suffixes.keyvaultDns}/secrets/${secret.key}'
    }
  }
  dependsOn: [
    keyvaultSecrets
  ]
}]

// Versionset
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
  name: '${infra.apim.name}/${apiName}'
  properties: {
    displayName: apiDisplayName
    versioningScheme: 'Segment'
    description: description
  }
  dependsOn: []
}

resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${infra.apim.name}/${apiName}-${apiVersionSanitized}${minorVersionSanitized}'
  properties: union(apiBasicProperties, apiProperties)
}

resource policy_base 'Microsoft.ApiManagement/service/apis/policies@2021-01-01-preview' = {
  name: '${infra.apim.name}/${apiName}-${apiVersionSanitized}${minorVersionSanitized}/policy'
  properties: {
    value: '${policyBaseUri}/API.xml${policySasToken}'
    format: 'rawxml-link'
  }
  dependsOn: [
    api
  ]
}

resource tag 'Microsoft.ApiManagement/service/tags@2021-01-01-preview' = [for item in tags: {       
  name: '${infra.apim.name}/${item}'
  properties: {
    displayName: '${item}'
  }
  dependsOn: [
    api
  ]
}]

resource apiTag 'Microsoft.ApiManagement/service/apis/tags@2021-01-01-preview' = [for item in tags: {
  name: '${infra.apim.name}/${apiName}-${apiVersionSanitized}${minorVersionSanitized}/${item}'
  dependsOn: [
    api
    tag
  ]
}]

resource symbolicname 'Microsoft.ApiManagement/service/apis/releases@2021-08-01' = {
  name: '${infra.apim.name}/${apiName}-${apiVersionSanitized}${minorVersionSanitized}/rev${minorVersion}'
  properties: {
    apiId: api.id
    notes: 'make revision as current'
  }
}

output id string = api.id
