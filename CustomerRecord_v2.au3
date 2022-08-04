;CustomerRecord_v2.au3 by PTHO
;Created with ISN AutoIt Studio v. 1.14
;*****************************************

;Make this script high DPI aware
;AutoIt3Wrapper directive for exe files, DllCall for au3/a3x files
;#AutoIt3Wrapper_Res_HiDpi=y
;If not @Compiled then DllCall("User32.dll", "bool", "SetProcessDPIAware")

#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <Array.au3>
#include <Misc.au3>
#include <GUIConstants.au3>
#include <GuiDateTimePicker.au3>
#include <WinAPISys.au3>
#include "mysql.au3"
#include "Forms\frmMain.isf"
#include "Forms\$frmLogin.isf"
#include "Forms\frmEditRecord.isf"
#include "Forms\frmAdvReport.isf"



#Region AutoIt Options
;Here we set the needed AutoIt Options for our script.
;Opt("GUIOnEventMode", 1)
opt("GUIEventOptions", 0)
#EndRegion AutoIt Option


#Region FormEvent
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit", $frmLogin)
GUISetState(@SW_SHOW, $frmLogin)
#EndRegion FormEvent


#Region Initialzie
HotKeySet("^`", "SendReport")
HotKeySet("^1", "unlockSendKey")

Local $hDLL = DllOpen("user32.dll")
_MySQL_InitLibrary()
;_MySQL_InitLibrary(@ScriptDir & "\libsql\libmysql.dll")
;MsgBox(1, 1, @ScriptDir & "\libsql\libmysql.dll")
;_MySQL_InitLibrary(@ScriptDir & "\libsql\libmySQL_x64.dll")
If @error Then Exit MsgBox(0, 'Error', "DLL file not found!")
$MysqlConn = _MySQL_Init()

$sqlServerName = IniRead(@ScriptDir & "\config.ini", "sqlserver", "mysqlserver_name", "localhost")
$connected = _MySQL_Real_Connect($MysqlConn, $sqlServerName, "root", "", "customer_record")
If $connected = 0 Then Exit MsgBox(16, 'Connection Error', _MySQL_Error($MysqlConn))


Local $userArray, $arrReport,  $res
Local $checkRadioRecord = "Urgent", $cs = "",  $ce = ""
Local $userName = "", $checkRadioReport = "Urgent",  $checkRadioSearch = "Name",  $checkMobile = "NOT", $sn_imei = "SN"
Local $previousKey = ""
Local $rawEditData = ""
Local $sStyle = "yyyy-MM-dd"
Local $laptopChassisType = [8 , 9, 10, 11, 12, 14, 18, 21]
Local $arrMousePOS = IniReadSection(@ScriptDir & "\config.ini", "mousepos")

GUICtrlSendMsg($editDateFieldReport, $DTM_SETFORMATW, 0, $sStyle)
GUICtrlSendMsg($editDateField, $DTM_SETFORMATW, 0, $sStyle)

Local $readDateFromUrl = BinaryToString(InetRead ( "http://worldtimeapi.org/api/timezone/Asia/Yangon",1))
If @error Then
	MsgBox(0, "Connection Error",  "unable to connect NTP server! Please check Date manually!")
Else
	Local $getDateFromTimeApi = StringRegExp ($readDateFromUrl,'"datetime":"(\d+-\d+-\d+)T', $STR_REGEXPARRAYMATCH)
	Local $splitDate = StringSplit($getDateFromTimeApi[0], "-")
	GUICtrlSetData($editDateField, $splitDate[1] & "/" & $splitDate[2] & "/" & $splitDate[3])
	GUICtrlSetData($editDateFieldReport, $splitDate[1] & "/" & $splitDate[2] & "/" & $splitDate[3])
EndIf


GUICtrlSetData($cbProductType, checkDeviceType())


#EndRegion Initialzie


