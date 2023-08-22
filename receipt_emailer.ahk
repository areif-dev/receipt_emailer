#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

ShortWait := 100
ElementDir = %A_ScriptDir%\elements\

ArScreens := []
ArScreens[1] := ElementDir . "save_as_popup.png"
ArScreens[2] := ElementDir . "new_invoice_screen.png"

; Waits for one of any specified images to appear on screen, then return the index 
; of the image that was found first 
; 
; @errors Sets ErrorLevel to 0 if an image was found. ErrorLevel to 1 if no images 
; are found within 60 seconds. ErrorLevel to 2 if one of the images fails to search 
; at all 
; @param ImageFiles {String[]} Array containing the paths to the images to search for 
; @returns {int} Returns -1 if an image failed to search at all or if no images 
; were found in 60 seconds. Otherwise, return the index of the image that was
; found first 
AwaitAnyElementsLoad(ImageFiles) 
{
    ; Pause 250 milliseconds between each interation for 240 iteration = total 
    ; possible wait of 60 seconds 
    loop, 240 
    {
        for i, file in ImageFiles 
        {
            ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, %file%
            if (ErrorLevel = 2) {
                return -1
            }
            else if (ErrorLevel = 0) 
                return i
        }
        Sleep, 250
    }

    return -1
}

; Wrapper for AwaitAnyElementsLoad that only searches for one ImageFile, rather 
; than a list 
;
; @param ImageFile {String} The location in the filesystem of the image to search 
; for 
; @returns void 
AwaitElementLoad(ImageFile)
{
    ImagesArray := []
    ImagesArray[1] := ImageFile
    FoundIndex := AwaitAnyElementsLoad(ImagesArray)

    if (FoundIndex = -1 && ErrorLevel = 2) {
        MsgBox, There was a problem searching for %ImageFile%
    } else if (FoundIndex = -1 && ErrorLevel = 1) {
        MsgBox, Could not find %ImageFile% in 60 seconds 
    }
}

; Make a system call to generate a GUID. The returned GUID will be enclosed in
; curly braces "{}"
; If the system call fails, then return a null string
CreateGUID()
{
    VarSetCapacity(pguid, 16, 0)
    if !(DllCall("ole32.dll\CoCreateGuid", "ptr", &pguid)) {
        size := VarSetCapacity(sguid, (38 << !!A_IsUnicode) + 1, 0)
        if (DllCall("ole32.dll\StringFromGUID2", "ptr", &pguid, "ptr", &sguid, "int", size))
            return StrGet(&sguid)
    }
    return ""
}

SendCtrlN() 
{
    ShortWait := 100
    Send, {Ctrl Down}
    Sleep % ShortWait * 3
    Send, n 
    Sleep % ShortWait * 3
    Send, {Ctrl Up}
}

ShowForm:
Gui, New,, Receipt Emailer Entry
Gui, Add, Text,, Starting Invoice
Gui, Add, Edit, vStartInvoice
Gui, Add, Text,, Last Invoice (Leave blank if same as Starting Invoice)
Gui, Add, Edit, vLastInvoice
Gui, Add, Text,, Customer ID (Leave blank to use customer id of first invoice)
Gui, Add, Edit, vCustomerID
Gui, Add, Text,, Customer Email (Leave blank to use default customer email)
Gui, Add, Edit, w250 vCustomerEmail
Gui, Add, Button, Default gVerifyInput, Submit
Gui, Show
Return

VerifyInput:
Gui, Submit
Gui, Destroy
if StartInvoice is not integer
{
        MsgBox, You must enter an integer for Starting Invoice!
        GoSub, ShowForm
        Return
}
if (LastInvoice = "") {
        LastInvoice := StartInvoice
}
if LastInvoice is not integer
{
        MsgBox, You must enter an integer for Last Invoice!
        GoSub, ShowForm
}
GoSub, Run313
Return

Run313:
if WinExist("REIFSNYDER'S AG CENTER - ABC Accounting Client")
    WinActivate
else
    Run, "C:\ABC Software\Client4\abctwin.exe"

if (CustomerId = "") {
        Send, {F10}
        AwaitElementLoad(ElementDir . "selection_screen.png")
        Send, r
        AwaitElementLoad(ElementDir . "accounts_receivable_screen.png")
        SendCtrlN()

        foundElementIndex := AwaitAnyElementsLoad(ArScreens)
        if (foundElementIndex = -1) {
            MsgBox, Accounts Receivable screen did not clear after Ctrl+N
            return 
        } else if (foundElementIndex = 1) {
            Send, {Right}
            Sleep % ShortWait * 3 
            Send, {Enter}
            Sleep % ShortWait * 3

            if WinExist("REIFSNYDER'S AG CENTER - ABC Accounting Client")
                WinActivate
        }
        ControlClick, ThunderRT6TextBox2
        Sleep % ShortWait * 3
        ControlSetText, ThunderRT6TextBox2, %StartInvoice%
        Send, {Enter}
        Sleep % ShortWait * 3
        ControlGetText, CustomerId, ThunderRT6TextBox3
}

if (CustomerEmail = "") {
        Send, {F10}
        AwaitElementLoad(ElementDir . "selection_screen.png")
        Send, c
        AwaitElementLoad(ElementDir . "customer_screen.png")
        ControlGetText, CustomerEmail, ThunderRT6TextBox14
}

loop {
        if (CustomerEmail = "") {
                InputBox, CustomerEmail, Cannot Find Customer Email, Could not find valid customer email. Please enter one:
                if ErrorLevel
                        Return
        } else {
                break
        }
}

MsgBox, 1, Continue?, Customer ID: %CustomerId%`, Email: %CustomerEmail%, 120
IfMsgBox, Cancel
        Return
IfMsgBox, Timeout
        Return

Send, {F10}
AwaitElementLoad(ElementDir . "selection_screen.png")
Send, 3
AwaitElementLoad(ElementDir . "3_reports_screen.png")
Send, 13{Enter}{Enter}
AwaitElementLoad(ElementDir . "3_13_reports_screen.png")
Send, {Enter}
Sleep % ShortWait * 3
Send, %StartInvoice%{Enter}
Sleep % ShortWait * 3
Send, %LastInvoice%{Enter}
Sleep % ShortWait * 3
Send, x
AwaitElementLoad(ElementDir . "save_file_dialogue.png")
FileGUID := CreateGUID()
if (StrLen(FileGUID) > 0) {
        ; The GUID creation function was successful, so make the file id the GUID
        ; GUID is preferred over time because it is guaranteed to be unique
        FileID := SubStr(FileGUID, 2, StrLen(FileGUID) - 2)
} else {
        ; The GUID creation failed, so use the current time as the file id
        ; Current time is very likely to be unique, but may not be if the script
        ; is run in very quick succession or the system time is reset
        FormatTime, FileID,, yyyy-MM-ddTHH_mm
}
TextFileLocation = %A_ScriptDir%\3_13_%FileID%.txt
Send, %TextFileLocation%
Sleep % ShortWait * 3
Send, {Enter}

; Match titles that contain the given string anywhere
SetTitleMatchMode, 2
loop, 300 {
        if (FileExist(TextFileLocation)) and (WinExist(FileID)) {
                Run, %A_ScriptDir%\.virtual\Scripts\python.exe -m receipt_emailer %TextFileLocation% "%CustomerId%" "%CustomerEmail%"
                Sleep, 30000
                FileDelete, %TextFileLocation%
                break
        }
        else
                Sleep, 1000
}
ExitApp

GoSub, ShowForm
