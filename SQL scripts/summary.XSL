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
<fieldset>

<fieldset style="text-align:left;">
<legend><font color="#2B60DE"><h3><b>Overall Summary/issues</b></h3></font></legend>

<h4>Database Status Summary</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Server</TH>
<TH bgcolor="#B7CEEC">Online</TH>
<TH bgcolor="#B7CEEC">Offline</TH>
<TH bgcolor="#B7CEEC">Total</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/instance/totaldbStatus/sdb"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@insName"/></TD>
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@online"/></font></TD>
<xsl:if test="./@offline!=0">
<TD bgcolor="#C2DFFF"><font color="#FF0000"><xsl:value-of select="@offline"/></font></TD>
</xsl:if>
<xsl:if test="./@offline=0">
<TD bgcolor="#C2DFFF"><font color="#347C17"><xsl:value-of select="@offline"/></font></TD>
</xsl:if>

<TD bgcolor="#C2DFFF"><b><xsl:value-of select="@total" /></b></TD>
</TR>
</xsl:for-each>
</TABLE>
<xsl:if test="count(root/instance/failedJobs[@chk='1'])!=0">
<h4>Failed scheduled job(s)</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Server</TH>
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
<xsl:for-each select="root/instance/failedJobs/fj"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@insName"/></TD>
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
<xsl:if test="count(root/instance/failedJobs[@chk='1'])=0"><br />
<b>* All scheduled jobs on all servers executed and finished successfully without anyissues</b>
</xsl:if>
<xsl:if test="count(root/instance/lowDbSpace[@chk='1'])!=0">
<h4>Low free space database(s) \ file(s)</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Server</TH>
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
<xsl:for-each select="root/instance/lowDbSpace/lds"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@insName"/></TD>
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
<xsl:if test="count(root/instance/lowDbSpace[@chk='1'])=0"><br />
<b>* All databases have enough free space(>=5%)</b>
</xsl:if>
<xsl:if test="count(root/instance/lowDiscSpace[@chk='1'])!=0">
<h4>Low space disk drive(s)</h4>
<TABLE border="0">
<TR>
<TH bgcolor="#B7CEEC">Server</TH>
<TH bgcolor="#B7CEEC">Drive Name</TH>
<TH bgcolor="#B7CEEC">Free Space(GB)</TH>
</TR>
<!--Set up a loop for each match on the pattern defined in the select
below, write out a table row-->
<xsl:for-each select="root/instance/lowDiscSpace/ld"> 
<TR>
<!--Place each attribute in cell in table-->
<TD bgcolor="#C2DFFF"><xsl:value-of select="@insName"/></TD>
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
<xsl:if test="count(root/instance/lowDiscSpace[@chk='1'])=0"><br />
<b>* All disk drives have enough free space(>=2)</b>
</xsl:if>

</fieldset>
<a href="#top" style="float:right">Go to Top</a>
</fieldset>
</BODY>
</xsl:template>
</xsl:stylesheet>

