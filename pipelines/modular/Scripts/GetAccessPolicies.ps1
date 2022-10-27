Install-Module -Name Arcus.Scripting.KeyVault -AllowClobber -Force -Scope CurrentUser
$accessPolicies = Get-AzKeyVaultAccessPolicies -KeyVaultName "#{Infra_Secrets_KeyVault_Name}#" -ResourceGroupName "#{Infra_ResourceGroup_Name}#"
$accessPoliciesJson = $accessPolicies | ConvertTo-Json -Depth 5 -Compress
Write-Host ("##vso[task.setvariable variable=accessPolicies;]$accessPoliciesJson")