#Region While
While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			_Exit()
		Case $chMobile
			If GUICtrlRead($chMobile) = 1 Then
				$checkMobile = ""
				$sn_imei = "IMEI"
			Else 
				$checkMobile = "NOT"
				$sn_imei = "SN"
			EndIf
		
		Case $radioAssembly
			ToggleRadioWarranty()
		Case $radioUrgent
			ToggleRadioWarranty()
		Case $radioAssemblyReport
			ToggleRadioWarranty()
		Case $radioUrgentReport
			ToggleRadioWarranty()
		Case $radioName
			$checkRadioSearch = "Name"
		Case $radioPhone
			$checkRadioSearch = "Phone"
		Case $radioSerial
			$checkRadioSearch = "SerialNumber"
			
		Case $btnLogin
			Login()
			
		Case $btnAdd
			AddCustomerRecord()
		Case $btnCheckSN
			CheckSN()
		
		Case $btnAddUser
			AddUser()
			
		Case $btnRemoveUser
			DeleteUser()
			
		Case $btnShowUser
			ShowUser()
		
		Case $btnReport
			ShowReport(Null)
		
		Case $btnDeleteReport
			DeleteReport()
		
		Case $btnEdit
			 EditReport()
			 
		Case $btnUpdate
			UpdateRecord()
		
		Case $btnCancel
			GUISetState(@SW_SHOW, $frmMain)
			GUISetState(@SW_HIDE, $frmEditRecord)
			
		Case $btnSearchCustomer
			ShowReport($checkRadioSearch)
		
	EndSwitch	
	
		If _IsPressed("0D", $hDLL) Then
			$currControl = ControlGetFocus("Customer Record")
			$currText = WinGetText("Customer Record")
			
			If $currControl = "Edit1" And StringInStr($currText, "Login") Then Login()
			
			While _IsPressed("0D", $hDLL)
				Sleep(250)
			WEnd
			$currControl = ""
			
		EndIf 				
		
	Sleep(10)
WEnd
#EndRegion While


Func CheckSN()
	
	;WMIC PATH Win32_Battery Get EstimatedChargeRemaining
	
	$model_name_str = ""
	$sn = StringSplit((StringStripWS(_GetDOSOutput("wmic bios get serialnumber"), 4)), " ")
	$vendor = StringSplit((StringStripWS(_GetDOSOutput("wmic csproduct get vendor"), 4)), " ")
	$model_name = StringSplit((StringStripWS(_GetDOSOutput("wmic csproduct get name"), 4)), " ")
	
	;MsgBox(1, 1, UBound($checkDevice))
	
	
	For $i = 2 to UBound($model_name) -1 
		$model_name_str &= $model_name[$i] & " "
	Next
	
	If GUICtrlRead($editModel) == "" Then 
		GUICtrlSetData($editModel, StringFormat("%s %s", $vendor[2], StringStripWS($model_name_str, 2)))
	EndIf
	
	If GUICtrlRead($editSN) ==  "" Then 
		GUICtrlSetData($editSN, $sn[2])
	EndIf
EndFunc

Func Login()
	$userName = StringRegExpReplace(GUICtrlRead($editUsername),  '"', "")	
	$query = StringFormat('SELECT * FROM accounts WHERE username="%s"', $userName)
	
	If $userName = "" Then 
		MsgBox(1, "ERROR", "Username must be filled")
		
	Else 
		If UBound(_excuteSQL($query)) > 0 Then
			If $userName <> "ADMIN" Then
				 _GUICtrlTab_DeleteItem($tab, 2)
			Else ;isAdmin = TRUE
				$cs = "/*"
				$ce = "*/"
			EndIf
			GUISetState(@SW_SHOW, $frmMain)
			GUISetState(@SW_HIDE, $frmLogin)
		
		Else 
			MsgBox($MB_OK, "ERROR", "User doesn't exist!", 0, $frmLogin)
			
		EndIf
		
	EndIf	
EndFunc

Func SearchRecord($sToSearch)
	
	$sSearchData = GUICtrlRead($editSearch)
	
	If $checkRadioReport = "UrgentReport" Then 
		Switch $sToSearch
		
			Case "Name"
				$sqlQuerrySearch = StringFormat('SELECT Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,Date FROM UrgentRecords WHERE Name LIKE "%%s%";', $sSearchData)
			Case "Phone"
				$sqlQuerrySearch = StringFormat('SELECT Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,Date FROM UrgentRecords WHERE Phone LIKE "%%s%";', $sSearchData)
			Case "SerialNumber"
				$sqlQuerrySearch = StringFormat('SELECT Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,Date FROM UrgentRecords WHERE Serialnumber LIKE "%%s%";', $sSearchData)
		EndSwitch 
	Else 
		Switch $sToSearch
		
			Case "Name"
				$sqlQuerrySearch = StringFormat('SELECT Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,Date FROM AssemblyRecords WHERE Name LIKE "%%s%";', $sSearchData)
			Case "Phone"
				$sqlQuerrySearch = StringFormat('SELECT Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,Date FROM AssemblyRecords WHERE Phone LIKE "%%s%";', $sSearchData)
			Case "SerialNumber"
				$sqlQuerrySearch = StringFormat('SELECT Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,Date FROM AssemblyRecords WHERE Serialnumber LIKE "%%s%";', $sSearchData)
		EndSwitch
	
	EndIf
	
