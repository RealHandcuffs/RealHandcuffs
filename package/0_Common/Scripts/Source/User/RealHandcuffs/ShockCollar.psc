;
; Script for RobCo ShockCollar.
;
Scriptname RealHandcuffs:ShockCollar extends RealHandcuffs:ShockCollarBase

Armor Property DummyShockCollar Auto Const Mandatory
Terminal Property TerminalRobCoShockCollar Auto Const Mandatory
MiscObject Property ExplodedShockCollar Auto Const Mandatory

;
; Override: Get a 'dummy' armor that can be used to visually represent the restraint.
;
Armor Function GetDummyObject()
    Return DummyShockCollar
EndFunction

;
; Override: Get the object to use for the exploded collar.
;
MiscObject Function GetExplodedCollar()
    Return ExplodedShockCollar
EndFunction

;
; Override: Get the terminal for this shock collar.
;
Terminal Function GetTerminal()
    return TerminalRobCoShockCollar
EndFunction

;
; Override: Get the number of supported access code digits.
;
Int Function GetNumberOfAccessCodeDigits()
    If (HasKeyword(Library.Resources.MarkTwoFirmware) || HasKeyword(Library.Resources.HackedFirmware))
        Return 3
    ElseIf (HasKeyword(Library.Resources.MarkThreeFirmware))
        Return 4
    EndIf
    Return 0
EndFunction

;
; Overrride: Get the supported trigger modes.
;
Int Function GetSupportedTriggerModes()
    If (HasKeyword(Library.Resources.MarkTwoFirmware) || HasKeyword(Library.Resources.HackedFirmware))
        Return TerminalData.SimpleSingleDoubleSignalTrigger
    ElseIf (HasKeyword(Library.Resources.MarkThreeFirmware))
        Return TerminalData.SimpleSingleDoubleTripleSignalTrigger
    EndIf
    Return TerminalData.SimpleTrigger
EndFunction
