; Update: 2018-8-11 (Added addTorrent support)

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
OnExit, ExitSub

Gosub, IniRead

; =================================
;		Menu
; =================================
Menu, lvMenu, Add, Open, Menu_Open
Menu, lvMenu, Add, Open Dir, Menu_OpenDir

; =================================
;		GUI
; =================================
Gui, Font, s10
Gui, Color, F0F0F0

Gui, Add, Text, h20 0x200 cBlue, RPC Server:
Gui, Add, Edit, ys hp w400 vRPC_server_url gEnable_BtnModify, % rpc_server

Gui, Add, Text, xm h20 0x200 cBlue, --rpc-secret=
Gui, Add, Edit, x+5 w200 gEnable_BtnModify vtoken, % rpc_token
Gui, Add, Text, x+5 hp 0x200, (Optional)
Gui, Add, Button, x+225 yp-23 w100 h40 vBtnModify gBtnModify Disabled, Modify

Gui, Add, Text, xm 0x10 w700, 

Gui, Add, Button, xm w150 gButtonNew, Add Url
Gui, Add, Button, x+40 gAddTorrentFile, Add Torrent File
Gui, Add, Button, x+40 vpause, Pause
Gui, Add, Button, x+40 vunpause, unpause

Gui, Add, ListView, xm w700 h200 NoSort vLV HwndHLV glvEvent, Name|Size|Progress|Time|Speed
	LV_SetWidth("220|100|150|100|100")
	LV_SetRowHeight(20)
	LVA_ListViewAdd("LV", "")

Gui, Add, Text, xm cBlue, Options
Gui, Add, Text, x+30, ( One option per line. Click
Gui, Add, Link, x+5, <a href="http://aria2.sourceforge.net/manual/en/html/aria2c.html#id2">here</a>
Gui, Add, Text, x+5, to see a complete list of options. )
Gui, Add, Edit, xm w700 h100 vaddUri_options, % addUri_options

Gui, Show
OnMessage("0x4E", "LVA_OnNotify")
Return

; =================================
;		Modify
; =================================
BtnModify:
	Gui, Submit, NoHide
	aria2.url   := RPC_server_url
	aria2.token := token

	GuiControl, Disable, BtnModify
Return

Enable_BtnModify:
	GuiControlGet, RPC_server_url
	GuiControl, % "Enable" !!RPC_server_url, BtnModify
Return

; =================================
;		New
; =================================
ButtonNew:
	Gui, +OwnDialogs
	InputBox, url, New, url:,, 500, 125
	If ErrorLevel
		Return
	If url is space
		Return

	GuiControlGet, addUri_options
	addUri_options := Options2obj(addUri_options)

	; Add url to aria2
	ret := aria2.addUri( [url], addUri_options )
	gid := ret.result

	; Add a new row and ProgressBar
	rowNumber := LV_Add()
	LVA_SetProgressBar("LV", rowNumber, 3, "s0xD8CB27 e0xFF91FF Smooth")
	
	; Record download info
	If !IsObject(gidList)
		gidList := []
	gidList.Insert( {gid: gid, rowNumber: rowNumber, fileName: fileName} )

	SetTimer, UpdateStatus, 1000
Return

; =================================
;		Add Torrent File
; =================================
AddTorrentFile:
	Gui, +OwnDialogs
	FileSelectFile, torrentFile, 1, %A_ScriptDir%, Select Torrent File, (*.torrent)
	if !torrentFile
		return

	GuiControlGet, addUri_options
	addUri_options := Options2obj(addUri_options)

	; Add url to aria2
	ret := aria2.addTorrent( torrentFile, addUri_options )
	gid := ret.result

	; Add a new row and ProgressBar
	rowNumber := LV_Add()
	LVA_SetProgressBar("LV", rowNumber, 3, "s0xD8CB27 e0xFF91FF Smooth")
	
	; Record download info
	If !IsObject(gidList)
		gidList := []
	gidList.Insert( {gid: gid, rowNumber: rowNumber, fileName: fileName} )

	SetTimer, UpdateStatus, 1000
Return

