#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

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
        Sleep, 1000
        Send, r
        Sleep, 1000
        ControlClick, ThunderRT6TextBox2
        Sleep, 1000
        ControlSetText, ThunderRT6TextBox2, %StartInvoice%
        Send, {Enter}
        Sleep, 1000

        if WinExist("Save changes before proceeding?") {
                WinActivate
                Sleep, 500
                Send, n
                Sleep, 1000
                if WinExist("REIFSNYDER'S AG CENTER - ABC Accounting Client")
                        WinActivate
        }

        ControlGetText, CustomerId, ThunderRT6TextBox3
}

if (CustomerEmail = "") {
        Send, {F10}
        Sleep, 1000
        Send, c
        Sleep, 1000
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
Sleep, 1000
Send, 3
Sleep, 1000
Send, 13{Enter}{Enter}
Sleep, 1000
Send, {Enter}
Sleep, 1000
Send, %StartInvoice%{Enter}
Sleep, 500
Send, %LastInvoice%{Enter}
Sleep, 500
Send, x
Sleep, 1000
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
Sleep, 500
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
