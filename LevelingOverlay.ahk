#SingleInstance, force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include, %A_ScriptDir%\lib\JSON.ahk
;#Include, %A_ScriptDir%\lib\Gdip2.ahk

Menu, Tray, Icon, %A_ScriptDir%\poe.ico
Menu, Tray, Tip, Path of Exile - Leveling Overlays

GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExileSteam.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64Steam.exe

;
; ========= Settings =========
;
global data := {}
Try {
    FileRead, JSONFile, %A_ScriptDir%\data.json
    data := JSON.Load(JSONFile)
    If (not data.acts.Length()) {
        MsgBox, 16, , Error reading zone data! `n`nExiting script.
        ExitApp        
    }
} Catch e {
    MsgBox, 16, , % e "`n`nExiting script."
    ExitApp
}
 
opacity := 140
gui_1_toggle := 0
gui_2_toggle := 0
linenumber := 1

global maxImages := 5
global windowTrans := 180
global xPosLayoutParent := Round(A_ScreenWidth / 2) - Round(((maxImages * 110) + (maxImages * A_Index)) / 2)
global xPosSkills := xPosLayoutParent + ((maxImages * 110) + (maxImages * A_Index))
global skillsWidth := 330   ; max width
global xPosXPRange := xPosSkills + skillsWidth + 2

global PoEWindowHwnd := ""
WinGet, PoEWindowHwnd, ID, ahk_group PoEWindowGrp

global xp_active := false
global skills_active := false
global layout_active := false
global image_active := false
global LastCounter := 0
global Counter := 0

Gosub, DrawGUI1
Gosub, DrawGUI2_1
Gosub, DrawGUI3_1
SetTimer, ShowGuiTimer, 250

Return


;
; ========= MAIN / GUI =========
;
 
 
 
;
; ========= HOTKEY =========
;
 
;========== Quest Rewards =======
#IfWinActive, ahk_group PoEWindowGrp
+F3:: ; Display/Hide gem leveler window hotkey
    if (gui_2_toggle = 0)
    {
        Gosub, DrawGUI2_1
    }

    else
    {
        Gui, 2:Destroy
        gui_2_toggle := 0
    }
    Gosub, ActivatePOE
    return
     
!F3::
        Gui, 2:Destroy
        Gosub, DrawGUI2_1
        return

    Gosub, ActivatePOE     
return
 
 
;========== XP Range =======
#IfWinActive, ahk_group PoEWindowGrp
+F4:: ; Display/Hide xp range window hotkey
    if (gui_1_toggle = 0)
    {
        Gosub, DrawGUI1
    }
    else
    {
        Gui, 1:Destroy
        gui_1_toggle := 0
    }
    Gosub, ActivatePOE
return
 
;========== Zone Layouts =======
#IfWinActive, ahk_group PoEWindowGrp
+F1:: ; Display/Hide zone layout window hotkey
    if (gui_3_toggle = 0)
    {
        Gosub, DrawGUI3_1
    }
    else
    {
        Gui, 3:Destroy
        Gui, Controls:Destroy
        Loop, % maxImages {
            Gui, Image%A_Index%:Destroy
        }        
        gui_3_toggle := 0
    }
    Gosub, ActivatePOE
return

; Dropdown tab switching hotkeys listed below

#IfWinActive, ahk_group PoEWindowGrp
^F1::
GuiControl, Controls:+AltSubmit, DdlA
Gui, Controls:Submit, NoHide
pos := DdlA
GuiControl, Controls:-AltSubmit, DdlA
if (pos > 1) {
    Gui, Controls:Submit, NoHide
    pos := pos - 1
    GuiControl, Controls:Choose, DdlA, % "|" pos
}
Gosub, ActivatePOE
return

#IfWinActive, ahk_group PoEWindowGrp
!F1::
GuiControl, Controls:+AltSubmit, DdlA
Gui, Controls:Submit, NoHide
pos := DdlA
GuiControl, Controls:-AltSubmit, DdlA
Gui, Controls:Submit, NoHide
pos := pos + 1
GuiControl, Controls:Choose, DdlA, % "|" pos
Gosub, ActivatePOE
return