EndFunc

Func DeleteReport()
		$selectedReport = StringSplit(GUICtrlRead(GUICtrlRead($listviewReport)), "|") ;selectedReport[13] is "id".
		$query = StringFormat('DELETE FROM records WHERE id=%d', $selectedReport[13] )
		If	UBound($selectedReport) > 2 Then 
			_MySQL_Real_Query($MysqlConn, $query)
		EndIf  
	
	ShowReport(Null)
	
EndFunc
	
Func SendReport()
	
	$keytoSend = StringSplit(GUICtrlRead(GUICtrlRead($listviewReport)), "|")
		
	;_ArrayDisplay($keytoSend)
	If UBound($keytoSend) > 5 Then
		If $previousKey <> $keytoSend[13] Then 
			$staffID = $keytoSend[11]
			If $checkRadioReport = "Urgent" Then
				$stockID = 100010				
			Else 
				$stockID = 100012
			EndIf
			$send_keys = StringFormat("%s/%s-%s/%s", $keytoSend[7], $sn_imei, $keytoSend[8], $keytoSend[10])
			WinActivate("IAIMS Web Application - Google Chrome", "")
			Sleep(500)
			ControlClick("IAIMS Web Application - Google Chrome", "", "",  "left", 3, $arrMousePOS[1][1], $arrMousePOS[2][1])
			Sleep(300)
			ControlSend("", "","", $send_keys, 1)
			Sleep(300)
			ControlClick("IAIMS Web Application - Google Chrome", "", "",  "left", 3, $arrMousePOS[3][1], $arrMousePOS[4][1])
			Sleep(300)
			ControlSend("", "", "", $staffID)
			Sleep(1000)
			ControlClick("IAIMS Web Application - Google Chrome", "", "",  "left", 3, $arrMousePOS[5][1], $arrMousePOS[6][1])
			Sleep(500)
			ControlSend("", "", "", "MMK", 1)
			ControlSend("", "", "", "{ENTER}")
			Sleep(500)
			ControlClick("IAIMS Web Application - Google Chrome", "", "",  "left", 3, $arrMousePOS[7][1], $arrMousePOS[8][1])
			Sleep(300)
			ControlSend("", "", "", "UN-SVC", 1)
			Sleep(300)
			ControlClick("IAIMS Web Application - Google Chrome", "", "",  "left", 3, $arrMousePOS[9][1], $arrMousePOS[10][1])
			Sleep(300)
			ControlSend("", "", "", $stockID, 1)
			Sleep(300)
			ControlClick("IAIMS Web Application - Google Chrome", "", "",  "left", 3, $arrMousePOS[11][1], $arrMousePOS[12][1] )
			
		EndIf
		$stockID = Null 
		$previousKey = $keytoSend[13]
	EndIf
	
EndFunc

Func unlockSendKey()
	$previousKey = ""
EndFunc

Func ShowReport($sSearch)
	$date = GUICtrlRead($editDateFieldReport)	
	$pcCount = 0
	_GUICtrlListView_DeleteAllItems($listviewReport)
	
	$query = StringFormat('SELECT * FROM records WHERE ' & $cs& ' TechName="%s" AND '& $ce& ' recordDate="%s" AND AsUrg="%s" AND '& $checkMobile  & ' ProductType="Mobile";', $userName, $date, $checkRadioReport)
	ConsoleWrite($query)
	$arrListReport = _excuteSQL($query)
	For $i = 1 to UBound($arrListReport) - 1
		GUICtrlCreateListViewItem(StringFormat("%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%d",$i, $arrListReport[$i][1],$arrListReport[$i][2],$arrListReport[$i][3],$arrListReport[$i][4],$arrListReport[$i][5],$arrListReport[$i][6],$arrListReport[$i][7],$arrListReport[$i][8],$arrListReport[$i][9],$arrListReport[$i][10],$arrListReport[$i][11],$arrListReport[$i][0]  ), $listviewReport)
		If $arrListReport[$i][4] = "PC" Then
			GUICtrlSetBkColor(-1,0xFFFF00 )
			$pcCount += 1
		EndIf		
	Next
			

	GUICtrlSetData($lblTotalPCs,"Total : " & $i -1 & " / LT : " & ($i -1) - $pcCount & " , PC : " & $pcCount)
	$arrListReport = Null 	
	