UpdateStatus:
	completedCount := 0

	For i, dl in gidList
	{
		If dl.stoped {
			completedCount += 1
			Continue
		}

		data := aria2.tellStatus( dl.gid ).result

		this_fileName := RegExReplace(data.files.1.path, ".*[/\\]")
		gidList[A_Index]["dir"] := data.dir

		If (data.status ~= "complete|paused") {
			gidList[A_Index]["stoped"] := data.status

			LVA_SetProgressBar("LV", dl.rowNumber, 3) ; Remove progressbar
			LV_Modify(dl.rowNumber, "", this_fileName, FormatByteSize(data.totalLength), data.status, "", "")
			completedCount += 1
			Continue
		}

		_size       := FormatByteSize(data.totalLength)
		_progress   := Floor(data.completedLength / data.totalLength * 100)
		_speed      := FormatByteSize(data.downloadSpeed)
		_timeRemain := FormatSeconds( (data.totalLength - data.completedLength) // data.downloadSpeed )

		LV_Modify(dl.rowNumber, "", this_fileName, _size, _progress, _timeRemain, _speed "/s")
		LVA_Progress("LV", dl.rowNumber, 3, _progress)
	}

	If ( completedCount = gidList.MaxIndex() )
		SetTimer, UpdateStatus, Off
Return

; =================================
;		Start / Pause / Remove
; =================================
ButtonPause:
ButtonUnPause:
	If !LV_GetNext() {
		Gui, +OwnDialogs
		MsgBox, Please select a row first!
		Return
	}

	nRow := 0
	While, ( nRow := LV_GetNext(nRow) ) {
		method := (A_ThisLabel = "ButtonPause") ? "pause" : "unpause"
		aria2[method]( gidList[nRow].gid )

		If (method = "unpause") {
			LVA_SetProgressBar("LV", nRow, 3, "s0xD8CB27 e0xFF91FF Smooth")
			gidList[nRow]["stoped"] := ""
		}
	}

	SetTimer, UpdateStatus, 1000
Return

; =================================
;		ContextMenu
; =================================
GuiContextMenu:
	If !(A_GuiControl = "LV" && selectedRow := LV_GetNext())
		Return

	LV_GetText(selectedStatus, selectedRow, 3)
	If (selectedStatus = "complete")
		Menu, lvMenu, Enable, Open
	Else
		Menu, lvMenu, Disable, Open

	Menu, lvMenu, Show
Return

Menu_Open:
	LV_GetText(selectedName, selectedRow, 1)
	Run, % gidList[selectedRow]["dir"] "\" selectedName
Return

Menu_OpenDir:
	Run, % gidList[selectedRow]["dir"]
Return

; =================================
;		lvEvent
; =================================
lvEvent:
	If ( A_GuiEvent = "DoubleClick" && selectedRow := LV_GetNext() ) {
		this_status := gidList[selectedRow]["stoped"]

		If !this_status
			SetTimer, ButtonPause, -1
		Else If ( this_status = "paused" )
			SetTimer, ButtonUnPause, -1
		Else If ( this_status = "complete" )
			SetTimer, Menu_Open, -1
	}
Return

; =================================
;		Ini Read/Write
; =================================
IniRead:
	iniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniRead, rpc_server    , %iniFile%, RPC    , rpc_server, http://127.0.0.1:6800/jsonrpc
	IniRead, rpc_token     , %iniFile%, RPC    , rpc_token , %A_Space%
	IniRead, addUri_options, %iniFile%, options
Return

IniWrite:
	iniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	Gui, Submit
	IniWrite, % rpc_server, %iniFile%, RPC, rpc_server
	IniWrite, % rpc_token , %iniFile%, RPC, rpc_token
	IniDelete, %iniFile%, options
	IniWrite, % addUri_options, %iniFile%, options
Return

; =================================
;		Exit
; =================================
GuiClose:
ExitApp

ExitSub:
	Gosub, IniWrite
ExitApp

; ======================================================= Functions =======================================================
#Include <LVA>
#Include <aria2>
#Include <LV_Functions>
#Include <b64>

FormatByteSize(Bytes){ ; by HotKeyIt, http://ahkscript.org/boards/viewtopic.php?p=18338#p18338
  static size:="bytes,KB,MB,GB,TB,PB,EB,ZB,YB"
  Loop,Parse,size,`,
    If (bytes>999)
      bytes:=bytes/1024
    else {
      bytes:=Trim(SubStr(bytes,1,4),".") " " A_LoopField
      break
    }
  return bytes
}

FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
{
    time = 19990101  ; *Midnight* of an arbitrary date.
    time += %NumberOfSeconds%, seconds
    FormatTime, mmss, %time%, mm:ss
    return NumberOfSeconds//3600 ":" mmss  ; This method is used to support more than 24 hours worth of sections.
}

Options2obj(options) {
	obj := {}

	options := Trim(options, " `t`r`n")
	options := RegExReplace(options, "im`a)^\s*-+")
	StringReplace, options, options, ",, All

	Loop, Parse, options, `n, `r
		If ( pos := InStr(A_LoopField, "=") )
			obj[ SubStr(A_LoopField, 1, pos-1) ] := SubStr(A_LoopField, pos+1)

	Return obj
}