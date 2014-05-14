#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force

; UHDL_Names_CDM.ahk

; variables ================================
reportfile = UHDL_Names_Report_%A_YYYY%%A_MM%%A_DD%.txt
uhdlnamefile = UHDL_Names.txt
appname = UHDL Name Authorities 0.2
lcnaf = LCNAF
hot = HOT
uhdl = UHDL

runcount = 0
match = 0
userinfo =
userinfolen = 0
timestamplen = 17
divider =
previousNames =

TW = 860
BW = 890
Yvalue = 10
Ytext = 33
Ydiff = 50

Y1 := Yvalue
Y2 := Yvalue + Ydiff
Y3 := Yvalue + 2 * Ydiff
Y4 := Yvalue + 3 * Ydiff
Y5 := Yvalue + 4 * Ydiff

YT1 = 25
YT2 := Ytext + Ydiff
YT3 := Ytext + 2 * Ydiff
YT4 := Ytext + 3 * Ydiff
YT5 := Ytext + 4 * Ydiff
; variables ================================

Gui, 1:Color, d0d0d0, 912206
Gui, 1:Show, h0 w0, %appname%

Menu, FileMenu, Add, &Reload, Reload
Menu, FileMenu, Add, E&xit, Exit
Menu, EditMenu, Add, &Authority File    (Ctrl+Alt+A), Authorities
Menu, EditMenu, Add, &Report File         (Ctrl+Alt+R), Report
Menu, MenuBar, Add, &File, :FileMenu
Menu, MenuBar, Add, &Edit, :EditMenu
Gui, Menu, MenuBar

; labels ================================
Gui, Font,, Arial

Gui, Add, Text, x10 y%Y1%, PREVIOUS NAMES
Gui, Add, Text, x10 y%Y2% w100 h20, NAMES
Gui, Add, Text, x10 y%Y3% w100 h20, LCNAF
Gui, Add, Text, x10 y%Y4% w100 h20, HOT
Gui, Add, Text, x10 y%Y5% w100 h20, UHDL

; STATIC 6-10
Gui, Add, Text, x30 y%YT1% w%TW% h20,
Gui, Add, Text, x30 y%YT2% w%TW% h20,
Gui, Add, Text, x30 y%YT3% w%TW% h20,
Gui, Add, Text, x30 y%YT4% w%TW% h20,
Gui, Add, Text, x30 y%YT5% w%TW% h20,

Gui, Add, GroupBox, x5 y0 w%BW% h50,
Gui, Add, GroupBox, x5 y50 w%BW% h215,
; labels ================================



WinGetPos, winX, winY, winWidth, winHeight, %appname%
winX+=%winWidth%
Gui, 1:Show, x%winX% y%winY% h270 w900, %appname%
WinActivate, %appname%


; hotkeys ================================
^!a::
	Gosub, Authorities
Return

^!r::
	Gosub, Report
Return

^!u::
	Send, uhdl
Return

