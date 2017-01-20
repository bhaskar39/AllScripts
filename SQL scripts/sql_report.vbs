On Error Resume Next
 
 
Set objFSO = CreateObject("Scripting.FileSystemObject")
filepath = objFSO.GetParentFolderName(WScript.ScriptFullName)
'Set oFile = objFSO.OpenTextFile(filepath & "\wsusconfig.ini", 1,false)
logPath = filepath & "\log"
logfile1 = logPath & "\sqlreport.xml"
checkFile1
xml1 = "<?xml version=""1.0""?><root>"
writeOutput1 ( xml1)
Set iFSO = CreateObject("Scripting.FilesyStemObject")
InputFile="serverlist.txt"
Set ifile = iFSO.OpenTextFile(inputfile)									   
Do until ifile.AtEndOfLine
 
	strComputer=ifile.ReadLine
    strComputer1=strComputer
	tokens = split(strComputer, " ")

	ubnd=UBound(tokens)

    If ubnd=0 Then 
	 strComputer=strComputer
	 strComputer1=strComputer
	Else 
	 strComputer=tokens(0)
	 strComputer1=tokens(0)
    End If
	intPos1 = InStr(strComputer,"\")
	If intPos1=0 Then
	   host= "MSSQLServer"
	   host1="(local)"
           host2=strComputer
	Else
	  host1= right(strComputer ,len(strComputer)-intPos1)
	  host="MSSQL$"& host1
          host2=left(strComputer ,intPos1-1)
	End If     
   'wscript.echo host
   If Reachable(host2) Then 
   serviceState=""
   Set objWMIService = GetObject("winmgmts:" _
			& "{impersonationLevel=impersonate}!\\" & host2 & "\root\cimv2")
			
			Set colServices = objWMIService.ExecQuery _
			("Select * from Win32_Service Where Name = '"&host&"'")

			'If colServices.Count > 0 Then
			For Each objService in colServices
				serviceState=objService.State
			Next
   Else
    serviceState="Not Reachable"
   End If
'wscript.echo host2&host&serviceState
	Dim logfile
	Dim filepath
	Dim objFSO

	Set objFSO = CreateObject("Scripting.FileSystemObject")
	filepath = objFSO.GetParentFolderName(WScript.ScriptFullName)
	'Set oFile = objFSO.OpenTextFile(filepath & "\wsusconfig.ini", 1,false)
	logPath = filepath & "\log"
	logfile = logPath & "\sqlreport"&host1&".xml"
	checkFile
    
   xml1 = "<instance name="""&strComputer1&""" error="""" >"
   xml = "<?xml version=""1.0""?><root><server name="""&strComputer1&""" error="""" />"
	writeOutput ( xml)
	writeOutput1 ( xml1)
	Set WshShell = CreateObject("WScript.Shell")
	'const ForAppending = 8
	If ubnd=0 Then
	 sCmd1 = "cmd.exe /c sqlcmd -S "&strComputer&" -E -i """& filepath & "\sql.txt"" >> output"&host1&".xml"
	'wscript.echo sCmd1
	Else 
     sCmd1 = "cmd.exe /c sqlcmd -S "&strComputer&" -U sa -P Job1!boss -i """& filepath & "\sql.txt"" >> output"&host1&".xml"
    'wscript.echo sCmd1
	End If
	iRC1 = WshShell.Run(sCmd1, 0,True)


					DirIn = "output"&host1&".xml"
					DirOut = "output"&host1&".xml"
'wscript.echo DirIn

                    DeleteLine  DirIn, "----------", 0, 0 

'wscript.echo Dirout
					Set fso = CreateObject("Scripting.FileSystemObject")

					Set txtStream = fso.OpenTextFile(DirIn)
					txtOut = ""
					Do While Not (txtStream.atEndOfStream)
					str=txtStream.ReadLine
					intPos = InStr(str,"<")
					if intPos=0 then
					txtOut = txtOut+replace(str,str,"")
					else 
					txtOut = txtOut+str
					Do While Not (txtStream.atEndOfStream)
						str1=txtStream.ReadLine
						txtOut = txtOut+str1
					Loop
					end if
					Loop

					intPos = InStr(txtOut,"<")

					txtOut1 = right(txtOut ,len(txtOut)-intPos+1)

					Set txtStreamOut = fso.OpenTextFile(DirOut, 2, True)
					'wscript.echo txtOut1
					txtStreamOut.write txtOut1

					txtStreamOut.Close
					txtStream.Close

					Dim DirIn
					Dim DirOut
					Dim fso
					Dim txtStream
					Dim txtOut
					Dim txtStreamOut
					Dim DirIn1
					Dim DirOut1
					Dim fso1
					Dim txtStream1
					Dim txtOut1
					Dim txtStreamOut1 
					Dim strFile1

					DirIn = "output"&host1&".xml"
					DirOut = "output"&host1&".xml"

					Set fso = CreateObject("Scripting.FileSystemObject")

					Set txtStream = fso.OpenTextFile(DirIn)

					txtOut = ""

					Do While Not (txtStream.atEndOfStream)
						txtOut = txtOut+replace(txtStream.ReadLine,"	","")
					Loop

					Set txtStreamOut = fso.OpenTextFile(DirOut, 2, True)

					txtStreamOut.write txtOut

					txtStreamOut.Close
					txtStream.Close
					txtStreamOut=Nothing
					txtStream=Nothing

					'WScript.Sleep(2000)

					DirIn1 = "output"&host1&".xml"
					DirOut1 = "output"&host1&".xml"

					Set fso1 = CreateObject("Scripting.FileSystemObject")


					Set txtStream = fso.OpenTextFile(DirIn1)

					txtout1 = ""

					Do While Not (txtStream.atEndOfStream)
						txtOut1 = txtOut1+txtStream.ReadLine
					Loop

					Set txtStreamOut1 = fso.OpenTextFile(DirOut1, 2, True)
					'wscript.echo txtout1
					txtStreamOut1.write txtOut1
					txtStreamOut1.Close
					txtStream1.Close
					txtStreamOut1=Nothing
					txtStream1=Nothing
					txtStream.close'test
					set objFSO1 = CreateObject("Scripting.FileSystemObject")

					strFile1 = "output"&host1&".xml"  

					Set ofile1 = objFSO1.OpenTextFile(strFile1,1)

					txtout1 = ""

					Do While Not (ofile1.atEndOfStream)
						txtOut1 = txtOut1+replace(ofile1.ReadLine,"&","&amp;")
					Loop

					writeOutput( txtOut1)
                    writeOutput1( txtOut1)
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & host2 & "\root\cimv2")

