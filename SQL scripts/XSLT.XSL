<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/"> 
<!--Apply template to everything-->
<!--HTML HEAD SECTION-->
<HEAD>
<TITLE>Checklist for SQL Server</TITLE>
<style type="text/css">
h3 {color:#2B60DE}
TH {color:BLACK}
h4 {color:#25587E}
</style>
</HEAD>
<BODY >
<xsl:if test="root/uptime/@time!=''">
<fieldset>
<fieldset style="text-align:center;"><a><xsl:attribute name="name"><xsl:if test="contains(root/server/@name, '\')=1">
<xsl:value-of select="substring-before(root/server/@name,'\')"/><xsl:value-of select="substring-after(root/server/@name,'\')"/></xsl:if><xsl:if test="contains(root/server/@name, '\')=0">
<xsl:value-of select="root/server/@name"/></xsl:if></xsl:attribute><h2>Database Checklist for <font color="#566D7E"><xsl:value-of select="root/server/@name"/></font> as on <font color="#566D7E"><xsl:value-of select="root/date"/></font></h2></a>
<h4>SQL Server Uptime: <font color="#347C17"><xsl:value-of select="root/uptime/@time"/></font></h4>
</fieldset>
<fieldset style="text-align:left;">
<legend><font color="black"><h3><b>Summary/issues</b></h3></font></legend>

<h4>Database Status Summary</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Status</TH>
<TH bgcolor="#B7CEEC">Count</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/dbsummary/sdb"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@status"/></TD>
<xsl:if test="./@status='OFFLINE' and ./@count!='0'">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@count"/></font></TD>
</xsl:if>
<xsl:if test="./@status='OFFLINE' and ./@count='0'">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@count"/></font></TD>
</xsl:if>
<xsl:if test="./@status!='OFFLINE'">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@count"/></font></TD>
</xsl:if>
</TR>
</xsl:for-each>
</TABLE>

<xsl:if test="root/failedJobs/@chk=1">
<h4>Failed scheduled job(s)</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">JobName</TH>
<TH bgcolor="#B7CEEC">Last Run Status</TH>
<TH bgcolor="#B7CEEC">Last Run Date</TH>
<TH bgcolor="#B7CEEC">Next Run Date</TH>
<TH bgcolor="#B7CEEC">Total Runs</TH>
<TH bgcolor="#B7CEEC">Success</TH>
<TH bgcolor="#B7CEEC">Failed</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/failedJobs/fj"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@jobName"/></TD>
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@lastRunStatus"/></font></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@lastRunDate"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@nextRunDate"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@totalRuns"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@success"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@failed"/></TD>
</TR>
</xsl:for-each>
</TABLE>
</xsl:if>
<xsl:if test="root/failedJobs/@error=''">
<br />
<b><xsl:value-of select="root/failedJobs/@msg"/></b>
</xsl:if>
<br />
<font color="Red"><xsl:value-of select="root/failedJobs/@error"/></font>


<xsl:if test="root/lowDbSpace/@chk=1">
<h4>Low free space database(s) / file(s)</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Database Name</TH>
<TH bgcolor="#B7CEEC">DB Type</TH>
<TH bgcolor="#B7CEEC">File Type</TH>
<TH bgcolor="#B7CEEC">File Name</TH>
<TH bgcolor="#B7CEEC">Total(MB)</TH>
<TH bgcolor="#B7CEEC">Free(%)</TH>
<TH bgcolor="#B7CEEC">Autogrow</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/lowDbSpace/lds"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@dbName"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@type"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@fileType"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@fileName"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@totalMB"/></TD>
<xsl:if test="./@type!='SYSTEMDB'">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@freePct"/></font></TD>
</xsl:if>
<xsl:if test="./@type='SYSTEMDB'">
<TD bgcolor="#C2DFFF"><font color="#C35817"><xsl:value-of select="@freePct"/></font></TD>
</xsl:if>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@autoGrow"/></TD>
</TR>
</xsl:for-each>
</TABLE>
</xsl:if>
<br />
<b><xsl:value-of select="root/lowDbSpace/@msg"/></b>

<xsl:if test="root/lowDiscSpace/@chk=1">
<h4>Low space disk drive(s)</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Drive Name</TH>
<TH bgcolor="#B7CEEC">Free Space(GB)</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/lowDiscSpace/ld"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@drive"/></TD>
<xsl:if test="./@freeSpaceGB &lt; 2">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@freeSpaceGB"/></font></TD>
</xsl:if>
<xsl:if test="./@freeSpaceGB &gt; 2">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@freeSpaceGB"/></font></TD>
</xsl:if>
</TR>
</xsl:for-each>
</TABLE>
</xsl:if>
<br />
<b><xsl:value-of select="root/lowDiscSpace/@msg"/></b>
</fieldset>


<fieldset style="text-align:left;">
<legend><font color="black"><h3><b>Detailed Checklist</b></h3></font></legend>

<h4>SQL Server Services Status</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Service</TH>
<TH bgcolor="#B7CEEC">Type</TH>
<TH bgcolor="#B7CEEC">Status</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/services/st"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@serviceName"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@type"/></TD>
<xsl:if test="./@status='Stopped' and ./@type='Auto'">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@status"/></font></TD>
</xsl:if>
<xsl:if test="./@status='Stopped' and ./@type!='Auto'">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@status"/></font></TD>
</xsl:if>
<xsl:if test="./@status='Running'">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@status"/></font></TD>
</xsl:if>
</TR>
</xsl:for-each>
</TABLE>


<h4>Database Status</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Database Name</TH>
<TH bgcolor="#B7CEEC">DB Type</TH>
<TH bgcolor="#B7CEEC">Recovery Model</TH>
<TH bgcolor="#B7CEEC">Status</TH>
<TH bgcolor="#B7CEEC">Last Full Backup</TH>
<TH bgcolor="#B7CEEC">Last Log Backup</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/backupCheck/bc"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@databaseName"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@type"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@recoveryMode"/></TD>
<xsl:if test="./@status='OFFLINE'">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@status"/></font></TD>
</xsl:if>
<xsl:if test="./@status='ONLINE'">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@status"/></font></TD>
</xsl:if>
<xsl:if test="./@status='RESTORING'">
<TD bgcolor="#C2DFFF"><font color="#E56717"><xsl:value-of select="@status"/></font></TD>
</xsl:if>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@lastFullBackup"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@lastLogBackup"/></TD>
</TR>
</xsl:for-each>
</TABLE>



<h4>Database Files Status</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Database Name</TH>
<TH bgcolor="#B7CEEC">DB Type</TH>
<TH bgcolor="#B7CEEC">File Type</TH>
<TH bgcolor="#B7CEEC">File Name</TH>
<TH bgcolor="#B7CEEC">Total(MB)</TH>
<TH bgcolor="#B7CEEC">Used(MB)</TH>
<TH bgcolor="#B7CEEC">Free(MB)</TH>
<TH bgcolor="#B7CEEC">Used(%)</TH>
<TH bgcolor="#B7CEEC">Free(%)</TH>
<TH bgcolor="#B7CEEC">Autogrow</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/dbFileStatus/dfs"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@dbName"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@type"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@fileType"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@fileName"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@totalMB"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@usedMB"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@freeMB"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@usedPct"/></TD>
<xsl:if test="./@freePct &lt; 5 and ./@type!='SYSTEMDB'">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@freePct"/></font></TD>
</xsl:if>
<xsl:if test="./@freePct &lt; 5 and ./@type='SYSTEMDB'">
<TD bgcolor="#C2DFFF"><font color="#C35817"><xsl:value-of select="@freePct"/></font></TD>
</xsl:if>

<xsl:if test="./@freePct &gt; 5">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@freePct"/></font></TD>
</xsl:if>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@autoGrow"/></TD>
</TR>
</xsl:for-each>
</TABLE>


<h4>Jobs Status</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">JobName</TH>
<TH bgcolor="#B7CEEC">Last Run Status</TH>
<TH bgcolor="#B7CEEC">Last Run Date</TH>
<TH bgcolor="#B7CEEC">Next Run Date</TH>
<TH bgcolor="#B7CEEC">Total Runs</TH>
<TH bgcolor="#B7CEEC">Success</TH>
<TH bgcolor="#B7CEEC">Failed</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/jobStatus/js"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@jobName"/></TD>
<xsl:if test="./@lastRunStatus='FAILED'">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@lastRunStatus"/></font></TD>
</xsl:if>
<xsl:if test="./@lastRunStatus='SUCCESS'">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@lastRunStatus"/></font></TD>
</xsl:if>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@lastRunDate"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@nextRunDate"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@totalRuns"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@success"/></TD>
<TD bgcolor="#C2DFFF"><xsl:value-of select="@failed"/></TD>
</TR>
</xsl:for-each>
</TABLE>
<xsl:if test="root/jobStatus/@error=''">
<b><xsl:value-of select="root/jobStatus/@msg"/></b>
</xsl:if>
<font color="Red"><xsl:value-of select="root/jobStatus/@error"/></font>

<h4>Drive Details</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Drive Name</TH>
<TH bgcolor="#B7CEEC">Free Space(GB)</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/discSpace/ds"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@drive"/></TD>
<xsl:if test="./@freeSpaceGB &lt; 2">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@freeSpaceGB"/></font></TD>
</xsl:if>
<xsl:if test="./@freeSpaceGB &gt; 2">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@freeSpaceGB"/></font></TD>
</xsl:if>
</TR>
</xsl:for-each>
</TABLE>

</fieldset>
<a href="#top" style="float:right">Go to Top</a>
</fieldset>
</xsl:if>
</BODY>

</xsl:template>
</xsl:stylesheet>