EndFunc

Func UpdateRecord()
	$newName = GUICtrlRead($editNewName)
	$newPhone = GUICtrlRead($editNewPhone)
	$newCity = GUICtrlRead($editnewCity)
	
	$query = StringFormat("UPDATE records SET Name='%s', Phone='09%s', City='%s' WHERE id='%d';", $newName, $newPhone, $newCity, $rawEditData[13])
		
	_MySQL_Real_Query($MysqlConn, $query)
	MsgBox(0, "Complete", "Record Updated", 0, $frmEditRecord)
	
	$newName = ""
	$newPhone = ""
	$newCity = ""
	GUICtrlSetData($editNewName, "")
	GUICtrlSetData($editNewCity, "")
	GUICtrlSetData($editNewPhone, "")
	GUISetState(@SW_SHOW, $frmMain)
	GUISetState(@SW_HIDE, $frmEditRecord)
	ShowReport(Null)
EndFunc

Func EditReport()
	
	$rawEditData = StringSplit(GUICtrlRead(GUICtrlRead($listviewReport)), "|")	
		
	If UBound($rawEditData) > 2 Then
			
		GUICtrlSetData($lblModelSN, StringFormat("%s/%s", $raweditData[7] , $raweditData[8]))
				
		GUISetState(@SW_SHOW, $frmEditRecord)
		GUISetState(@SW_HIDE, $frmMain)
		
	Else 
		MsgBox(0,"Error", "Please select record to edit.", 0, $frmMain)
	EndIf
		
		ShowReport(Null )
EndFunc

Func AddCustomerRecord()
	$productError = ""
	$productWarranty = "" 
	$customerName = StringRegExpReplace(GUICtrlRead($editName),  '"', "")
	$customerPhNo = StringRegExpReplace("09" & GUICtrlRead($editPhone),  '"', "")
	$customerAddress = StringRegExpReplace(GUICtrlRead($editCity),  '"', "")
	$productType = StringRegExpReplace(GUICtrlRead($cbProductType),  '"', "")
	$productModel = StringRegExpReplace(GUICtrlRead($editModel),  '"', "")
	$productSN = StringRegExpReplace(GUICtrlRead($editSN),  '"', "")
	$date = GUICtrlRead($editDateField) 
	
	If BitAND(GUICtrlRead($radioUrgent), $GUI_CHECKED) = $GUI_CHECKED Then
		
		If BitAND(GUICtrlRead($radioExp), $GUI_CHECKED) = $GUI_CHECKED Then $productWarranty = "Exp"
		If BitAND(GUICtrlRead($radioExt), $GUI_CHECKED) = $GUI_CHECKED Then $productWarranty = "Ext"
		If BitAND(GUICtrlRead($radioWithin), $GUI_CHECKED) = $GUI_CHECKED Then $productWarranty = "Within"	
		$productError = StringRegExpReplace(GUICtrlRead($editError),  '"', "")
	EndIf

	$productSolution = StringRegExpReplace(GUICtrlRead($editSolution),  '"', "")	
	
	If  $productModel <> "" Then
			
		$query = StringFormat('INSERT INTO records(Name,Phone,City,ProductType,Warranty,ModelName,Serialnumber,Error,Solution,TechName,recordDate,AsUrg) VALUES("%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s");', $customerName, $customerPhNo, $customerAddress, $productType,$productWarranty, $productModel, $productSN, $productError,$productSolution, $userName, $date, $checkRadioRecord)

		$resultTest = _MySQL_Real_Query($MysqlConn, $query)
		If $resultTest = 0 Then
			GUICtrlSetState($editName, $GUI_FOCUS)
			MsgBox(0, "Complete", "Record Added", 0, $frmMain)
			$query = ""
		Else 
			MsgBox(0, "Error", "Failed to add record.", 0, $frmMain)
		EndIf
		
		
	Else 
		MsgBox(0, "ERROR", "Fill text field.", 0, $frmMain)
	EndIf
	
	
	
	Sleep(300)
	GUICtrlSetData($editName, "")
	GUICtrlSetData($editPhone, "")
	GUICtrlSetData($editCity, "")
	GUICtrlSetData($editModel, "")
	GUICtrlSetData($editModel, "")
	GUICtrlSetData($editSN, "")
	GUICtrlSetData($editError, "")
	GUICtrlSetData($editSolution, "")
	
	
