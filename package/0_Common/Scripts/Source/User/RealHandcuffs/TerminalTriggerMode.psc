;
; Script for the pin trigger mode subterminal in the shock collar terminal.
;
Scriptname RealHandcuffs:TerminalTriggerMode extends Terminal Const

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:ShockCollarTerminalData Property TerminalData Auto Const Mandatory

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTerminalRef)
    If (auiMenuItemID == 1 || auiMenuItemID == 5)
        TerminalData.TriggerMode = TerminalData.SimpleTrigger
        RealHandcuffs:Log.Info("User set trigger mode to SimpleTrigger.", Library.Settings)
    ElseIf (auiMenuItemID == 2 || auiMenuItemID == 6)
        TerminalData.TriggerMode = TerminalData.SingleSignalTrigger
        RealHandcuffs:Log.Info("User set trigger mode to SingleSignalTrigger.", Library.Settings)
    ElseIf (auiMenuItemID == 3 || auiMenuItemID == 7)
        TerminalData.TriggerMode = TerminalData.DoubleSignalTrigger
        RealHandcuffs:Log.Info("User set trigger mode to DoubleSignalTrigger.", Library.Settings)
    ElseIf (auiMenuItemID == 4 || auiMenuItemID == 8)
        TerminalData.TriggerMode = TerminalData.TripleSignalTrigger
        RealHandcuffs:Log.Info("User set trigger mode to TripleSignalTrigger.", Library.Settings)
    EndIf
EndEvent