#IfWinActive, ahk_group PoEWindowGrp
^F2::
GuiControl, Controls:+AltSubmit, DdlZ
Gui, Controls:Submit, NoHide
pos := DdlZ
GuiControl, Controls:-AltSubmit, DdlZ
if (pos > 1) {
    Gui, Controls:Submit, NoHide
    pos := pos - 1
    GuiControl, Controls:Choose, DdlZ, % "|" pos
}
Gosub, ActivatePOE
return

#IfWinActive, ahk_group PoEWindowGrp
!F2:: 
GuiControl, Controls:+AltSubmit, DdlZ
Gui, Controls:Submit, NoHide
pos := DdlZ
GuiControl, Controls:-AltSubmit, DdlZ
Gui, Controls:Submit, NoHide
pos := pos + 1
GuiControl, Controls:Choose, DdlZ, % pos
Gosub, changeZone
Gosub, ActivatePOE
return



 
;========== Subs and Functions =======
 
ActivatePOE:
    WinActivate, ahk_id %PoEWindowHwnd%
return

DrawGUI1:
    Gui, 1:+E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndXpWindow
    Gui, 1:Font, s9, Consolas
    WinSet, Transparent, %opacity%
    
    xp_ranges = 
    (LTrim
    XP Range
    1-15  | 3
    16-31 | 4    
    32-47 | 5
    48-63 | 6
    64-79 | 7
    80+   | 8
    )
    Gui, 1:Add, Text, x5 y+5, % xp_ranges

    CalculateCellTextDimensions(xp_ranges, 9, "Consolas", xp_height, xp_width)
    _width := xp_width - 15
    _height:= xp_height
    
    Gui, 1:Show, x%xPosXPRange% y5 w%_width% h%_height%
    gui_1_toggle := 1
return
 
 
DrawGUI2_1:
    Gui, 2:+E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndSkillGemsWindow
    Gui, 2:font, s9, Arial
    WinSet, Transparent, %opacity%
	
    skillText := ""
	Loop
	{
		FileReadLine, ReadLine, gemlist.txt, %linenumber%
		{
			if ErrorLevel = 0
			{
				linenumber += 1
			} else
			{
				linenumber = 1
				break
			}
			if ReadLine = 
			{
				break
			}
            skillText .= ReadLine "`n"
		}
		if ReadLine = 
			{
				break
			}
	}
    Gui, 2:Add, Text, x5 y+5, % skillText

    CalculateCellTextDimensions(skillText, 9, "Arial", skill_height, skill_width)
    skill_width := (skill_width > skillsWidth) ? skillsWidth : skill_width
    _height:= skill_height + 10
    
    Gui, 2:Show, x%xPosSkills% y5 w%skill_width% h%_height%, Gui 2
    gui_2_toggle := 1
return

DrawGUI3_1:
    Gui, Parent:New, +AlwaysOnTop +ToolWindow +hwndParentWindow
    Gui, Parent:Color, brown    
    Gui, Parent:Show, w100 h80 x%xPosLayoutParent% y5
    WinSet, TransColor, brown, A
    
    ; make tooltip clickthrough and remove borders
    ; doesn't work
	WinSet, ExStyle, +0x20, ahk_id %ParentWindow% ; 0x20 = WS_EX_CLICKTHROUGH
    WinSet, Style, -0xC00000, ahk_id %ParentWindow%
    
    LastCounter := Counter
    Counter := 0
    Loop, % maxImages {
        filepath := "" A_ScriptDir "\Overlays\" data.DdlA "\" data.DdlZ "_Seed_" A_Index ".jpg" ""
        xPos := xPosLayoutParent + maxImages * 110 - (A_Index) * 110 - (5 * A_Index)

        If (FileExist(filepath)) {
            Gui, Image%A_Index%:New, -resize -SysMenu -Caption +AlwaysOnTop +hwndImage%A_Index%Window
            Gui, Image%A_Index%:Add, Picture, VPic%A_Index% x0 y0 w110 h60, %filepath%
            Gui, Image%A_Index%:Show, w110 h60 x%xPos% y5, Image%A_Index%
            Gui, Image%A_Index%:+OwnerParent
            Gui, Image%A_Index%: +LastFound
            WinSet, Transparent, %windowTrans%
            Counter := Counter + 1
        }
    }
    
    Gui, Controls:+E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndControls
    Gui, Controls:Color, gray
    Gui, Controls:Font, s9, Arial
    Gui, Controls:Add, DropDownList, VDdlA GchangeAct x0 y0 w90 h200 , % GetDelimitedActListString(data.zones, "Act I")
    Gui, Controls:Add, DropDownList, VDdlZ GchangeZone x+5 y0 w120 h250 , % GetDelimitedZoneListString(data.zones, "Act I")
    Gui, Controls:+OwnerParent
    xPos := xPosLayoutParent + 330
    Gui, Controls:Show, h21 w215 x%xPos% y68, Controls

    gui_3_toggle := 1