EndFunc


Func DeleteUser()
	$selectedUser = StringSplit(GUICtrlRead(GUICtrlRead($listviewUser)), "|") ;$selectedUser[1] is "id".
	$query = StringFormat('DELETE FROM accounts WHERE id=%d;',$selectedUser[1] )
	
	_MySQL_Real_Query($MysqlConn, $query)
	ShowUser()
	
EndFunc


Func ShowUser()
	_GUICtrlListView_DeleteAllItems($listviewUser)
	
	$query = 'SELECT * FROM accounts'
	$arrUser = _excuteSQL($query)
	
	For $i = 1 to UBound($arrUser) - 1
		GUICtrlCreateListViewItem(StringFormat("%d|%s|%s|%s",$arrUser[$i][0],$arrUser[$i][1],$arrUser[$i][3],$arrUser[$i][4] ), $listviewUser)
	Next
	$arrUser = Null 
	
EndFunc

Func AddUser()
	$techName = StringRegExpReplace(GUICtrlRead($editAddUser),  '"', "")
	$query = StringFormat('INSERT INTO accounts(username) VALUES("%s");', $techName)
	
	If $techName = "" Then 
		MsgBox(1, "ERROR",  "Name must be filled.")
		
	Else 
		_MySQL_Real_Query($MysqlConn, $query)
		
		ShowUser()
	EndIf
	GUICtrlSetData($editAddUser, "")
	
EndFunc


Func ChangeUrgentAssembly($checkRadio)
	
	Switch $checkRadio
		
		Case "Assembly"
			For $ii =  0 To UBound($aGroupUrgent) -1
				GUICtrlSetState($aGroupUrgent[$ii], $GUI_HIDE)		
			Next
			GUICtrlSetData($editError, "")
			$checkRadioRecord = "Assembly"
			
		Case "Urgent"
			For $ii =  0 To UBound($aGroupUrgent) -1
				GUICtrlSetState($aGroupUrgent[$ii], $GUI_SHOW)
			Next
			$checkRadioRecord = "Urgent"
			
		Case "UrgentReport"
			$checkRadioReport = "Urgent"
			
		Case "AssemblyReport"

			$checkRadioReport = "Assembly"
	EndSwitch
	
	
	
EndFunc

Func ToggleRadioWarranty()
	If BitAND(GUICtrlRead($radioAssembly), $GUI_CHECKED) = $GUI_CHECKED Then ChangeUrgentAssembly("Assembly")
	
	If BitAND(GUICtrlRead($radioUrgent), $GUI_CHECKED) = $GUI_CHECKED Then ChangeUrgentAssembly("Urgent")

	If BitAND(GUICtrlRead($radioUrgentReport), $GUI_CHECKED) = $GUI_CHECKED Then ChangeUrgentAssembly("UrgentReport")
	
	If BitAND(GUICtrlRead($radioAssemblyReport), $GUI_CHECKED) = $GUI_CHECKED Then ChangeUrgentAssembly("AssemblyReport")
EndFunc


Func _GetDOSOutput($sCommand)
    Local $iPID, $sOutput = ""

    $iPID = Run('"' & @ComSpec & '" /c ' & $sCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
    While 1
        $sOutput &= StdoutRead($iPID, False, False)
        If @error Then
            ExitLoop
        EndIf
        Sleep(10)
    WEnd
    Return $sOutput
EndFunc 
	
Func _excuteSQL($sqlQuery)
	_MySQL_Real_Query($MysqlConn, $sqlQuery)
	
	$res = _MySQL_Store_Result($MysqlConn)
	
	$arrResult = _MySQL_Fetch_Result_StringArray($res)
	
	Return $arrResult
	
EndFunc

Func checkDeviceType()
	$getChassis =  StringSplit((StringStripWS(_GetDOSOutput("wmic path win32_systemenclosure get chassistypes"), 4)), " ")
	;$getChassis[2] is chassistype number.
	$chassistype = StringRegExp($getChassis[2], '{(.*?)}', $STR_REGEXPARRAYMATCH)
	
	If _ArraySearch($laptopChassisType, $chassistype[0]) =  -1 Then 
		Return "PC"
	Else 
		Return "Laptop"
	EndIf
	
EndFunc
	
	
Func _Exit()	
	_MySQL_Free_Result($res)
	_MySQL_Close($MysqlConn)
	_MySQL_EndLibrary()
	DllClose($hDLL)
	Exit 
EndFunc



