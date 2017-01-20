
## ---------- Working with SQL Server ---------- ##
 
## - Get SQL Server Table data:

Try
{
    $ErrorActionPreference = "Stop"

    $SQLServer = 'localhost'

    $SqlQuery = @'
declare @dbname varchar(60)
declare @State tinyint
declare @sqlstmt varchar(2000)

declare cur_Fix cursor
for
select name,state from sys.databases 
where state in (6,5,4,3) order by name asc

open cur_Fix
fetch next from cur_Fix into @dbname,@state
while @@FETCH_STATUS=0
begin
if @State =6
begin 
     
                set @sqlstmt =  'alter database ' + '['+@dbname+ ']'+ ' Set Online; ' 
                exec (@sqlstmt)
                --print @sqlstmt
                --print'go'
				Print + @dbname +' has been set Online'
               
end

if @State in(3,5,4)
begin 
set @sqlstmt =  'ALTER DATABASE' + '['+@dbname+ ']'+ 'SET EMERGENCY;' +
                'ALTER DATABASE' + '['+@dbname+ ']'+ 'SET SINGLE_USER;'+
				'DBCC CHECKDB' + '(' +'['+@dbname+ ']'+','+ 'REPAIR_ALLOW_DATA_LOSS' +') WITH NO_INFOMSGS,ALL_ERRORMSGS;'+
				'ALTER DATABASE'+ '['+@dbname+ ']'+ 'SET Multi_User;';
                exec (@sqlstmt)
                --Print @sqlstmt
                --Print'go'
				Print 'Log Has Been Rebuild for Database '+@dbname

end

fetch next from cur_fix  into @dbname,@State
end
close cur_fix
deallocate cur_fix
'@
 
## - Connect to SQL Server using non-SMO class 'System.Data':
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $SQLServer; Integrated Security = True"
    #$SqlConnection.ConnectionString = "Server = $SQLServer;uid=sa;pwd=Pass@123;Integrated Security = False"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection

    ## - Extract and build the SQL data object '$DataSetTable'
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $Sqlconnection.FireInfoMessageEventOnUserErrors=$true

    $res = New-Object System.Collections.ArrayList
    #...
    #$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Host "$($_)"}
    $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { $res.Add("$($_)")}
    $Sqlconnection.add_InfoMessage($handler)
    $SqlConnection.Open()
    $result = $SqlCmd.ExecuteNonQuery()

    if($?)
    {
        <#$NewArrayObj = New-Object System.Collections.ArrayList
        foreach($a in $res)
        {
            if(($a -eq 'go') -and ($a))
            {
                Continue
            }
            else
            {
                $Obj = New-Object psobject
                $db = ($a.Split('[')).Split(']')[1]
                $diskpath = $a.split("=")[1].trim()

                $obj | Add-Member -MemberType NoteProperty -Name "Database Name" -Value $db
                $Obj | Add-Member -MemberType NoteProperty -Name "Disk Path" -Value $diskpath
            }
            $NewArrayObj += $Obj
        }
        #>
        $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
        #$ParentFolder = $CurrentDir.Substring(0,$CurrentDir.LastIndexOf("\"))

        if(Test-Path "$PSScriptRoot\..\Output")
        {
            # skip
        }
        Else
        {
            $data = (New-Item -Path "$PSScriptRoot\..\" -Name Output -ItemType Directory -Force -ErrorAction Stop).FullName
        }

        $BackUpdbs = "$PSScriptRoot\..\Output\BackUpdbs.txt"

        $NewArrayObj | Out-File $BackUpdbs -Force

    }
    else
    {
        Write-Output "The query did not return anything"
    }
}
catch
{
    $Error[0].exception.Message
}
 
## - End of Script - ##