return

GetDelimitedActListString(data, act) {
	dList := ""

	For key, zone in data {        
        dList .= "|" . zone.act
        
        If (zone.act = act) {
            dList .= "|"
        }        
	}    
	Return RegExReplace(dList, "^\|")
}

GetDelimitedZoneListString(data, act) {
	dList := ""

	For key, zone in data {
        If (zone.act = act) {
            For k, val in zone.list {
                dList .= "|" . val 
                If (val = zone.default) {
                    dList .= "|"
                }
            }
        }        
	}
	Return RegExReplace(dList, "^\|")
}

GetDefaultZone(zones, act) {
    For key, zone in zones {
        If (zone.act = act) {
            Return zone.default
        }        
	}
}

changeAct:
    Gui, Controls:Submit, NoHide
    
    Loop, % maxImages {
        Gui, Image%A_Index%:Submit, NoHide    
    }
    
    GuiControl,,DdlZ, % "|" GetDelimitedZoneListString(data.zones, DdlA)
    DdlZ := GetDefaultZone(data.zones, DdlA)

    Loop, % maxImages {
        filepath := "" A_ScriptDir "\Overlays\" DdlA "\" DdlZ "_Seed_" A_Index ".jpg" ""
        If (FileExist(filepath)) {
            GuiControl,Image%A_Index%:,Pic%A_Index%, *w110 *h60 %filepath%        
            Gui, Image%A_Index%:Show
            Gui, Image%A_Index%:+OwnerParent
        } Else {
            Gui, Image%A_Index%:Destroy
        }
    }
    GoSub, ActivatePOE
return

changeZone:
    Gui, Controls:Submit, NoHide
    
    Loop, % maxImages {
        Gui, Image%A_Index%:Submit, NoHide
    }
    
    LastCounter := Counter
    Counter := 0
    Loop, % maxImages {
        filepath := "" A_ScriptDir "\Overlays\" DdlA "\" DdlZ "_Seed_" A_Index ".jpg" ""
        If (FileExist(filepath)) {
            GuiControl,Image%A_Index%:,Pic%A_Index%, *w110 *h60 %filepath%
            Gui, Image%A_Index%:Show
            Gui, Image%A_Index%:+OwnerParent
            Counter := Counter + 1
        } Else {
            Gui, Image%A_Index%:Destroy
        }
    }
    If (Counter > LastCounter) {
        Loop, % maxImages - LastCounter {
            CurrentIndex := A_Index + LastCounter
            filepath := "" A_ScriptDir "\Overlays\" DdlA "\" DdlZ "_Seed_" CurrentIndex ".jpg" ""
            xPos := xPosLayoutParent + maxImages * 110 - (CurrentIndex) * 110 - (5 * CurrentIndex)
            

            If (FileExist(filepath)) {
                Gui, Image%CurrentIndex%:New, -resize -SysMenu -Caption +AlwaysOnTop +hwndImage%CurrentIndex%Window
                Gui, Image%CurrentIndex%:Add, Picture, VPic%CurrentIndex% x0 y0 w110 h60, %filepath%
                Gui, Image%CurrentIndex%:Show, w110 h60 x%xPos% y5, Image%CurrentIndex%
                Gui, Image%CurrentIndex%:+OwnerParent
                Gui, Image%CurrentIndex%: +LastFound
                WinSet, Transparent, %windowTrans%
            }
        }
    }
    GoSub, ActivatePOE
return

ShowGuiTimer:
    ; check all if one of the windows is active (focused)
    poe_active := WinActive("ahk_id" PoEWindowHwnd)
    xp_active := WinActive("ahk_id" XpWindow)
    skills_active := WinActive("ahk_id" SkillGemsWindow)
    layout_active := WinActive("ahk_id" ParentWindow)
    controls_active := WinActive("ahk_id" Controls)
    
    image_active := false
    Loop, % maxImages {
        iid := Image%A_Index%Window
        If (WinActive("ahk_id" iid)) {
            image_active := true
        }       
    }
    
    If (poe_active or (xp_active or skills_active or layout_active or image_active or controls_active)) {
        ; show all gui windows
        GoSub, ShowAllWindows
    } Else {
        GoSub, HideAllWindows
    }
