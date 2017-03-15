' xxxxx This script adds printers to computers based on what OU they are in
On Error Resume Next
Dim mapping,debugging, printerString, printer_number, printerSplit
Set mapping = CreateObject("Scripting.Dictionary")
debugging=0  'set to 1 to get pop-up windows with debugging information. do not use in production!
'Add a listing of your OU names and printers here.
'OUs that have multiple printers should still have ONE
'line, but the second argument should be in the format:
' \\server\printerA;\\server\printerB
if debugging Then wscript.echo "Creating dictionary..." End If

' Add stuff below here.  Uncomment the lines you want.  Be sure to turn off any GPO which
' was supposed to be adding these printers.

'mapping.add "BCH Lower Level","\\wlb-print-03\LAB_Honors_1"
mapping.add "Honors Lab","\\wlb-print-03\LAB_Honors_2"
mapping.add "BH101","\\wlb-print-03\LAB_BH101_1"
mapping.add "BC Nurses Station","\\wlb-print-03\LAB_BH101_1"
'mapping.add "Classrooms","\\wlb-print-01\business_2"  ' --special --uses item-level targeting
mapping.add "E118","\\wlb-print-03\LAB_E137_1"
mapping.add "E137","\\wlb-print-03\LAB_E137_2"
mapping.add "E143","\\wlb-print-03\LAB_E143_1"
mapping.add "E147A","\\wlb-print-03\LAB_E147a_1"
mapping.add "E149B","\\wlb-print-03\LAB_E149B_1"
mapping.add "E150","\\wlb-print-03\LAB_E150_1"
mapping.add "E153A","\\wlb-print-03\LAB_E153a_1"
mapping.add "E153B","\\wlb-print-03\LAB_E153B_1"
mapping.add "E156","\\wlb-print-03\LAB_E156_1"
mapping.add "E18","\\wlb-print-03\LAB_e18_1"
mapping.add "E19","\\wlb-print-03\LAB_E19_1"
mapping.add "E211","\\wlb-print-03\Biology_1 \\wlb-print-03\Biology_2"
'mapping.add "E232","\\wlb-print-03\LAB_E232_1 \\WLB-PRINT-03\LAB_E235_1 \\wlb-print-03\LAB_E236_2"
'mapping.add "E235","\\wlb-print-03\LAB_E235_1 \\wlb-print-03\LAB_E237_1"
mapping.add "E236","\\wlb-print-03\LAB_E236_2 \\wlb-print-03\LAB_E235_1"
mapping.add "E237","\\wlb-print-03\LAB_E237_1"
mapping.add "E238","\\wlb-print-03\LAB_E238_1"
mapping.add "E238A","\\wlb-print-03\LAB_E238A_1"
mapping.add "EOF","\\wlb-print-03\LAB_EOF_1"
mapping.add "HH101A","\\wlb-print-03\Psychology_6"
mapping.add "HH101B","\\wlb-print-03\Psychology_7"
mapping.add "HH103A","\\wlb-print-03\LAB_HH103A_1"
mapping.add "HH106","\\wlb-print-03\LAB_HH106_1" 
mapping.add "HH106A","\\wlb-print-03\LAB_HH106A_1" 
mapping.add "HH106B","\\wlb-print-03\LAB_HH106B_1"
mapping.add "HH111","\\wlb-print-03\LAB_HH111_POOL"
mapping.add "HH124","\\wlb-print-03\Psychology_1 \\wlb-print-03\Psychology_2"
mapping.add "HH201","\\wlb-print-03\Math_3 \\wlb-print-03\Math_2 \\wlb-print-03\Math_1"
mapping.add "HH203","\\wlb-print-03\LAB_HH203_1"
mapping.add "HH206","\\wlb-print-03\Chemistry_3 \\wlb-print-03\Chemistry_2 \\wlb-print-03\Chemistry_1"
mapping.add "HH207","\\wlb-print-03\LAB_HH207_1" 
mapping.add "HH212","\\wlb-print-03\LAB_HH212_1"
mapping.add "HH216","\\Wlb-print-03\LAB_HH216_1 \\wlb-print-03\ComputerScience_1 \\wlb-print-03\ComputerScience_2 \\wlb-print-03\ComputerScience_3"
mapping.add "HH223","\\wlb-print-03\ComputerScience_1 \\wlb-print-03\ComputerScience_2 \\wlb-print-03\ComputerScience_3"
mapping.add "HH251","\\wlb-print-03\Math_4"
mapping.add "HH306","\\wlb-print-03\LAB_HH306_1 \\wlb-print-03\LAB_HH306_3 \\wlb-print-03\LAB_HH306_2"
mapping.add "HH307","\\wlb-print-03\LAB_HH307_1"
mapping.add "HH308","\\wlb-print-03\LAB_HH308_1"
mapping.add "HH309","\\wlb-print-03\LAB_HH309_1"
mapping.add "HH328","\\wlb-print-03\History_2"
mapping.add "HH349","\\wlb-print-03\History_2"
mapping.add "Laurel Hall","\\wlb-print-03\Training_1"
mapping.add "JP113","\\wlb-print-03\ForeignLanguage_1"
mapping.add "JP125","\\wlb-print-03\ForeignLanguage_1"
mapping.add "Basement Lab","\\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_4a"
mapping.add "Library 1st Floor","\\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_4a" 
mapping.add "Library 2fl","\\wlb-print-03\LAB_Library_4a \\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_3a" 'item level on library_10
mapping.add "Library Athletics Lab","\\wlb-print-03\LAB_Athletics_1A \\wlb-print-03\LAB_Library_5 \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_10"
mapping.add "Library Loaner Laptops","\\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_4a"
mapping.add "Medicat Laptops","\\wlb-print-03\Healthcenter_1"
mapping.add "Reference Area A","\\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_4a"
mapping.add "Reference Area B","\\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_4a"
mapping.add "Reference Area C","\\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_4a"
mapping.add "Reference Area D","\\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_4a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_3a"
mapping.add "Reference Area E","\\wlb-print-03\LAB_Library_1a \\wlb-print-03\LAB_Library_2 \\wlb-print-03\LAB_Library_3a \\wlb-print-03\LAB_Library_4a"
mapping.add "Library Reference Desk","\\wlb-print-03\Library_9"		'Added by JF #00124047
mapping.add "MAC117","\\wlb-print-03\LAB_MAC_117_1"
mapping.add "MAC164","\\wlb-print-03\LAB_MAC172_1 \\wlb-print-03\MAC_6"
mapping.add "MH19","\\wlb-print-03\LAB_MH19_1"
mapping.add "MHLL","\\wlb-print-03\LAB_MH19_1"
mapping.add "MH123","\\wlb-print-03\LAB_MH123_1"
mapping.add "MH124","\\wlb-print-03\SPECL_2"
mapping.add "MH202","\\wlb-print-03\HealthStudies_1 \\HealthStudies_3"
mapping.add "MH226","\\wlb-print-03\LAB_MH226_1"
mapping.add "MPCC129","\\mpcc-print-01\PhysAssist_2 \\mpcc-print-01\PhysAssist_1"
mapping.add "MPCC138","\\mpcc-print-01\PsychCounseling_7 \\mpcc-print-01\PsychCounseling_5"
mapping.add "MPCC167","\\mpcc-print-01\SPECL_6 \\mpcc-print-01\SPECL_8"
mapping.add "MPCC168","\\mpcc-print-01\SPECL_8"
mapping.add "MPCC171","\\mpcc-print-01\SPECL_6"
mapping.add "JP115","\\wlb-print-03\LAB_JP115_1"
mapping.add "JP234","\\wlb-print-03\LAB_JP234_1 \\wlb-print-03\LAB_JP234_2"
mapping.add "1st floor Greek Lounge","\\wlb-print-03\GreekLounge_1"
mapping.add "2nd Floor Lounge Lab","\\wlb-print-03\LAB_STUCTR_POOLa"
mapping.add "SC-308","\\wlb-print-03\StudentServices_5"
mapping.add "SC-309","\\wlb-print-03\StudentServices_10 \\wlb-print-03\StudentServices_4"
mapping.add "SC-315","\\wlb-print-03\StudentServices_7"
mapping.add "SC-317","\\wlb-print-03\StudentServices_7"
mapping.add "SC-318","\\wlb-print-03\StudentServices_7"
mapping.add "SC-320","\\wlb-print-03\StudentServices_6"
mapping.add "SC-333","\\wlb-print-03\Conference_1 \\wlb-print-03\Conference_2"
mapping.add "SC-334","\\wlb-print-03\Conference_1 \\wlb-print-03\Conference_2"
mapping.add "SW_4Printer","\\wlb-print-03\SocialWork_4"
mapping.add "CSS","\\wlb-print-03\LAB_CSS_1"
mapping.add "Disability Services","\\wlb-print-03\LAB_DDS_1 \\wlb-print-03\LAB_TestCtr_1 \\wlb-print-03\Disability_3 \\wlb-print-03\Disability_4"
mapping.add "DSS Testing Center","\\wlb-print-03\LAB_TestCtr_1 \\wlb-print-03\Disability_1 \\wlb-print-03\LAB_DDS_1 \\wlb-print-03\Disability_3 \\wlb-print-03\Disability_4"
mapping.add "Schedule Print","\\wlb-print-03\firstyear_5"
mapping.add "FYM","\\wlb-print-03\FirstYear_6"
mapping.add "Graduate Lounge Basement","\\wlb-print-03\LAB_STUCTR_3"
mapping.add "Veteran Services","\\wlb-print-03\LAB_VETSERV_1"
mapping.add "Veteran Services Lounge","\\wlb-print-03\LAB_VetsLounge_1"
mapping.add "WA016","\\wlb-print-03\English_6 \\wlb-print-03\English_7"
mapping.add "WA017","\\wlb-print-03\English_6"
' commented due to user request.  Ticket #121161 - 20160229 mapping.add "WA100","\\wlb-print-03\English_7" 
mapping.add "WC2","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC3","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC4","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC5","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC6","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC7","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC8","\\wlb-print-03\LAB_WriteCtr_1 \\wlb-print-03\CSS_1 \\wlb-print-03\CSS_3"
mapping.add "WC9","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC10","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC11","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WC12","\\wlb-print-03\LAB_WriteCTR_1 \\wlb-print-03\WritingCenter_02"
mapping.add "WC13","\\wlb-print-03\LAB_WriteCtr_1"
mapping.add "WT201","\\wlb-print-03\Music&Theatre_1 \\wlb-print-03\Music&Theatre_2 \\wlb-print-03\Music&Theatre_3"
mapping.add "WT209","\\wlb-print-03\Music&Theatre_1 \\wlb-print-03\Music&Theatre_2 \\wlb-print-03\Music&Theatre_3"
mapping.add "WT220","\\wlb-print-03\Music&Theatre_1 \\wlb-print-03\Music&Theatre_2 \\wlb-print-03\Music&Theatre_3"
mapping.add "Web Factory","\\wlb-print-03\info_mgmt_1 \\wlb-print-03\info_mgmt_3 \\wlb-print-03\info_mgmt_4"
mapping.add "Writing Center","\\wlb-print-03\LAB_WriteCTR_1"
mapping.add "BC118","\\wlb-print-03\LAB_BMC118_1 \\wlb-print-03\LAB_BMC118_2 \\wlb-print-03\NursingClinic_1 \\wlb-print-03\Nursing_1"
mapping.add "BC104","\\wlb-print-03\NursingClinic_1"
mapping.add "PZ207","\\wlb-print-03\LAB_PZ207_1"
mapping.add "1st Floor Lab","\\wlb-print-03\LAB_STUCTR_2"
mapping.add "AS_Lab_431","\\wlb-print-03\LAB_AS431_1"
mapping.add "AS_Lab_432","\\wlb-print-03\LAB_AS432_1"
mapping.add "Atrium Science","\\wlb-print-03\LAB_AS432_1 \\wlb-print-03\LAB_AS432_2"

