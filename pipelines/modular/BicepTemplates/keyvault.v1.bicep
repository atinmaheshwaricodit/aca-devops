// Parameters
param infra object

@secure()
param secrets object = {}

// Secrets in Key Vault
resource keyvaultSecrets 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview'  = [for secret in items(secrets): {
  name: '${infra.secrets.keyVault.name}/${secret.key}'
  properties: {
    contentType: 'text/plain'
    value: secret.value
  }
}]