return

ShowAllWindows:
    If (gui_3_toggle) {
        If (not layout_active) {
            Gui, Parent:Show, NoActivate
        }
        If (not controls_active) {
            Gui, Controls:Show, NoActivate
            Gui, Controls:+OwnerParent
        }
        
        If (not image_active) {
            Loop, % maxImages {
                Gui, Image%A_Index%:Show, NoActivate
                Gui, Image%A_Index%:+OwnerParent
            }
        }
    }
    
    If (not skills_active and gui_1_toggle) {
        Gui, 1:Show, NoActivate
    }    
    If (not xp_active and gui_2_toggle) {
        Gui, 2:Show, NoActivate
    }
return

HideAllWindows:
    Gui, Parent:Cancel
    Gui, Controls:Cancel
    
    Loop, % maxImages {
        Gui, Image%A_Index%:Cancel
    }
    
    Gui, 1:Cancel
    Gui, 2:Cancel
return

; ==================================================================================================================================
; Function:	CalculateCellTextDimensions	 
;  			Calculates width and height of a string. Multiline support.
; Parameters:	
;			value	- text to measure. 
;			fontSize	- texts font size.
;			font		- texts font family.
;			height	- ByRef variable, calculated height.
;			width	- ByRef variable, calculated width.
;			newValue	- ByRef variable, new value (for multiline text).
; Returns:
;			Height, width and newValue as ByRef variables.
; ==================================================================================================================================
CalculateCellTextDimensions(value, fontSize, font, ByRef height = 0, ByRef width = 0, ByRef newValue = "") {
    value := RegExReplace(value, "\r|\n$")
    height := 0
    width := 0
    Loop, Parse, value, `n, `r
    {
        string := A_LoopField			
        StringReplace, string, string, `r,, All
        StringReplace, string, string, `n,, All
        
        emptyLine := false
        If (not StrLen(string)) {
            string := "A"				; don't prevent emtpy lines, just having a linebreak will break the text measuring 
            emptyLine := true				
        }
        string := " " Trim(string) " "	; add spaces as table padding
        
        If (emptyLine) {
            newValue .= "`n"
        } Else {
            newValue .= string "`n"
        }

        If (StrLen(string)) {
            size := Font_DrawText(string, "", "s" fontSize ", " font, "CALCRECT SINGLELINE NOCLIP")          
            width := width > size.W ? width : size.W
            height += size.H
        }
    }
    
    Return 
}

