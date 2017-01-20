$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "integrated security=false;Database=ASSESS-MGMT;server=localhost;uid=sa;pwd=pass12345@word"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "p_CreateCustomer"
$SqlCmd.Connection = $SqlConnection
$SqlCmd.CommandType = [System.Data.CommandType]'StoredProcedure';
$SqlCmd.Parameters.AddWithValue("@PartnerName", "NetEnrich1") >> $null;
$SqlCmd.Parameters.AddWithValue("@ClientName", "NetEnrich2") >> $null;
$SqlCmd.Parameters.AddWithValue("@Region", "East Asia") >> $null;
#$SqlCmd.Parameters.AddWithValue("@keycolumn", "$KeyColumn") >> $null;
$outParameter = new-object System.Data.SqlClient.SqlParameter;
$outParameter.ParameterName = "@outDBName";
$outParameter.Direction = [System.Data.ParameterDirection]'Output';
$outParameter.DbType = [System.Data.DbType]'string';
$outParameter.Size=50;
$SqlCmd.Parameters.Add($outParameter) >> $null;
$SqlConnection.Open();
$result = $SqlCmd.ExecuteNonQuery();
$DBShortCo = $SqlCmd.Parameters["@outDBName"].Value;
$SqlConnection.Close();
$truth;