;
; Script for the torture mode subterminal in the shock collar terminal.
;
Scriptname RealHandcuffs:TerminalTortureMode extends Terminal Const

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:ShockCollarTerminalData Property TerminalData Auto Const Mandatory

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTerminalRef)
    If (auiMenuItemID == 1 || auiMenuItemID == 2)
        ; enable torture mode
        TerminalData.RestartTortureMode = true
        TerminalData.TortureModeFrequency = 1.0
    ElseIf (auiMenuItemID == 3 || auiMenuItemID == 4)
        ; disable torture mode
        TerminalData.RestartTortureMode = true
        TerminalData.TortureModeFrequency = 0.0
    ElseIf (auiMenuItemID == 5 || auiMenuItemID == 6)
        ; more frequent
        If (TerminalData.TortureModeFrequency == 0.2)
            TerminalData.TortureModeFrequency = 0.1666
        ElseIf (TerminalData.TortureModeFrequency == 0.25)
            TerminalData.TortureModeFrequency = 0.2
        ElseIf (TerminalData.TortureModeFrequency == 0.3333)
            TerminalData.TortureModeFrequency = 0.25
        ElseIf (TerminalData.TortureModeFrequency == 0.5)
            TerminalData.TortureModeFrequency = 0.3333
        ElseIf (TerminalData.TortureModeFrequency == 1)
            TerminalData.TortureModeFrequency = 0.5
        ElseIf (TerminalData.TortureModeFrequency > 1)
            TerminalData.TortureModeFrequency -= 1
        EndIf
        TerminalData.RestartTortureMode = true
    ElseIf (auiMenuItemID == 7 || auiMenuItemID == 8)
        ; less frequent
        If (TerminalData.TortureModeFrequency == 0.1666)
            TerminalData.TortureModeFrequency = 0.2
        ElseIf (TerminalData.TortureModeFrequency == 0.2)
            TerminalData.TortureModeFrequency = 0.25
        ElseIf (TerminalData.TortureModeFrequency == 0.25)
            TerminalData.TortureModeFrequency = 0.3333
        ElseIf (TerminalData.TortureModeFrequency == 0.3333)
            TerminalData.TortureModeFrequency = 0.5
        ElseIf (TerminalData.TortureModeFrequency == 0.5)
            TerminalData.TortureModeFrequency = 1
        ElseIf (TerminalData.TortureModeFrequency < 6)
            TerminalData.TortureModeFrequency += 1
        EndIf
        TerminalData.RestartTortureMode = true
    EndIf
EndEvent