####################################################################
# MICROSOFT - Exchange 2010 Architecture Report
#
# File : E2K10_Architecture.ps1
# Version : 2.0
# Author : Pascal Theil & Franck Nerot
# Author Company : MICROSOFT
# Author Mail : ptheil@microsoft.com & franckn@microsoft.com
# Creation date : 12/09/2011
# Modification date : 19/09/2011
#
# Exchange 2010
# 
####################################################################

#===================================================================
# Settings
#===================================================================
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$AD = Get-AcceptedDomain | ?{$_.Default -eq "True"} 
$ADDN = $AD.DomainName
$Date = Get-Date
#===================================================================
# HTML Report Structure
#===================================================================

	$Report = @"
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
	<html ES_auditInitialized='false'><head><title>Audit</title>
	<META http-equiv=Content-Type content='text/html; charset=windows-1252'>
	<STYLE type=text/css>	
		DIV .expando {DISPLAY: block; FONT-WEIGHT: normal; FONT-SIZE: 8pt; RIGHT: 10px; COLOR: #ffffff; FONT-FAMILY: Arial; POSITION: absolute; TEXT-DECORATION: underline}
		TABLE {TABLE-LAYOUT: fixed; FONT-SIZE: 100%; WIDTH: 100%}
		#objshowhide {PADDING-RIGHT: 10px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; Z-INDEX: 2; CURSOR: hand; COLOR: #405774; MARGIN-RIGHT: 0px; FONT-FAMILY: Arial; TEXT-ALIGN: right; TEXT-DECORATION: underline; WORD-WRAP: normal}
		.heading0_expanded {BORDER-RIGHT: #bbbbbb 1px solid; PADDING-RIGHT: 5em; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 8px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; MARGIN-BOTTOM: -1px; MARGIN-LEFT: 0px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; CURSOR: hand; COLOR: #000000; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; HEIGHT: 2.25em; BACKGROUND-COLOR: #999999}
		.heading1 {BORDER-RIGHT: #bbbbbb 1px solid; PADDING-RIGHT: 5em; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 16px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; MARGIN-BOTTOM: -1px; MARGIN-LEFT: 5px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; CURSOR: hand; COLOR: #000000; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; HEIGHT: 2.25em; BACKGROUND-COLOR: #CCCCCC}
		.heading10 {BORDER-RIGHT: #bbbbbb 1px solid; PADDING-RIGHT: 5em; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 16px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; MARGIN-BOTTOM: -1px; MARGIN-LEFT: 5px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; CURSOR: hand; COLOR: #000000; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; HEIGHT: 2.25em; BACKGROUND-COLOR: #FF0000}
		.tableDetail {BORDER-RIGHT: #bbbbbb 1px solid; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 16px; FONT-SIZE: 8pt;MARGIN-BOTTOM: -1px; PADDING-BOTTOM: 5px; MARGIN-LEFT: 5px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; COLOR: #405774; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; BACKGROUND-COLOR: #f9f9f9}
		.filler {BORDER-RIGHT: medium none; BORDER-TOP: medium none; DISPLAY: block; BACKGROUND: none transparent scroll repeat 0% 0%; MARGIN-BOTTOM: -1px; FONT: 100%/8px Arial; MARGIN-LEFT: 43px; BORDER-LEFT: medium none; COLOR: #ffffff; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: medium none; POSITION: relative}
		.Solidfiller {BORDER-RIGHT: medium none; BORDER-TOP: medium none; DISPLAY: block; BACKGROUND: none transparent scroll repeat 0% 0%; MARGIN-BOTTOM: -1px; FONT: 100%/8px Arial; MARGIN-LEFT: 0px; BORDER-LEFT: medium none; COLOR: #405774; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: medium none; POSITION: relative; BACKGROUND-COLOR: #405774}
		td {VERTICAL-ALIGN: TOP; FONT-FAMILY: Arial}
		th {VERTICAL-ALIGN: TOP; COLOR: #000000; TEXT-ALIGN: left}
	</STYLE>
	<SCRIPT language=vbscript>
		strShowHide = 1
		strShow = "show"
		strHide = "hide"
		strShowAll = "show all"
		strHideAll = "hide all"
	
	Function window_onload()
		If UCase(document.documentElement.getAttribute("ES_auditInitialized")) <> "TRUE" Then
			Set objBody = document.body.all
			For Each obji in objBody
				If IsSectionHeader(obji) Then
					If IsSectionExpandedByDefault(obji) Then
						ShowSection obji
					Else
						HideSection obji
					End If
				End If
			Next
			objshowhide.innerText = strShowAll
			document.documentElement.setAttribute "ES_auditInitialized", "true"
		End If
	End Function
	
	Function IsSectionExpandedByDefault(objHeader)
		IsSectionExpandedByDefault = (Right(objHeader.className, Len("_expanded")) = "_expanded")
	End Function
	
	Function document_onclick()
		Set strsrc = window.event.srcElement
		While (strsrc.className = "sectionTitle" or strsrc.className = "expando")
			Set strsrc = strsrc.parentElement
		Wend
		If Not IsSectionHeader(strsrc) Then Exit Function
		ToggleSection strsrc
		window.event.returnValue = False
	End Function
	
	Sub ToggleSection(objHeader)
		SetSectionState objHeader, "toggle"
	End Sub
	
	Sub SetSectionState(objHeader, strState)
		i = objHeader.sourceIndex
		Set all = objHeader.parentElement.document.all
		While (all(i).className <> "container")
			i = i + 1
		Wend
		Set objContainer = all(i)
		If strState = "toggle" Then
			If objContainer.style.display = "none" Then
				SetSectionState objHeader, "show" 
			Else
				SetSectionState objHeader, "hide" 
			End If
		Else
			Set objExpando = objHeader.children.item(1)
			If strState = "show" Then
				objContainer.style.display = "block" 
				objExpando.innerText = strHide
	
			ElseIf strState = "hide" Then
				objContainer.style.display = "none" 
				objExpando.innerText = strShow
			End If
		End If
	End Sub
	
	Function objshowhide_onClick()
		Set objBody = document.body.all
		Select Case strShowHide
			Case 0
				strShowHide = 1
				objshowhide.innerText = strShowAll
				For Each obji In objBody
					If IsSectionHeader(obji) Then
						HideSection obji
					End If
				Next
			Case 1
				strShowHide = 0
				objshowhide.innerText = strHideAll
				For Each obji In objBody
					If IsSectionHeader(obji) Then
						ShowSection obji
					End If
				Next
		End Select
	End Function
	
	Function IsSectionHeader(obj) : IsSectionHeader = (obj.className = "heading1_expanded") Or (obj.className = "heading10_expanded") Or (obj.className = "heading1") Or (obj.className = "heading10") Or (obj.className = "heading2"): End Function
	Sub HideSection(objHeader) : SetSectionState objHeader, "hide" : End Sub
	Sub ShowSection(objHeader) : SetSectionState objHeader, "show": End Sub
	</SCRIPT>
	</HEAD>
	<BODY>
	<p><b><hr size="4" color="#FF0000"><font face="Arial" size="3">EXCHANGE 2010 ARCHITECTURE REPORT</font></b><br>
	<p><b><font face="Arial" size="1"color="#000000">Report generated on $Date <hr size="2" color="#FF00000"></font></p>
	<TABLE cellSpacing=0 cellPadding=0>
		<TBODY>
			<TR>
				<TD>
					<DIV id=objshowhide tabIndex=0><FONT face=Arial></FONT></DIV>
				</TD>
			</TR>
		</TBODY>
	</TABLE>
	<DIV class=heading0_expanded>
	<br><SPAN class=sectionTitle tabIndex=0><font face="Arial" size="2">Exchange Domaine Name : <font color='#0000FF'>$($ADDN)</font></SPAN><br><br>
	<A class=expando href='#'></A>
	</DIV>
	<DIV class=filler></DIV>

"@

Return $Report