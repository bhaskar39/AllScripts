Param
(
    [Parameter(Mandatory=$true)]
    $SourcePath,
    [Parameter(Mandatory=$true)]
    $destinationPath
)

Try
{
    If(!(Test-Path -Path $destinationPath))
    {
        $FolderStatus = New-Item -Path $destinationPath -ItemType Directory -Force -ErrorAction Stop
    }
    if(Test-Path -Path $SourcePath)
    {
        $Status = Copy-Item -Path $SourcePath -Destination $destinationPath -Force -ErrorAction Stop
        if($? -eq $true)
        {
            Write-Output "File has been copied successfully"
        }
        Else
        {
            Write-Output "There was error in copying the file"
        }
    }
    Else
    {
        Write-Output "The Given Source Path does not exist"
    }
}
Catch
{
    Write-Output "$($Error[0].Exception.Message)" 
}