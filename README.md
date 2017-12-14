
# AzureSQL-SaveAs

**NOTE** These scripts are designed to work for one specific purpose.  They were not generalized, and often have hard-coded database names in them.
If you want to use the scripts, review this documentation and update the scripts accordingly.


## On your CI Server
1. Run the `on-the-ci-server\01-create-databases-as-copy-of.sql` script.
1. For each of your newly created support databases, execute cleanup scripts `on-the-ci-servers\02-support_db_assistan.sql` . These scripts are specific to your needs and should be created any way you want.
1. `iwr -Uri 'https://raw.githubusercontent.com/EzriCloud/azuresql-saveas/master/BackupAzureSql.ps1' -OutFile 'BackupAzureSql.ps1'`
1. Setup your build variables with your Azure Secrets, and run 
1. Powershell Script `BackupAzureSql.ps1 -TenantId $(TenantId) -SubscriptionId $(SubscriptionId) -ApplicationId $(ApplicationId) -ApplicationKey $(ApplicationKey) -DBResourceGroup "MyDBResourceGroup" -DBServer "MyDbServerName" -PasswordVaultName "AzureVaultWhereIKeepMyPasswords" -Databases "Support_Production,Support_Staging" -DumpResourceGroup "ResourceGroupOfStorageAccount" -DumpStorageAccount "StorageAccountName" -ProvideUpdates`

## On your client machine

### To Download `Support_Production`
`DownloadBacpac.cmd azurecontainername Support_Production`

### To Restore `Support_Production` as `Support_ProductionMyOwnCopy`
`RestoreBacpac.cmd Support_Production MyOwnCopy`
