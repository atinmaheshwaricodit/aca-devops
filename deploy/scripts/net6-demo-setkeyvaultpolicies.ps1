
Login-AzAccount
Get-AzAdUser -UserPrincipalName "helena.coppieters@codit.eu"

Get-AzADServicePrincipal -DisplayName "dev-we-lab-app"
UserPrincipalName "Helena.Coppieters@codit.eu"
Set-AzContext -SubscriptionId "533f6b10-3a70-4c5d-8962-8b51e839a13c"
-BypassObjectIdValidation 
Set-AzKeyVaultAccessPolicy -VaultName 'dev-we-lab-app-vault' -UserPrincipalName 'Helena.Coppieters@codit.eu' -PermissionsToSecrets set,delete,get -PassThru

Get-AzADServicePrincipal -DisplayName "codit-automation-sp"


Set-AzKeyVaultAccessPolicy -SubscriptionId "533f6b10-3a70-4c5d-8962-8b51e839a13c" -VaultName "dev-we-lab-app-vault" -ObjectId "d72cc826-44d3-4dd1-a8d3-741a883ff8f7" -PermissionsToSecrets Get
Set-AzKeyVaultAccessPolicy -SubscriptionId "533f6b10-3a70-4c5d-8962-8b51e839a13c" -VaultName "dev-we-lab-app-vault" -ObjectId "d72cc826-44d3-4dd1-a8d3-741a883ff8f7" -PermissionsToSecrets Get

Write-Host "*** Completed"