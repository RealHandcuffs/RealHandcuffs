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
    Return LL_FourPlay.IntToHexString(formId)
EndFunction