; name mapping script
^!n::
	WinGet, cdmwindow, ID, CONTENTdm ; CDM window id

	; variables
	lcnafconfirmed =
	hotconfirmed =
	localconfirmed =
	novocablist =
	novocab = 0

	clipsave = %clipboard% ; save clipboard for later restoration
	clipboard =

	if (runcount == 0)
	{
		InputBox, input,, Please Enter Your Initials,, 180, 125,,,,,
		if ErrorLevel
			Return
		else
		{
			username = %input%
			InputBox, input,, Please Enter The Project Name,, 380, 125,,,,,
			if ErrorLevel
				Return
			else
			{
				projectname = %input%
				userinfo = %projectname% %username%
				StringLen, userinfolen, userinfo
				dividerlen := userinfolen + timestamplen + 2
				Loop, %dividerlen%
				{
					divider .= "_"
				}
			}
		}
	}

	if (runcount > 0)
	{
		ControlSetText, Static6, %previousNames%, %appname% ; update PREVIOUS NAMES
	}

	; format report entry
	FileAppend, %divider%`n%A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min% %userinfo%`n`n, %reportfile%

	; read in name authority mappings
	FileRead, namelist, %uhdlnamefile%

	; send names in LCNAF field to variable via clipboard
	Send, {F2}
	Sleep, 50
	Send, ^a
	Sleep, 50
	Send, ^c
	Sleep, 50
	Send, {Tab}
	Sleep, 50
	Send, {Left}
	Clipwait
	searchstring = %clipboard%
	StringReplace, searchstring, searchstring, `n,, All
	StringReplace, searchstring, searchstring, `r,, All

	FileAppend, NAMES: %searchstring%`n`n, %reportfile%
	ControlSetText, Static7, %searchstring%, %appname% ; update NAMES in gui

	; loop matches to O: drive authority lists
	Loop, parse, searchstring, `;
	{
		match = 0
		name = %A_LoopField%
		StringReplace, name, name, `n,, All
		StringReplace, name, name, `r,, All

		StringLen, length, A_LoopField
		if (length > 0)
		{
			Loop, parse, namelist, `n
			{
				lcnafconfirmed := NameMap(lcnaf, A_LoopField, name, lcnafconfirmed)
				hotconfirmed := NameMap(hot, A_LoopField, name, hotconfirmed)
				localconfirmed := NameMap(uhdl, A_LoopField, name, localconfirmed)
			}

			if (match == 0)
			{
				Run, http://www.tshaonline.org/handbook-search-results?arfarf=%name%
				Run, http://id.loc.gov/search/?q=%name%&q=cs`%3Ahttp`%3A`%2F`%2Fid.loc.gov`%2Fauthorities`%2Fnames

				Sleep, 1000
				Gui, 2:Add, Text,, `n%name%`n
				Gui, 2:Add, ListBox, vListChoice, LCNAF|HOT|UHDL
				Gui, 2:Add, Text,, Enter authorized name:
				Gui, 2:Add, Edit, w280 vauthorizedname, %A_LoopField%
				Gui, 2:Add, Text,, Enter Authority URI:
				Gui, 2:Add, Edit, w280 vauthorityURI,
				Gui, 2:Add, Button, gChoiceSubmit, OK
				Gui, 2:Add, Button, x+50 gChoiceCancel, Cancel
				Gui, 2:Show, w300, Vocab Choice
				WinWaitClose, Vocab Choice

				if (ListChoice == "LCNAF")
				{
					lcnafconfirmed := lcnafconfirmed . authorizedname . "; "
					FileAppend, `nLCNAF`t%name%`t%authorizedname%`t%authorityURI%`t%username%`t%A_YYYY%%A_MM%%A_DD%, %uhdlnamefile%
				}

				else if (ListChoice == "HOT")
				{
					hotconfirmed := hotconfirmed . authorizedname . "; "
					FileAppend, `nHOT`t%name%`t%authorizedname%`t%authorityURI%`t%username%`t%A_YYYY%%A_MM%%A_DD%, %uhdlnamefile%
				}

				else if (ListChoice == "UHDL")
				{
					localconfirmed := localconfirmed . authorizedname . "; "
					FileAppend, `nUHDL`t%name%`t%authorizedname%`t%authorityURI%`t%username%`t%A_YYYY%%A_MM%%A_DD%, %uhdlnamefile%
				}
				else if (ListChoice == "")
				{
					novocab++
					novocablist := novocablist . "LCNAF/HOT/UHDL`t" . name . "`t" . authorizedname . "`t" . authorityURI . "`t" . username . "`t" . A_YYYY . A_MM . A_DD . "`n"
				}
			}

			prev_lcnafconfirmed = %lcnafconfirmed%
			prev_hotconfirmed = %hotconfirmed%
			prev_localconfirmed = %localconfirmed%
		}
	}

	; prepare the field entries
	StringTrimRight, lcnafprint, lcnafconfirmed, 2
	StringTrimRight, hotprint, hotconfirmed, 2
	StringTrimRight, localprint, localconfirmed, 2

	; add field entries to report
	FileAppend, LCNAF: %lcnafprint%`n, %reportfile%
	FileAppend, HOT: %hotprint%`n, %reportfile%
	FileAppend, Local: %localprint%`n`n, %reportfile%
	if (novocab > 0)
	{
		FileAppend, %novocablist%`n`n, %reportfile%
	}

	; activate gui
	WinActivate, %appname%

	; add field entries to gui
	ControlSetText, Static8, %lcnafprint%, %appname%
	ControlSetText, Static9, %hotprint%, %appname%
	ControlSetText, Static10, %localprint%, %appname%

	; activate cdm window
	WinActivate, ahk_id %cdmwindow%

	; delete current lcnaf field
	Send, {Delete}
	Sleep, 100

	; enter lcnaf matches
	Send, {F2}
	Sleep, 100
	Send, %lcnafprint%
	Sleep, 100
	Send, {Tab}
	Sleep, 100

	; enter hot matches
	Send, {F2}
	Sleep, 100
	Send, %hotprint%
	Sleep, 100
	Send, {Tab}
	Sleep, 100
	Send, {Tab}
	Sleep, 100

	; enter local matches
	Send, {F2}
	Sleep, 100
	Send, %localprint%
	Sleep, 100
	Send, {Tab}

	; reset cursor
	Send, {Left 4}
	Sleep, 50

	previousNames = %searchstring% ; save names for next run

	; restore clipboard
	clipboard = %clipsave%

	if (novocab > 0)
	{
		MsgBox,, Vocab Error, %novocab% Term(s) Entered For which No Vocab Was Chosen`n`nPlease see the report file and choose the appropriate vocabulary.
		Run, %reportfile%
	}

	runcount++
Return

; gui submit button
ChoiceSubmit:
	Gui, Submit
	Gui, Destroy
Return

; gui cancel button
ChoiceCancel:
	Gui, Destroy
	ExitApp
Return

; map function ================================
NameMap(vocabulary, listentry, name, confirmed)
{
	count = 0
	Loop, parse, listentry, `t
	{
		count++
		if (count == 1)
		{
			IfEqual, vocabulary, %A_LoopField%
			{
				Continue
			}
			Else
			{
				Break
			}
		}

		if (count == 2)
		{
			matchname = %A_LoopField%
			StringReplace, matchname, matchname, `n,, All
			StringReplace, matchname, matchname, `r,, All
		}

		if (count == 3)
		{
			authorizedname = %A_LoopField%
			StringReplace, authorizedname, authorizedname, `n,, All
			StringReplace, authorizedname, authorizedname, `r,, All
			Break
		}
	}

	IfEqual, name, %matchname% ; if the current name matches
	{
		global match = 1
		IfNotInString, confirmed, %authorizedname% ; add authorized form
		{
			confirmed := confirmed . authorizedname . "; "
		}
	}

Return confirmed
}
; map function ================================

; menu functions ================================
Authorities:
	IfExist, C:\Program Files (x86)\Notepad++
	{
		Run, "C:\Program Files (x86)\Notepad++\notepad++.exe" %uhdlnamefile%
	}
	Else
	{
		Run, "C:\Program Files\Notepad++\notepad++.exe" %uhdlnamefile%
	}
Return

Report:
	IfExist, C:\Program Files (x86)\Notepad++
	{
		Run, "C:\Program Files (x86)\Notepad++\notepad++.exe" %reportfile%
	}
	Else
	{
		Run, "C:\Program Files\Notepad++\notepad++.exe" %reportfile%
	}
Return


Reload:
Reload

Exit:
ExitApp

GuiClose:
ExitApp
