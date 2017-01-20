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
        $JSONData
    )

    Try
    {        
        #$SqlCommand2 = "select * INTO VMConfig from openrowset('MSDASQL','Driver={Microsoft Access Text Driver (*.txt, *.csv)}','select * from "+ $CSVPath+"')"

        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server=devvm.eastus2.cloudapp.azure.com;Database='ASSESS-MGMT';Integrated Security=False;uid=sqladmin;pwd=pass123@word"
        $SqlConnection.Open()
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand

        foreach($da in $JSONData)
        {
            $Sqlquery = @"
                update Meters
                set EffectiveDate = `'$($da.EffectiveDate)`'
                where MeterId = `'$($da.MeterId)`'

               update MeterRates
                set Price = `'$($da.MeterRates.'0')`'
               where MeterId = `'$($da.MeterId)`'
"@
            $SqlCmd.CommandText = $Sqlquery
            $SqlCmd.Connection = $SqlConnection
            $SqlCmd.ExecuteNonQuery()
        }
        $SqlConnection.Close()

    }
    Catch
    {
        Write-Output "There was an error while updating the Ratecard data to Database.$($Error[0].Exception.Message)"
        exit
    }
}


Try
{
    $Headers = New-AzureRestAuthorizationHeader -ClientId $ClientID -ClientKey $AppSecretKey -TenantId $TenantID
    if($Headers -ne $null)
    {
        #$CSVFilePath  = "C:\CSVFilePath.csv"
        $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
        $URI = "https://management.azure.com/subscriptions/ca68598c-ecc3-4abc-b7a2-1ecef33f278d/providers/Microsoft.Commerce/RateCard?api-version=2015-06-01-preview&"+'$filter=OfferDurableId eq '+"'MS-AZR-0003P' and Currency eq 'USD' and Locale eq 'en-US' and RegionInfo eq 'US'"
        $Data = Invoke-RestMethod -Method Get -Uri $URI -Headers $Headers
        #$Rdata = 
        if($Data -ne $null)
        {
            $OutFile = $Data | ConvertTo-Json | Out-File -FilePath "$PSScriptRoot\meters.json" -Force
            $FOutPut = Update-Table -JSONData $($Data.Meters)

            "Success"
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