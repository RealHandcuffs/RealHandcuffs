;
; Constant helper script for logging.
;
Scriptname RealHandcuffs:Log Const Hidden

; Log text with Info severity
Function Info(String text, RealHandcuffs:Settings settings) Global
    Message(text, 0, settings == None || settings.LogLevelPapyrus <= 0, settings != None && settings.LogLevelNotificationArea <= 0)
EndFunction

; Log text with Warning severity
Function Warning(String text, RealHandcuffs:Settings settings) Global
    Message(text, 1, settings == None || settings.LogLevelPapyrus <= 1, settings == None || settings.LogLevelNotificationArea <= 1)
EndFunction

; Log text with Error severity
Function Error(String text, RealHandcuffs:Settings settings) Global
    Message(text, 2, settings == None || settings.LogLevelPapyrus <= 2, settings == None || settings.LogLevelNotificationArea <= 2)
EndFunction

; Internal logger function called by the other functions
Function Message(String text, Int logLevel, Bool logToPapyrus, Bool logToNotificationArea) Global
    If (logToPapyrus)
        RealHandcuffs:DebugWrapper.Trace("[RealHandcuffs] " + text, logLevel)
    EndIf
    If (logToNotificationArea)
        RealHandcuffs:DebugWrapper.Notification("[RealHandcuffs] " + text)
    EndIf
EndFunction

; Return the id of a form as a string for logging.
String Function FormIdAsString(Form item) Global
    If (item == None)
        Return "None"
    EndIf
    Int formId = item.GetFormID()
    Int modId = formId / 0x01000000
    Int baseId
    If (formId >= 0)
        baseId = formId - modId * 0x1000000
    Else
        modId = (255 + modId)
        baseId = (256 - modId) * 0x1000000 + formId
    EndIf
    String hex = GetHexDigit(modId / 0x10) + GetHexDigit(modId % 0x10)
    hex += GetHexDigit(baseId / 0x00100000) + GetHexDigit((baseId / 0x00010000) % 0x10)
    hex += GetHexDigit((baseId / 0x00001000) % 0x10) + GetHexDigit((baseId / 0x00000100) % 0x10)
    hex += GetHexDigit((baseId / 0x00000010) % 0x10) + GetHexDigit(baseId % 0x10)
    Return hex
EndFunction

;
; Internal function to get the string for a single hex digit (a value in [0,15]).
;
String Function GetHexDigit(Int nibble) Global
    If (nibble < 8)
        If (nibble < 4)
            If (nibble < 2)
                If (nibble == 0)
                    Return "0"
                Else
                    Return "1"
                EndIf
            ElseIf (nibble == 2)
                Return "2"
            Else
                Return "3"
            EndIf
        ElseIf (nibble < 6)
            If (nibble == 4)
                Return "4"
            Else
                Return "5"
            EndIf
        ElseIf (nibble == 6)
            Return "6"
        Else
            Return "7"
        EndIf
    ElseIf (nibble < 12)
        If (nibble < 10)
            If (nibble == 8)
                Return "8"
            Else
                Return "9"
            EndIf
        ElseIf (nibble == 10)
            Return "A"
        Else
            Return "B"
        EndIf
    ElseIf (nibble < 14)
        If (nibble == 12)
            Return "C"
        Else
            Return "D"
        EndIf
    ElseIf (nibble == 14)
        Return "E"
    Else
        Return "F"
    EndIf
EndFunction