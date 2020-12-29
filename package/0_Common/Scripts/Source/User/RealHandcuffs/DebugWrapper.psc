;
; A wrapper script for Debug functionality. This wrapper allows all other scripts to be compiled in release mode.
;
Scriptname RealHandcuffs:DebugWrapper Const Hidden

Function Notification(string asNotificationText) global
    Debug.Notification(asNotificationText)
EndFunction

Function Trace(string asTextToPrint, int aiSeverity = 0) global
    Debug.Trace(asTextToPrint, aiSeverity)
EndFunction

Function TraceStack(string asTextToPrint, int aiSeverity = 0) global
    Debug.TraceStack(asTextToPrint, aiSeverity)
EndFunction