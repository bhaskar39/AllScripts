#START NETWORK TRACES ON REMOTE COMPUTERS
#Specify target computer name
$computers= @("13.68.109.96")
$creds = New-Object System.Management.Automation.PSCredential ('ebabula',(ConvertTo-SecureString -AsPlainText -String pass12345@word -Force))
#Drive letter on remote computers to create output folder under
$drive="C"

#Folder path on remote computers to save output file to
$directory="TEMP\TRACES"
$path= $drive + ":\" + $directory

#SCRIPTBLOCK TO BE EXECUTED ON EACH TARGET COMPUTER
$scriptBlockContent=
{
    param ($localoutputpath,$tracefullpath)

    #Verify that output path & folder exists. If not, create it.
    if((Test-Path -isValid $localoutputpath))
    {
        New-Item -Path $localoutputpath -ItemType directory
    }

    #Start network trace and output file to specified path
    netsh trace start capture=yes tracefile=$tracefullpath
}

#Loop to execute scriptblock on all remote computers
ForEach ($computer in $computers)
{
    $file= $computer + ".etl"
    $output= $path + "\" + $file
    Invoke-Command -ComputerName $computer -ScriptBlock $ScriptBlockContent -ArgumentList $path, $output -Credential $creds
}

#Loop to check for “X” key
While($True)
{
    $Continue= Read-Host "Press 'X' To Stop the Tracing"
    If ($Continue.ToLower() -eq "x")
    {
        #STOP NETWORK TRACES ON REMOTE COMPUTERS
        #Run 'netsh trace stop' on each target computer
        ForEach ($computer in $computers)
        {
            $oData = Invoke-Command -ComputerName $computer -Credential $creds -ScriptBlock {
                #$c = $args[0]
                netsh trace stop
                #$data = Get-Content "C:\TEMP\TRACES\$c.etl"
                #$data
            } -ArgumentList $computer

            #Set-Content -Value $oData -Path "C:\Temp\$computer.etl"
        }

        #COLLECT TRACES
        #Copy network traces from each target computer to a folder on the local server
        ForEach ($computer in $computers)
        {
            $file= $computer + ".etl"
            $unc= "\\" + $computer + "\" + $drive + "$\" + $directory

            #Specify directory on local computer to copy all network traces to
            #NOTE: There is no check to verify that folder exists.
            $localdirectory="C:\Temp"
            $tracefile= $unc + "\" + $file
            #Copy-Item -Path $tracefile -Destination $localdirectory 
            New-PSDrive -Name J -PSProvider FileSystem -Persist -Root $unc -Credential $creds
            Copy-Item -Path "J:\$computers.etl" -Destination $localdirectory -Force
            #-Credential $creds   #    $tracefile $localdirectory -Credential $creds
            #Start-BitsTransfer -Source $tracefile -Destination $localdirectory -Credential $creds
            Write-Host $file "copied successfully to" $localdirectory
            Remove-PSDrive -Name J -PSProvider FileSystem -Force
        }
        break
    }

}