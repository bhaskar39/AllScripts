# To pull the data from Azure for VM Sizes
$AppSecretKey = "FTaN7/A5X2okYRc5xkee/AVokyNP3BJ7UqbCOqBRzTo="
$ClientID = "ec4c2b83-79e9-48d5-830b-cbcbf3b0a66f"
$TenantID = "163304dc-3d1d-40d1-9589-7e1673369634"
$SubscriptionID = "ca68598c-ecc3-4abc-b7a2-1ecef33f278d"

Function New-AzureRestAuthorizationHeader 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [String]$ClientId, 
        [String]$ClientKey, 
        [String]$TenantId
    ) 

    try
    {
        # Import ADAL library to acquire access token 
        # $PSScriptRoot only work PowerShell V3 or above versions 
        Add-Type -Path "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll" 
        Add-Type -Path "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll" 

        # Authorization & resource Url 
        $authUrl = "https://login.windows.net/$TenantId/" 
        $resource = "https://management.core.windows.net/" 

        # Create credential for client application 
        $clientCred = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential]::new($ClientId, $ClientKey) 

        # Create AuthenticationContext for acquiring token 
        $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authUrl, $false) 

        # Acquire the authentication result 
        $authResult = $authContext.AcquireTokenAsync($resource, $clientCred).Result 

        # Compose the access token type and access token for authorization header 
        $authHeader = $authResult.AccessTokenType + " " + $authResult.AccessToken 

        # the final header hash table 
        return @{"Authorization"=$authHeader; "Content-Type"="application/json"}
    }
    catch
    {
        Write-Output "There was an error in fetching the AccessToken from Azure. $($Error[0].Exception.Message)"
    }
}

Function Update-Table
{
    Param
    (
        $CSVPath
    )

    Try
    {        
        $SqlCommand1 = @"
        USE master;  
        EXEC sp_configure 'show advanced option', '1'; 
        sp_configure 'Ad Hoc Distributed Queries',1
        GO
"@
        $SqlCommand2 = "select * INTO VMConfig from openrowset('MSDASQL','Driver={Microsoft Access Text Driver (*.txt, *.csv)}','select * from "+ $CSVPath+"')"

        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server=localhost;Integrated Security=True;User Id=ebabula;Password=pass12345@word"
        $SqlConnection.Open()
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.Connection = $SqlConnection
        $SqlCmd.CommandText = $SqlCommand1
        $SqlCmd.ExecuteNonQuery()

        $SqlCmd.CommandText = $SqlCommand2
        $SqlCmd.Connection = $SqlConnection
        $SqlCmd.ExecuteNonQuery()
    }
    Catch
    {
        Write-Output "There was an error while updating the VMConfig data to Database.$($Error[0].Exception.Message)"
        exit
    }
}


Try
{
    $Headers = New-AzureRestAuthorizationHeader -ClientId $ClientID -ClientKey $AppSecretKey -TenantId $TenantID
    if($Headers -ne $null)
    {
        $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
        $URI = "https://management.azure.com/subscriptions/ca68598c-ecc3-4abc-b7a2-1ecef33f278d/providers/Microsoft.Compute/locations/westus/vmSizes?api-version=2015-05-01-preview"
        $Data = Invoke-RestMethod -Method Get -Uri $URI -Headers $Headers
        #$Rdata = 
        if($Data -ne $null)
        {
            $CSVFilePath = "$PSScriptRoot\sizes.csv"
            $OutFile = $Data.value | export-csv -Path $CSVFilePath -NoTypeInformation -Force
            #$FOutPut = Update-Table -CSVPath $CSVFilePath
        }
        Else
        {
            Write-Output "There was error while pulling the VMConfig data from Azure. $($Error[0].Exception.Message)"
        }
    }
    else
    {
        Write-Output "Unable to get the Access Token."
    }
}
catch
{
    Write-Output "There was error while fetching and updating the data for VMConfig.$($Error[0].Exception.Message)"
}