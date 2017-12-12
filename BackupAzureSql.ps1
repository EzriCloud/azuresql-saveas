Param(
    [String] $SubscriptionId,
    [String] $TenantId,
    [String] $ApplicationId,
    [String] $ApplicationKey,
    [String] $DBResourceGroup,
    [String] $PasswordVaultName,
    [String] $DBServer,
    [String] $Databases,
    [String] $DumpResourceGroup,
    [String] $DumpStorageAccount,
    [Switch] $ProvideUpdates

    
)


Function Login-Azure {
    Param(
        [Parameter(ParameterSetName='ServicePrincipal')]
        [String] $TenantId,
        [Parameter(ParameterSetName='ServicePrincipal')]
        [String] $SubscriptionId,
        [Parameter(ParameterSetName='ServicePrincipal')]
        [String] $ApplicationId,
        [Parameter(ParameterSetName='ServicePrincipal')]
        [String] $ApplicationKey
    )

    try {

        $currentContext = Get-AzureRmContext
    } catch {
        Write-Host "It appears you are not logged in."
        $currentContext = $null;
    }


    if (!$currentContext) {
        if ($ApplicationKey) {
            $secpasswd = ConvertTo-SecureString $ApplicationKey -AsPlainText -Force
            $mycreds = New-Object System.Management.Automation.PSCredential ($ApplicationId, $secpasswd)
            Write-Host "Attempting Service User Login"
            Login-AzureRmAccount -ServicePrincipal -Credential $mycreds -TenantId $TenantId -SubscriptionId $SubscriptionId
        }
        else {
            Login-AzureRmAccount
        }

        Select-AzureRmSubscription -SubscriptionId $SubscriptionId
        Set-AzureRmContext -SubscriptionId $subscriptionId
    }

   
}


if ($ApplicationKey) {
    Login-Azure -TenantId $TenantId -SubscriptionId $SubscriptionId -ApplicationId $ApplicationId -ApplicationKey $ApplicationKey
} else {
    Login-Azure
}


Function Get-VaultSecret {
Param(
    [Parameter(Mandatory=$true)]
    [String] $VaultName,

    [Parameter(Mandatory=$true)]
    [String] $SecretName,

    [Switch] $SecureString
)

 
    $secret = Get-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName

    if ($SecureString) {
        return ConvertTo-SecureString -String $secret.SecretValueText -AsPlainText -Force
    }

    return $secret.SecretValueText;

    

}


Function Save-Database {
Param(
    [Parameter(Mandatory=$true)]
    [String] $DatabaseName,

    [Parameter(Mandatory=$true)]
    [String] $ResourceGroup,

    [Parameter(Mandatory=$true)]
    [String] $ServerName,

    [Parameter(Mandatory=$true)]
    [String] $PasswordVaultName,

    [Parameter(Mandatory=$true)]
    [String] $DumpResourceGroup,

    [Parameter(Mandatory=$true)]
    [String] $DumpStorageAccount

    

    
)
    $sqlServer = Get-AzureRmSqlServer -ResourceGroupName $ResourceGroup -ServerName $ServerName
    $sqlPassword = (Get-VaultSecret -VaultName $PasswordVaultName -SecretName "$ServerName-$($sqlServer.SqlAdministratorLogin)" -SecureString)
    $sqlCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($($sqlServer.SqlAdministratorLogin), $sqlPassword)


    # Generate a unique filename for the BACPAC
    $bacpacFilename = $DatabaseName + (Get-Date).ToString("dd") + ".bacpac"

    # Storage account info for the BACPAC
    $storageContainer = 
    $BaseStorageUri = "https://"+ $DumpStorageAccount + ".blob.core.windows.net/" + $DatabaseName.Replace("_","").ToLower() + "/"
    $BacpacUri = $BaseStorageUri + $bacpacFilename


    $dumpStorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $DumpResourceGroup -Name $DumpStorageAccount)[0].Value


    $exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $ResourceGroup -ServerName $ServerName `
       -DatabaseName $DatabaseName -StorageKeytype StorageAccessKey -StorageKey $dumpStorageKey -StorageUri $BacpacUri `
       -AdministratorLogin $sqlCreds.UserName -AdministratorLoginPassword $sqlCreds.Password

    return ($exportRequest)

}


$responses =  [System.Collections.ArrayList]@()

$Databases.split(",") | ForEach-Object {
    Write-Host "Saving $_ as bacpac"
    $resp = Save-Database -DatabaseName $_ -ResourceGroup $DBResourceGroup -ServerName $DBServer -PasswordVaultName $PasswordVaultName -DumpResourceGroup $DumpResourceGroup -DumpStorageAccount $DumpStorageAccount
    $responses.Add($resp)
}
    

Write-Host $responses


if ($ProvideUpdates) {

    $inProgress = $true
    
    while ($inProgress = $true) {

            $inProgress = $false

            $responses | ForEach-Object {
                $latestStatus = (Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $_.OperationStatusLink)
                $latestStatusCode = $latestStatus.Status

                if ($latestStatusCode.Equals("InProgress")) {
                   $inProgress = $true
                   Write-Host $_ $latestStatus.Status
                }

            }

            Start-Sleep -s 32

        

    }
    




}
Write-Host "Script completed"