; ==================================================================================================================================
; Original script by majkinetor.
; Fixed by Eruyome.
;	
; https://github.com/majkinetor/mm-autohotkey/blob/master/Font/Font.ahk
;	
; Function:		CreateFont
;				Creates the font and optinally, sets it for the control.
; Parameters:
;				hCtrl 	- Handle of the control. If omitted, function will create font and return its handle.
;				Font  	- AHK font defintion ("s10 italic, Courier New"). If you already have created font, pass its handle here.
;				bRedraw	- If this parameter is TRUE, the control redraws itself. By default 1.
; Returns:	
;				Font handle.
; ==================================================================================================================================
CreateFont(HCtrl="", Font="", BRedraw=1) {
    static WM_SETFONT := 0x30

    ;if Font is not integer
    if (not RegExMatch(Trim(Font), "^\d+$"))
    {
        StringSplit, Font, Font, `,,%A_Space%%A_Tab%
        fontStyle := Font1, fontFace := Font2

      ;parse font 
        italic      := InStr(Font1, "italic")    ?  1    :  0 
        underline   := InStr(Font1, "underline") ?  1    :  0 
        strikeout   := InStr(Font1, "strikeout") ?  1    :  0 
        weight      := InStr(Font1, "bold")      ? 700   : 400 

      ;height 

        RegExMatch(Font1, "(?<=[S|s])(\d{1,2})(?=[ ,]*)", height) 
        ifEqual, height,, SetEnv, height, 10
        RegRead, LogPixels, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontDPI, LogPixels 
        height := -DllCall("MulDiv", "int", Height, "int", LogPixels, "int", 72) 
    
        IfEqual, Font2,,SetEnv Font2, MS Sans Serif
     ;create font 
        hFont   := DllCall("CreateFont", "int",  height, "int",  0, "int",  0, "int", 0
                          ,"int",  weight,   "Uint", italic,   "Uint", underline 
                          ,"uint", strikeOut, "Uint", nCharSet, "Uint", 0, "Uint", 0, "Uint", 0, "Uint", 0, "str", Font2, "Uint")
    } else hFont := Font
    ifNotEqual, HCtrl,,SendMessage, WM_SETFONT, hFont, BRedraw,,ahk_id %HCtrl%
    return hFont
}

; ==================================================================================================================================
;
; Original script by majkinetor.
; Fixed by Eruyome.
;
; https://github.com/majkinetor/mm-autohotkey/blob/master/Font/Font.ahk
;
; Function:	DrawText
;			Draws text using specified font on device context or calculates width and height of the text.
; Parameters: 
;		Text		- Text to be drawn or measured. 
;		DC		- Device context to use. If omitted, function will use Desktop's DC.
;		Font		- If string, font description in AHK syntax. If number, font handle. If omitted, uses the system font to calculate text metrics.
;		Flags	- Drawing/Calculating flags. Space separated combination of flag names. For the description of the flags see <http://msdn.microsoft.com/en-us/library/ms901121.aspx>.
;		Rect		- Bounding rectangle. Space separated list of left,top,right,bottom coordinates. 
;				  Width could also be used with CALCRECT WORDBREAK style to calculate word-wrapped height of the text given its width.
;				
; Flags:
;			CALCRECT, BOTTOM, CALCRECT, CENTER, VCENTER, TABSTOP, SINGLELINE, RIGHT, NOPREFIX, NOCLIP, INTERNAL, EXPANDTABS, AHKSIZE.
; Returns:
;			Decimal number. Width "." Height of text. If AHKSIZE flag is set, the size will be returned as w%w% h%h%
; ==================================================================================================================================	
Font_DrawText(Text, DC="", Font="", Flags="", Rect="") {
    static DT_AHKSIZE=0, DT_CALCRECT=0x400, DT_WORDBREAK=0x10, DT_BOTTOM=0x8, DT_CENTER=0x1, DT_VCENTER=0x4, DT_TABSTOP=0x80, DT_SINGLELINE=0x20, DT_RIGHT=0x2, DT_NOPREFIX=0x800, DT_NOCLIP=0x100, DT_INTERNAL=0x1000, DT_EXPANDTABS=0x40

    hFlag := (Rect = "") ? DT_NOCLIP : 0

    StringSplit, Rect, Rect, %A_Space%
    loop, parse, Flags, %A_Space%
        ifEqual, A_LoopField,,continue
        else hFlag |= DT_%A_LoopField%

    if (RegExMatch(Trim(Font), "^\d+$")) {
        hFont := Font, bUserHandle := 1
    }
    else if (Font != "") {
        hFont := CreateFont( "", Font)
    }
    else {
        hFlag |= DT_INTERNAL
    }

    IfEqual, hDC,,SetEnv, hDC, % DllCall("GetDC", "Uint", 0, "Uint")
    ifNotEqual, hFont,, SetEnv, hOldFont, % DllCall("SelectObject", "Uint", hDC, "Uint", hFont)

    VarSetCapacity(RECT, 16)
    if (Rect0 != 0)
        loop, 4
            NumPut(Rect%A_Index%, RECT, (A_Index-1)*4)

    h := DllCall("DrawTextA", "Uint", hDC, "Str", Text, "int", StrLen(Text), "uint", &RECT, "uint", hFlag)

    ;clean
    ifNotEqual, hOldFont,,DllCall("SelectObject", "Uint", hDC, "Uint", hOldFont) 
    ifNotEqual, bUserHandle, 1, DllCall("DeleteObject", "Uint", hFont)
    ifNotEqual, DC,,DllCall("ReleaseDC", "Uint", 0, "Uint", hDC) 
    
    w	:= NumGet(RECT, 8, "Int")
    
    return InStr(Flags, "AHKSIZE") ? "w" w " h" h : { "W" : w, "H": h }
}

GuiClose:
ExitApp