if debugging Then wscript.echo "Dictionary creation finished." End If


''''''''''''''''''''''''''''
' No serviceable parts below
''''''''''''''''''''''''''''

' this function gets this computers OU, looks up the OU name in
' the dictionary,  finds the printer string.
Set objSysInfo = CreateObject("ADSystemInfo")
strComputer = objSysInfo.ComputerName
Set objComputer = GetObject("LDAP://" & strComputer)
arrOUs = Split(objComputer.Parent, ",")
arrMainOU = Split(arrOUs(0), "=")
If debugging Then Wscript.Echo "OU Found is: " & arrMainOU(1) End If

' OU is found in arrMainOU(1)
' Does this OU have any printers?
if mapping.Exists(arrMainOU(1)) Then
	' This removes all wlb-print-01 networked printers from the local computer
	Const SERVERNAMEA = "\\wlb-print-01"
	Const SERVERNAMEB = "\\wlb-print-03"
	Const SERVERNAMEC = "\\mpcc-print-01"
	Set objNetwork = CreateObject("WScript.Network")
	strComputer = "."
	dbLogonDeleted = ""
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	Set colPrinters = objWMIService.ExecQuery("Select * From Win32_Printer")
	' Remove each printer
	For Each objPrinter in colPrinters
		If (objPrinter.SystemName = SERVERNAMEA) or (objPrinter.SystemName = SERVERNAMEB) or (objPrinter.SystemName = SERVERNAMEC) Then
			strPrinter = objPrinter.Name
			dbLogonDeleted = dbLogonDeleted & " " & objPrinter.Name
			objNetwork.RemovePrinterConnection strPrinter
		End If
	Next

		
	' Now add new network printers
	Set WshNetwork = CreateObject("Wscript.Network")
	' there are printer(s) for us to map
	'split apart the printer string based on space character
	printerString=mapping(arrMainOU(1))
	printerSplit=Split(printerString)
	'map each printer found in the printer string for this OU
	'create an object for mapping stuff
	printer_number=0
	for each printer_unc In printerSplit
		If debugging Then wscript.echo  "Trying to map: " & printer_unc End If
		WshNetwork.AddWindowsPrinterConnection printer_unc

		if printer_number = 0 Then 'first printer. set as default printer
			default_printer = printer_unc
		End If
		printer_number = printer_number + 1 'increase printer count
	Next
	if debugging Then wscript.echo "End of Adding Printers" End If

	' set default printer
	If debugging Then wscript.echo "Setting default printer to: " & default_printer End If
	WshNetwork.SetDefaultPrinter default_printer
	'set LPT1 to this default printer.  legacy stuff uses LPT:
	if debugging Then wscript.echo "Setting LPT1: to " & default_printer End If
	'WshNetwork.AddPrinterConnection "LPT1",default_printer


	'
	'  REPORTING AREA BELOW
	' 
	' Report what we deleted and what is on the computer now
	set WshShell = CreateObject("WScript.Shell")
	set oEnv=WshShell.Environment("Process")
	set conn = CreateObject("ADODB.connection")
	connString = "DRIVER={SQL Server};SERVER=wlb-sql-03A.monmouth.edu\WLBSQL03A;UID=usertrack;PWD=tracker1;DATABASE=usertrack"
	conn.Open connString
	user_name = left(lcase(oEnv("USERNAME")),   8)
	computer_name = left(lcase(oEnv("COMPUTERNAME")),20)
	' This queries to see what printers we have now
	Set objNetwork = CreateObject("WScript.Network")
	strComputer = "."
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	Set colPrinters = objWMIService.ExecQuery("Select * From Win32_Printer")
	dbLogonCreated = ""
	For Each objPrinter in colPrinters
		If (objPrinter.SystemName = SERVERNAMEA) or (objPrinter.SystemName = SERVERNAMEB) or (objPrinter.SystemName = SERVERNAMEC) Then
			dbLogonCreated = dbLogonCreated & " " & objPrinter.Name
		End If
	Next
	dbOK="1"
	if Not dbLogonDeleted = "" Then dbOK="0" End If 
	if Not len(trim(printerstring)) = len(trim(dbLogonCreated)) Then dbOK="0" End If
	'msgbox "A" & len(trim(printerString)) & len(trim(dbLogonCreated))
	sqlquery = "insert into printers (OU,logon,username,date,computer,OK,logon_deleted,logon_created) VALUES ('" &arrMainOU(1)& "',1,'" &user_name& "', GETDATE(),'" & computer_name & "',"&dbOK&",'" & trim(dbLogonDeleted) & "','" & trim(dbLogonCreated) & "')"
	'msgbox sqlquery
	set resultset = conn.Execute(sqlquery)
End If