Set colRetrievedEvents = objWMIService.ExecQuery _
    ("Select * from Win32_Service Where Name like'%SQL%' and Name!='MySQL'")
txtOut=""
txtOut=txtOut+"<services>"
For Each objEvent in colRetrievedEvents
txtOut=txtOut+"<st serviceName=""" & objEvent.Name  & """ type="""& objEvent.StartMode &  """ status=""" &objEvent.State& """ />"
Next
txtOut=txtOut+"</services>"
writeOutput(txtOut)




					writeOutput( "</root>" )
					writeOutput1("</instance>")
					ofile1.Close
					ofile1=Nothing
					txtStreamOut=Nothing
					strFile1=Nothing

					'--cleanup
					sCmd2 = "cmd.exe /c del output"&host1&".xml"
					iRC2 = WshShell.Run(sCmd2, 0,True)

	file=logfile


	Dim objXML      'object to hold XML data
	Dim objXSL      'object to hold style sheet
	Dim objHTML     'object to hold style sheet 

	   
		  set objXML  = CreateObject("MSXML2.DOMDocument.3.0")
		  set objXSL  = CreateObject("MSXML2.DOMDocument.3.0")
		  set objHTML = CreateObject("Scripting.FilesyStemObject")
		  

		  objXML.validateOnParse = true
		  objXSL.validateOnParse = true
		  

		  objXML.load(file)
		  objXsL.load("XSLT.xsl")

		  strResult = objXML.transformNode(objXSL)
	 
		  set ofile = objHTML.createTextFile("Sqlreport"&host1&".html", True)
		  ofile.write strResult
		  ofile.Close
		  
          file1=filepath & "\Sqlreport"&host1&".html"

	      set objFSO1 = CreateObject("Scripting.FileSystemObject")

					Set ofile1 = objFSO1.OpenTextFile(file1,1)

					txtout1 = ""

					Do While Not (ofile1.atEndOfStream)
						txtOut1 = txtOut1+ofile1.ReadLine
					Loop
					
					txtout2 = txtout2+txtout1+"<hr color=""#000000"">"
          ofile1.close
	      objFSO1.close
	      objFSO1=Nothing

		  'sCmd3 = "cmd.exe /c del "&file1
		  sCmd3 = "cmd.exe /c del Sqlreport"&host1&".html"
          iRC3 = WshShell.Run(sCmd3, 0,True)
          sCmd4 = "cmd.exe /c del log\sqlreport"&host1&".xml"
          iRC4 = WshShell.Run(sCmd4, 0,True)

		  If serviceState="Running" Then 
			txt2=txt2+"<TR><TD bgcolor=""#C2DFFF""><a href=""#"&Replace(strComputer,"\","")&""">"&strComputer&"</a></TD><TD bgcolor=""#C2DFFF""><font color=""#347C17"">"&serviceState&"</font></TD></TR>"	  
		  Else
			txt2=txt2+"<TR><TD bgcolor=""#C2DFFF""><a href=""#"&Replace(strComputer,"\","")&""">"&strComputer&"</a></TD><TD bgcolor=""#C2DFFF""><font color=""#FF0000"">"&serviceState&"</font></TD></TR>"	  
		  End If
	
Loop
writeOutput1( "</root>" )

    set objXML  = CreateObject("MSXML2.DOMDocument.3.0")
      set objXSL  = CreateObject("MSXML2.DOMDocument.3.0")
      set objHTML = CreateObject("Scripting.FilesyStemObject")
      

      objXML.validateOnParse = true
      objXSL.validateOnParse = true
      

      objXML.load(logfile1)
      objXsL.load("summary.xsl")

      strResult1 = objXML.transformNode(objXSL)
    txt2="<fieldset><a name=""top""></a><br><b>Hi All,<br><br>This is an automated DBA Checklist Report for the following SQL servers as on <font color=""#347C17"">"&now()&"</font>.Please click on the server name to see the report for that server.</b><br><br><TABLE border=""0""><TR><TH bgcolor=""#B7CEEC"">SQL servers</TH><TH bgcolor=""#B7CEEC"">Status</TH></TR>"&txt2&"</TABLE></fieldset>"&strResult1
'wscript.echo txt2
set objXML=Nothing
set objXSL=Nothing
set objHTML=Nothing

sCmd5 = "cmd.exe /c del log\Sqlreport.xml"
'wscript.echo sCmd5
iRC5 = WshShell.Run(sCmd5, 0,True)

Set fso3 = CreateObject("Scripting.FileSystemObject")
Set filetxt3 = fso3.CreateTextFile("Checklist.html")
ttt=vbcrlf&txt2&txtout2&vbcrlf &vbcrlf &"<br>Thanks,<br>NetEnrich.<br>"
filetxt3.WriteLine(ttt)
filetxt3.close
Set fso3 = Nothing


Set objMessage = CreateObject("CDO.Message") 
	objMessage.Subject = "SQL-Checklist Report for 2Source "& Now() &" EST"
	objMessage.From ="siva.payyavula@netenrich.com" 
	objMessage.To ="support@netenrich.com" 
	objMessage.Cc="l2database@netenrich.com"
	objMessage.htmlBody =vbcrlf&txt2&txtout2&vbcrlf &vbcrlf &"<br>Thanks,<br>NetEnrich.<br>"
	'objMessage.Addattachment file1
	'This section provides the configuration information for the remote SMTP 
	'server.Normally you will only change the server name or IP.
	objMessage.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 1

	'Name or IP of Remote SMTP Server
	objMessage.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "216.82.254.35" 

	'Server port number(typically 25)
	objMessage.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25 

	objMessage.Configuration.Fields.Update

	objMessage.Send
	Set objMessage = Nothing


WScript.Echo "Completed"


	Function checkFile
		On Error Resume Next
		Dim fso1
		Set fso1 = CreateObject("Scripting.FileSystemObject")
		If fso1.FolderExists(logPath) Then
		Else
			fso1.CreateFolder(logPath)
		End If
		If fso1.FileExists(logfile) Then
			fso1.DeleteFile logfile
		Else 
			'Set filetxt = fso1.CreateTextFile("C:\NT_ScriptLogs\output_tempfiles.txt")
		End If
		Set fso1 = nothing
	End Function
	Function checkFile1
		On Error Resume Next
		Dim fso1
		Set fso1 = CreateObject("Scripting.FileSystemObject")
		If fso1.FolderExists(logPath) Then
		Else
			fso1.CreateFolder(logPath)
		End If
		If fso1.FileExists(logfile1) Then
			fso1.DeleteFile logfile1
		Else 
			'Set filetxt = fso1.CreateTextFile("C:\NT_ScriptLogs\output_tempfiles.txt")
		End If
		Set fso1 = nothing
	End Function
	Function writeOutput(ByVal result)
		On Error Resume Next
		err.clear
		Const ForReading = 1, ForWriting = 2, ForAppending = 8 
		Dim fso1 , NewFile, filetxt
		Set fso1 = CreateObject("Scripting.FileSystemObject")
		If fso1.FolderExists(logPath) Then
		Else
			fso1.CreateFolder(logPath)
		End If
		If fso1.FileExists(logfile) Then
			Set filetxt = fso1.OpenTextFile(logfile, ForAppending, False)
		Else 
			Set filetxt = fso1.CreateTextFile(logfile)
		End If
		
		'WScript.Echo result
		filetxt.WriteLine(result)
		filetxt.close
		Set fso1 = nothing
	End Function
		Function writeOutput1(ByVal result)
		On Error Resume Next
		err.clear
		Const ForReading = 1, ForWriting = 2, ForAppending = 8 
		Dim fso1 , NewFile, filetxt
		Set fso1 = CreateObject("Scripting.FileSystemObject")
		If fso1.FolderExists(logPath) Then
		Else
			fso1.CreateFolder(logPath)
		End If
		If fso1.FileExists(logfile1) Then
			Set filetxt = fso1.OpenTextFile(logfile1, ForAppending, False)
		Else 
			Set filetxt = fso1.CreateTextFile(logfile1)
		End If
		
		'WScript.Echo result
		filetxt.WriteLine(result)
		filetxt.close
		Set fso1 = nothing
	End Function

        Function dConvertToDate(sDate)
		Dim sMonth, sDay, sYear, sHour, sMinutes, sSeconds
		sMonth = Mid(sDate,5,2)
		sDay = Mid(sDate,7,2)
		sYear = Mid(sDate,1,4)
		sHour = Mid(sDate,9,2)
		sMinutes = Mid(sDate,11,2)
		sSeconds = Mid(sDate,13,2)
		dConvertToDate = DateSerial (sYear, sMonth, sDay) + TimeSerial (sHour, sMinutes, sSeconds)
	End Function
Function DeleteLine(strFile, strKey, LineNumber, CheckCase)
   Const ForReading=1:Const ForWriting=2
   Dim objFSO,objFile,Count,strLine,strLineCase,strNewFile
   Set objFSO=CreateObject("Scripting.FileSystemObject")
   Set objFile=objFSO.OpenTextFile(strFile,ForReading)
   Do Until objFile.AtEndOfStream
      strLine=objFile.Readline
      If CheckCase=0 then strLineCase=ucase(strLine):strKey=ucase(strKey)
      If LineNumber=objFile.Line-1 or LineNumber=0 then
         If instr(strLine,strKey) or instr(strLineCase,strkey) or strKey="" then
            strNewFile=strNewFile
         Else
            strNewFile=strNewFile&strLine&vbcrlf
         End If
      Else
         strNewFile=strNewFile&strLine&vbcrlf
      End If
   Loop
   objFile.Close
   Set objFSO=CreateObject("Scripting.FileSystemObject")
   Set objFile=objFSO.OpenTextFile(strFile,ForWriting) 
   objFile.Write strNewFile 
   objFile.Close 

End Function

Function Reachable(strComputer)

Dim wmiQuery, objWMIService, objPing, objStatus

wmiQuery = "Select * From Win32_PingStatus Where Address = '" & strComputer & "'"
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set objPing = objWMIService.ExecQuery(wmiQuery)

For Each objStatus in objPing
If IsNull(objStatus.StatusCode) Or objStatus.Statuscode<>0 Then
Reachable = False 'if computer is unreacable, return false
Else
Reachable = True 'if computer is reachable, return true
End If

Next
End Function